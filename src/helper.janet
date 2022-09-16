# src/helper.janet
#
# Helper Functions
#
# created on : 2022.09.07.
# last update: 2022.09.16.

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

(defn- purge-nil-params
  "Removes keys with nil values from given dict."
  [dict]
  (var result @{})
  (loop [(k v) :in 
         (filter (fn [(k v)]
                   (not (nil? v)))
                 (pairs dict))]
    (put result k v))
  result)

(defn- key->keyword
 "Converts json key to kebab-cased keyword."
 [key]
 (keyword (string/replace-all "_" "-" key)))

(defn- dict->kebabbed-keys
  "Converts all struct/table keys to kebab-cased keywords."
  [dict]
  (var result @{})
  (loop [[k v] :in (map (fn [(k v)]
                          [(key->keyword k)
                           (cond
                             (or (tuple? v)
                                 (array? v)) (map (fn [v]
                                                    (if (or (struct? v)
                                                            (table? v))
                                                      (dict->kebabbed-keys v)
                                                      v)) v) # recurse for nested struct/tables
                             (or (struct? v)
                                 (table? v)) (dict->kebabbed-keys v) # recurse for nested struct/tables
                             v)])
                        (pairs dict))]
    (put result k v))
  result)

(defn request
  "Sends a HTTP request with given method name and params.
  Returns a response synchronously.

  Keywords in returned response are in kebab-case."
  [bot method params]
  (let [f (fn [b m ps]
            (let [token (b :token)
                  url (string api-baseurl token "/" m)
                  headers {:user-agent "telegram-bot-janet"}
                  params (purge-nil-params ps)
                  result (if (httprequest/has-file? params)
                           (httprequest/post url headers params)
                           (httprequest/post<-json url headers params))]
              (cond
                (= (result :status) 200) (dict->kebabbed-keys (json/decode (result :body)))
                (do 
                  (verbose bot "request error: " result)
                  (merge result {:ok false})))))]
    (f bot method params)))

(defn url-for-filepath
  "Generates a URL from a fetched file info.
  (https://core.telegram.org/bots/api#getfile)"
  [bot filepath]
  (string file-baseurl (bot :token) "/" filepath))
