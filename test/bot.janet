# test/bot.janet
#
# created on : 2022.09.16.
# last update: 2023.11.10.
#
# Test with:
#
# ```bash
# $ TOKEN=xxxxx CHAT_ID=yyyyy jpm test
#
# # for verbose messages:
# $ TOKEN=xxxxx CHAT_ID=yyyyy VERBOSE=true jpm test
# ``

(use ../src/init)

(import httprequest :as r)

(defn- read-env-var
  "Reads an environment variable with given key."
  [key]
  (os/getenv key))

# fake tokens and chat id
(def test-bot-token "0123456789:abcdefghijklmnopqrstuvwxyz")
(def test-chat-id -1)
(def verbose? (= (read-env-var "VERBOSE") "true"))

# initialize values from environment variables
(var bot (new-bot (or (read-env-var "TOKEN")
                      test-bot-token)
                  :verbose? verbose?))
(def chat-id (or (read-env-var "CHAT_ID")
                 test-chat-id))

# constants
(def- filepath-for-test (string (os/cwd) "/resources/test/image.png"))


########################
# test bot creation
#
(print "Testing bot creation")
(do
  # get my info
  (let [bot-info (:get-me bot)]
    (assert (bot-info :ok)))

  (comment --------))


########################
# test message sending/fetching
#
(print "Testing sending and fetching messages")
(do
  # delete webhook,
  (assert ((:delete-webhook bot) :ok))

  # delete bot commands
  (assert ((:delete-my-commands bot) :ok))

  # set bot commands
  (assert ((:set-my-commands bot [{:command "/help" :description "show help messages"}]) :ok))

  # get bot commands
  (assert ((:get-my-commands bot) :ok))

  # set bot name
  (assert ((:set-my-name bot "telegram-bot-janet test bot") :ok))

  # get bot name
  (assert ((:get-my-name bot) :ok))

  # set bot description
  (assert ((:set-my-description bot :description "A bot for testing library: telegram-bot-janet") :ok))

  # get bot description
  (assert ((:get-my-description bot) :ok))

  # set bot short description
  (assert ((:set-my-short-description bot :short-description "telegram-bot-janet") :ok))

  # get bot short description
  (assert ((:get-my-short-description bot) :ok))

  # send a chat action,
  (assert ((:send-chat-action bot chat-id :typing) :ok))

  # send a text message,
  (let [sent-message (:send-message bot chat-id "test message")]
    (assert (sent-message :ok))

    # edit the message's text,
    (assert ((:edit-message-text bot "edited message"
                                 :chat-id chat-id
                                 :message-id (get-in sent-message [:result :message-id])) :ok))

    # copy it,
    (assert ((:copy-message bot chat-id chat-id (get-in sent-message [:result :message-id])) :ok))

    # and forward it
    (assert ((:forward-message bot chat-id chat-id (get-in sent-message [:result :message-id])) :ok)))

  # send a photo,
  (let [photo-file (r/filepath->param filepath-for-test)
        sent-photo (:send-photo bot chat-id photo-file)]
    (assert (sent-photo :ok))

    # edit the photo's caption
    (assert ((:edit-message-caption bot "caption"
                                    :chat-id chat-id
                                    :message-id (get-in sent-photo [:result :message-id])) :ok)))

  # TODO: send-audio

  # send a document,
  (let [document-file (r/filepath->param filepath-for-test)
        sent-document (:send-document bot chat-id document-file)]
    (assert (sent-document :ok))

    # get-file
    (let [file-id (get-in sent-document [:result :document :file-id])
          file (:get-file bot file-id)
          file-url (get-in file [:result :file-url])]
      (do
        (assert (file :ok))

        (assert (string/has-prefix? "https://" file-url))))

    # delete a message,
    (assert ((:delete-message bot chat-id (get-in sent-document [:result :message-id])) :ok)))

  # TODO: send-sticker

  # TODO: send-video

  # TODO: send-animation

  # TODO: send-voice

  # TODO: send-video-note

  # TODO: send-media-group

  # send a location,
  (assert ((:send-location bot chat-id 37.5665 126.9780) :ok))

  # TODO: send-venue

  # send a contact,
  (assert ((:send-contact bot chat-id "911" "Nine-One-One") :ok))

  # send a poll,
  (let [sent-poll (:send-poll bot chat-id "The earth is...?" ["flat" "round" "nothing"])]
    (assert (sent-poll :ok))

    # stop a poll,
    (assert (:stop-poll bot chat-id (get-in sent-poll [:result :message-id]) :ok)))

  # send a dice,
  (assert ((:send-dice bot chat-id) :ok))

  # TODO: edit-message-media

  # TODO: edit-message-reply-markup

  # TODO: edit-message-live-location

  # TODO: stop-message-live-location

  # fetch messages
  (assert ((:get-updates bot) :ok))

  (comment --------))


########################
# test message polling
#
(print "Testing polling updates")
(do
  # start polling updates,
  (var ch (:poll-updates bot 1))
  (assert ch)

  # wait for a moment,
  (os/sleep 5)

  # read updates from the channel, (can be empty)
  (let [updates (ev/take ch)]
    (assert updates))

  # wait for a moment,
  (os/sleep 5)

  # then stop polling
  (assert (:stop-polling-updates bot ch))

  (comment --------))


########################
# test stickers
#
(print "Testing stickers")
(do
  # TODO: get-sticker-set

  # TODO: upload-sticker-file

  # TODO: create-new-sticker-set

  # TODO: add-sticker-to-set

  # TODO: set-sticker-position-in-set

  # TODO: delete-sticker-from-set

  # TODO: set-sticker-set-thumbnail

  # TODO: set-custom-emoji-sticker-set-thumbnail

  # TODO: set-custom-emoji-sticker-set-thumbnail

  # TODO: set-sticker-set-title

  # TODO: delete-sticker-set

  # TODO: set-sticker-emoji-list

  # TODO: set-sticker-keywords

  # TODO: set-sticker-mask-position

  # TODO: set-chat-sticker-set

  # TODO: delete-chat-sticker-set

  # TODO: get-forum-topic-icon-stickers

  (comment --------))


########################
# test game
#
(print "Testing game")
(do
  # TODO: send-game

  # TODO: set-game-score

  # TODO: get-game-highscores

  (comment --------))


########################
# test shopping
#
(print "Testing shopping")
(do
  # TODO: send-invoice

  # TODO: answer-shipping-query

  # TODO: answer-pre-checkout-query

  (comment --------))


########################
# test chat administration
#
(print "Testing chat administration")
(do
  # TODO: ban-chat-member

  # TODO: leave-chat

  # TODO: unban-chat-member

  # TODO: restrict-chat-member

  # TODO: promote-chat-member

  # TODO: set-chat-administrator-custom-title

  # TODO: ban-chat-sender-chat

  # TODO: unban-chat-sender-chat

  # TODO: set-chat-permissions

  # TODO: export-chat-invite-link

  # TODO: create-chat-invite-link

  # TODO: edit-chat-invite-link

  # TODO: revoke-chat-invite-link

  # TODO: approve-chat-join-request

  # TODO: decline-chat-join-request

  # TODO: set-chat-photo

  # TODO: delete-chat-photo

  # TODO: set-chat-title

  # set-chat-description
  (let [desc (:set-chat-description bot chat-id (string/format "[telegram-bot-janet] chat_id: %s (last update: %d)" chat-id (os/time)))]
    (assert (desc :ok)))

  # TODO: pin-chat-message

  # TODO: unpin-chat-message

  # TODO: unpin-all-chat-messages

  # get-chat
  (let [chat (:get-chat bot chat-id)]
    (assert (chat :ok)))

  # TODO: get-user-profile-photos

  # get-chat-administrators
  (let [admins (:get-chat-administrators bot chat-id)]
    (assert (admins :ok)))

  # get-chat-member-count
  (let [count (:get-chat-member-count bot chat-id)]
    (assert (count :ok)))

  # TODO: get-chat-member

  # TODO: set-chat-menu-button

  # TODO: get-chat-menu-button

  # TODO: set-my-default-administrator-rights

  # TODO: get-my-default-administrator-rights

  # TODO: create-forum-topic

  # TODO: edit-forum-topic

  # TODO: close-forum-topic

  # TODO: reopen-forum-topic

  # TODO: delete-forum-topic

  # TODO: unpin-all-forum-topic-messages

  # TODO: edit-general-form-topic

  # TODO: close-general-forum-topic

  # TODO: reopen-general-forum-topic

  # TODO: hide-general-forum-topic

  # TODO: unhide-general-forum-topic

  # TODO: unpin-all-general-forum-topic-messages

  (comment --------))


########################
# test callback query
#
(print "Testing callback query")
(do
  # TODO: answer-callback-query

  (comment --------))


########################
# test inline query
#
(print "Testing inline query")
(do
  # TODO: answer-inline-query

  (comment --------))


########################
# test web app query
#
(print "Testing web app query")
(do
  # TODO: answer-web-app-query

  (comment --------))


########################
# test helper functions
#
(print "Testing helper functions")
(def long-text-with-newlines
  ``Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vitae nisi a metus varius dignissim ut ultricies neque. Nunc facilisis commodo augue, sit amet rutrum turpis blandit id. Sed ullamcorper lectus a vulputate egestas. Donec viverra lobortis fermentum. Phasellus finibus metus orci, bibendum convallis orci commodo gravida. Sed in vulputate mauris. Sed quis odio id est malesuada tincidunt vel id lectus. Nulla et eleifend quam. Aliquam ultricies molestie turpis, et porta erat iaculis non. Sed sagittis luctus egestas. In non ex id mi faucibus tempor.

  Duis non velit eleifend nunc placerat pretium. Aenean pharetra, sem non porttitor dapibus, leo tortor convallis dui, sed sodales sem orci sed augue. Etiam vehicula ante sit amet iaculis gravida. Vestibulum dictum dapibus congue. Proin ut nisi lorem. Integer bibendum dui nisl, nec pulvinar eros hendrerit eget. Donec nec neque eget massa suscipit tincidunt. In sem massa, efficitur sit amet maximus eget, imperdiet sit amet massa. Donec at iaculis odio, quis dictum eros. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Maecenas faucibus sapien quis sagittis tempor.

  Mauris egestas ipsum a nibh rhoncus imperdiet. Aliquam ultrices, purus et varius venenatis, lorem orci placerat lorem, quis laoreet elit metus a ligula. Sed varius magna sit amet massa dictum facilisis. Vivamus rutrum, erat in ultricies lacinia, lorem massa accumsan nibh, ac semper nisl sem id quam. Vivamus ante lectus, fringilla at massa at, congue gravida nisl. Sed volutpat dictum interdum. Phasellus ac condimentum nibh, ac tempus lectus. Mauris convallis nec urna in aliquam. Ut lobortis orci vitae diam ultricies, nec interdum odio laoreet. Mauris vehicula nunc et nisi tempor, eu porta augue vestibulum. Donec quis feugiat lectus, eget aliquet est. Mauris vel nunc vitae risus consectetur pharetra sed sed enim. Donec tristique purus et augue ultricies sagittis. Duis lobortis finibus ante, et sollicitudin arcu lobortis in.

  Fusce tempor nunc et sem rutrum, eget laoreet est tempor. Proin sollicitudin rutrum nulla dignissim posuere. In dolor nisl, tincidunt nec turpis eget, gravida tempus quam. Aliquam vestibulum cursus commodo. Aenean elementum odio sed mollis efficitur. Proin imperdiet ullamcorper velit vitae venenatis. Nullam vitae tellus lectus. Donec fermentum nec nisi vitae tincidunt. Suspendisse ullamcorper eros id dui pharetra, vel sodales nunc vulputate.

  Proin tempor massa at nunc pellentesque egestas. Quisque lacinia libero ut urna feugiat, sed varius tortor pellentesque. In id dolor varius, imperdiet felis ac, sollicitudin felis. Vestibulum sollicitudin pellentesque tortor, quis sollicitudin velit commodo non. In hac habitasse platea dictumst. Integer pellentesque diam finibus sapien mollis, nec dignissim tellus porta. Nam imperdiet feugiat elit, in convallis velit viverra sit amet. Nam finibus ipsum sollicitudin, interdum ligula eu, eleifend leo. Fusce id elit sed felis placerat ullamcorper. Aliquam vel nisl nec dolor ultricies dignissim vel sed felis. Fusce posuere quam et eros sollicitudin viverra. Duis ut felis venenatis eros ullamcorper rhoncus. Nulla tristique turpis ut turpis lobortis, ac accumsan turpis tincidunt.
  ``)
(do
  # split text
  (let [chars-limit 1000
        splits (split-text long-text-with-newlines chars-limit)]
    (assert splits)

    (loop [splitted :in splits]
      (assert (<= (length splitted) chars-limit))))

  (comment --------))
