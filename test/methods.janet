# test/methods.janet
#
# created on : 2022.09.16.
# last update: 2022.11.07.
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

  # TODO: set-sticker-set-thumb

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

  # TODO: set-chat-permission

  # TODO: export-chat-invite-link

  # TODO: create-chat-invite-link

  # TODO: edit-chat-invite-link

  # TODO: revoke-chat-invite-link

  # TODO: approve-chat-join-request

  # TODO: decline-chat-join-request

  # TODO: set-chat-photo

  # TODO: delete-chat-photo

  # TODO: set-chat-title

  # TODO: set-chat-description

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

  # TODO: set-chat-sticker-set

  # TODO: delete-chat-sticker-set

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

  # TODO: get-forum-topic-icon-stickers

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

