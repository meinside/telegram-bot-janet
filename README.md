# telegram-bot-janet

Telegram Bot API wrapper library for Janet.

Ported from [clogram](https://github.com/meinside/clogram).

## Install


In your `project.janet` file, add:

```clojure
{:dependencies ["https://github.com/meinside/telegram-bot-janet"]}
```

## Usage

```clojure
(import telegram-bot-janet :as tg)

(def token "0123456789:abcdefghijklmnop1234567890ABCDEFG")
(def chat-id -1234567890)

(var bot (tg/new-bot token))
(:send-message bot chat-id "dodge this!")
```

## Samples

#### Echo Server

```clojure
(import telegram-bot-janet :as tg)

(def token "0123456789:abcdefghijklmnop1234567890ABCDEFG")
(def interval-seconds 1)
(def verbose? true)

(defn main [& args]
  (var bot (tg/new-bot token
                       :interval-seconds 1
                       :verbose? verbose?))
  (let [updates-ch (:poll-updates bot interval-seconds)]
    (ev/do-thread
      (forever
        (if-let [updates (ev/take updates-ch)]
          (do
            (if-not (empty? updates)
              (loop [update :in updates]
                (let [chat-id (get-in update [:message :chat :id])
                      text (get-in update [:message :text])
                      original-message-id (get-in update [:message :message-id])
                      response (:send-message bot chat-id text :reply-parameters {"message_id" original-message-id})]
                  (print (string/format "response of send-message: %m" response))

                  (if (= text "/exit")
                    (do
                      (print "stopping polling updates...")

                      (:stop-polling-updates bot updates-ch)))))))
          (do
            (print "failed to take from updates channel")
            (break))))))
  
  (print "exiting application..."))
```
