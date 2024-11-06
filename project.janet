(declare-project
  :name "telegram-bot-janet"
  :description ```Telegram Bot API Wrapper for Janet Language```
  :version "0.0.33"
  :dependencies ["https://github.com/janet-lang/spork.git"
                 "https://github.com/meinside/httprequest-janet"])

(declare-source
  :prefix "telegram-bot-janet"
  :source ["src/init.janet"
           "src/helper.janet"])
