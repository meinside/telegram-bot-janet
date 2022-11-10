# src/helper.janet
#
# Helper Functions
#
# created on : 2022.09.07.
# last update: 2022.11.10.

(import spork/json)
(import httprequest)

################################
#
# Constants

(def api-baseurl "https://api.telegram.org/bot")
(def file-baseurl "https://api.telegram.org/file/bot")

################################
#
# Helper Functions

# get timestamp of given local epoch value
(defn- timestamp
  [epoch]
  (let [now (os/date epoch "local")]
    (string/format "%04d-%02d-%02d %02d:%02d:%02d"
                   (now :year)
                   (inc (now :month))
                   (inc (now :month-day))
                   (now :hours)
                   (now :minutes)
                   (now :seconds))))

# print verbose log messages
(defn verbose
  [bot & args]
  (when (bot :verbose?)
    (print
      (timestamp (os/time))
      "| VERBOSE |"
      (string/join (map (fn [v]
                          (string/format (if (string? v) "%s" "%j") v))
                        args) " "))))

# print log messages
(defn log
  [& args]
  (print
    (timestamp (os/time))
    "| LOG |"
    (string/join (map (fn [v]
                        (string/format (if (string? v) "%s" "%j") v))
                      args) " ")))

(defn- key->kebabbed-keyword
  ``Converts json key string to kebab-cased keyword for convenience.
  ``
  [key]
  (->> key
       (string/replace-all "_" "-")
       keyword))

(defn- sanitize-keys
  ``Sanitizes all struct/table keys in given collection `val` recursively.
  ``
  [val]

  (cond
    # dictionary
    (or (struct? val) (table? val))
    (do
      (var sanitized @{})
      (loop [[k v] :in (map (fn [(k v)]
                              [(key->kebabbed-keyword k) (sanitize-keys v)])
                            (pairs val))]
        (put sanitized k v))
      # return sanitized value
      sanitized)

    # array
    (or (tuple? val) (array? val))
    (map sanitize-keys val)

    # pass other types
    val))

(defn request
  ``Sends a HTTP request with given method name and params.
  Returns a response synchronously.

  Keywords in returned response are in kebab-case.
  ``
  [bot method params]
  (let [f (fn [b m ps]
            (try
              (do
                (let [token (b :token)
                      url (string api-baseurl token "/" m)
                      headers {:user-agent "telegram-bot-janet"}
                      result (if (httprequest/has-file? ps)
                               (httprequest/post url headers ps)
                               (httprequest/post<-json url headers ps))]
                  (cond
                    (= (result :status) 200) (sanitize-keys (json/decode (result :body)))
                    (do
                      (verbose bot "request error: " result)
                      (merge result {:ok false})))))
              ([err] {:ok false
                      :error (string err)})))]
    (f bot method params)))

(defn url-for-filepath
  ``Generates a URL from a fetched file info.

  https://core.telegram.org/bots/api#getfile
  ``
  [bot filepath]
  (string file-baseurl (bot :token) "/" filepath))
