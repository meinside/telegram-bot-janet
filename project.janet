(declare-project
  :name "telegram-bot-janet"
  :description ```Telegram Bot API Wrapper for Janet Language ```
  :version "0.0.4"
  :dependencies ["https://github.com/janet-lang/spork.git"
                 "https://github.com/meinside/janet-httprequest"])

(declare-source
  :prefix "telegram-bot-janet"
  :source ["src/init.janet"
           "src/helper.janet"])
