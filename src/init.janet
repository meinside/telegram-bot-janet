# src/init.janet
#
# Telegram Bot Library for Janet
#
# (https://core.telegram.org/bots/api)
#
# created on : 2022.09.15.
# last update: 2023.01.03.

(import ./helper :as h)

# constants
(def- default-interval-seconds 1)
(def- default-timeout-seconds 10)
(def- default-limit-count 100)
(def- channel-buffer-size 10)

########################
# bot API methods
#
# https://core.telegram.org/bots/api#available-methods

(defn delete-webhook
  ``Deletes webhook for polling messages.

  Optional parameter keys are: :drop-pending-updates.

  https://core.telegram.org/bots/api#deletewebhook
  ``
  [bot &named drop-pending-updates]
  (h/request bot "deleteWebhook" {"drop_pending_updates" drop-pending-updates}))

(defn get-me
  ``Fetches this bot's info.

  https://core.telegram.org/bots/api#getme
  ``
  [bot]
  (h/request bot "getMe" {}))

(defn get-updates
  ``Fetches updates for this bot.

  Optional parameter keys are: :offset, :limit, :timeout, and :allowed-updates.

  https://core.telegram.org/bots/api#getupdates
  ``
  [bot &named offset
              limit
              timeout
              allowed-updates]
  (h/request bot "getUpdates" {"offset" offset
                               "limit" (or limit 100)
                               "timeout" (or timeout (bot :timeout-seconds))
                               "allowed_updates" allowed-updates}))

(defn poll-updates
  ``Returns a channel whilch will be populated by updates periodically.

  Empty array will be passed when there are no updates for the time.

  Call `stop-polling-updates` when done.

  Optional parameter keys are: :offset, :limit, :timeout, and :allowed-updates.
  ``
  [bot interval-seconds &named offset
                               limit
                               timeout
                               allowed-updates]
  (let [ch (ev/thread-chan channel-buffer-size)
        limit (or limit 100)
        timeout (or timeout (bot :timeout-seconds))
        interval-seconds (max default-interval-seconds interval-seconds)]

    (h/log "starting polling with interval:" interval-seconds "second(s)")

    (ev/spawn-thread
      (do
        # initialize `update-offset`
        (var update-offset (or offset 0))

        (forever
          (let [response (get-updates bot
                                      :offset update-offset
                                      :limit limit
                                      :timeout timeout
                                      :allowed-updates allowed-updates)
                ok? (response :ok)]
            (if ok?
              (let [updates (response :result)]
                # new update-offset = latest update-id + 1
                (if-not (empty? updates)
                  (set update-offset (inc (last (sort (map (fn [r]
                                                             (r :update-id))
                                                           updates))))))
                (try
                  (do
                    # give updates through channel
                    (if-let [given (ev/give ch updates)]
                      (do
                        (h/verbose bot (string/format "given updates: %m" updates)))
                      (do
                        (h/log "channel closed, stopping polling...")
                        (break))))
                  ([err] (do
                           (h/verbose bot (string/format "failed to write to channel: %s" err))
                           (break)))))
              (do
                (if-let [err (response :error)]
                  (h/log (string/format "failed to fetch updates: %s" err))
                  (h/log (string/format "failed to fetch updates: %m" response))))))

          # sleep
          (ev/sleep interval-seconds))))
    ch))

(defn stop-polling-updates
  ``Stops polling of updates. Passed updates channel will be closed.
  ``
  [bot ch]
  (ev/chan-close ch))

(defn send-message
  ``Sends a message.

  Optional parameter keys are: :message-thread-id, :parse-mode, :entities, :disable-web-page-preview, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendmessage
  ``
  [bot chat-id text &named message-thread-id
                           parse-mode
                           entities
                           disable-web-page-preview
                           disable-notification
                           protect-content
                           reply-to-message-id
                           allow-sending-without-reply
                           reply-markup]
  (h/request bot "sendMessage" {"chat_id" chat-id
                                "message_thread_id" message-thread-id
                                "text" text
                                "parse_mode" parse-mode
                                "entities" entities
                                "disable_web_page_preview" disable-web-page-preview
                                "disable_notification" disable-notification
                                "protect_content" protect-content
                                "reply_to_message_id" reply-to-message-id
                                "allow_sending_without_reply" allow-sending-without-reply
                                "reply_markup" reply-markup}))

(defn forward-message
  ``Forwards a message.

  Optional parameter keys are: :message-thread-id, :disable-notification, and :protect-content.

  https://core.telegram.org/bots/api#forwardmessage
  ``
  [bot chat-id from-chat-id message-id &named message-thread-id
                                              disable-notification
                                              protect-content]
  (h/request bot "forwardMessage" {"chat_id" chat-id
                                   "message_thread_id" message-thread-id
                                   "from_chat_id" from-chat-id
                                   "message_id" message-id
                                   "disable_notification" disable-notification
                                   "protect_content" protect-content}))

(defn copy-message
  ``Copies a message.

  Optional parameter keys are: :message-thread-id, :caption, :parse-mode, :caption-entities, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#copymessage
  ``
  [bot chat-id from-chat-id message-id &named message-thread-id
                                              caption
                                              parse-mode
                                              caption-entities
                                              disable-notification
                                              protect-content
                                              reply-to-message-id
                                              allow-sending-without-reply
                                              reply-markup]
  (h/request bot "copyMessage" {"chat_id" chat-id
                                "message_thread_id" message-thread-id
                                "from_chat_id" from-chat-id
                                "message_id" message-id
                                "caption" caption
                                "parse_mode" parse-mode
                                "caption_entities" caption-entities
                                "disable_notification" disable-notification
                                "protect_content" protect-content
                                "reply_to_message_id" reply-to-message-id
                                "allow_sending_without_reply" allow-sending-without-reply
                                "reply_markup" reply-markup}))

(defn send-photo
  ``Sends a photo.

  Optional parameter keys are: :message-thread-id, :caption, :parse-mode, :caption-entities, :has-spoiler, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendphoto
  ``
  [bot chat-id photo &named message-thread-id
                            caption
                            parse-mode
                            caption-entities
                            has-spoiler
                            disable-notification
                            protect-content
                            reply-to-message-id
                            allow-sending-without-reply
                            reply-markup]
  (h/request bot "sendPhoto" {"chat_id" chat-id
                              "message_thread_id" message-thread-id
                              "photo" photo
                              "caption" caption
                              "parse_mode" parse-mode
                              "caption_entities" caption-entities
                              "has_spoiler" has-spoiler
                              "disable_notification" disable-notification
                              "protect_content" protect-content
                              "reply_to_message_id" reply-to-message-id
                              "allow_sending_without_reply" allow-sending-without-reply
                              "reply_markup" reply-markup}))

(defn send-audio
  ``Sends an audio file.

  Optional parameter keys are: :message-thread-id, :caption, :parse-mode, :caption-entities, :duration, :performer, :title, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendaudio
  ``
  [bot chat-id audio &named message-thread-id
                            caption
                            parse-mode
                            caption-entities
                            duration
                            performer
                            title
                            disable-notification
                            protect-content
                            reply-to-message-id
                            allow-sending-without-reply
                            reply-markup]
  (h/request bot "sendAudio" {"chat_id" chat-id
                              "message_thread_id" message-thread-id
                              "audio" audio
                              "caption" caption
                              "parse_mode" parse-mode
                              "caption_entities" caption-entities
                              "duration" duration
                              "performer" performer
                              "title" title
                              "disable_notification" disable-notification
                              "protect_content" protect-content
                              "reply_to_message_id" reply-to-message-id
                              "allow_sending_without_reply" allow-sending-without-reply
                              "reply_markup" reply-markup}))

(defn send-document
  ``Sends a document file.

  Optional parameter keys are: :message-thread-id, :caption, :parse-mode, :caption-entities, :disable-content-type-detection, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#senddocument
  ``
  [bot chat-id document &named message-thread-id
                               caption
                               parse-mode
                               caption-entities
                               disable-content-type-detection
                               disable-notification
                               protect-content
                               reply-to-message-id
                               allow-sending-without-reply
                               reply-markup]
  (h/request bot "sendDocument" {"chat_id" chat-id
                                 "message_thread_id" message-thread-id
                                 "document" document
                                 "caption" caption
                                 "parse_mode" parse-mode
                                 "caption_entities" caption-entities
                                 "disable_content_type_detection" disable-content-type-detection
                                 "disable_notification" disable-notification
                                 "protect_content" protect-content
                                 "reply_to_message_id" reply-to-message-id
                                 "allow_sending_without_reply" allow-sending-without-reply
                                 "reply_markup" reply-markup}))

(defn send-sticker
  ``Sends a sticker.

  Optional parameter keys are: :message-thread-id, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendsticker
  ``
  [bot chat-id sticker &named message-thread-id
                              disable-notification
                              protect-content
                              reply-to-message-id
                              allow-sending-without-reply
                              reply-markup]
  (h/request bot "sendSticker" {"chat_id" chat-id
                                "message_thread_id" message-thread-id
                                "sticker" sticker
                                "disable_notification" disable-notification
                                "protect_content" protect-content
                                "reply_to_message_id" reply-to-message-id
                                "allow_sending_without_reply" allow-sending-without-reply
                                "reply_markup" reply-markup}))

(defn get-sticker-set
  ``Fetches a sticker set.

  https://core.telegram.org/bots/api#getstickerset
  ``
  [bot name]
  (h/request bot "getStickerSet" {"name" name}))

(defn upload-sticker-file
  ``Uploads a sticker file.

  https://core.telegram.org/bots/api#uploadstickerfile
  ``
  [bot user-id sticker]
  (h/request bot "uploadStickerFile" {"user_id" user-id
                                      "png_sticker" sticker}))

(defn create-new-sticker-set
  ``Creates a new sticker set.

  Optional parameter keys are: :png-sticker, :tgs-sticker, :webm-sticker, :contains-masks, and :mask-position

  https://core.telegram.org/bots/api#createnewstickerset
  ``
  [bot user-id name title emojis &named png-sticker
                                        tgs-sticker
                                        webm-sticker
                                        contains-masks
                                        mask-position]
  (h/request bot "createNewStickerSet" {"user_id" user-id
                                        "name" name
                                        "title" title
                                        "png_sticker" png-sticker
                                        "tgs_sticker" tgs-sticker
                                        "webm_sticker" webm-sticker
                                        "emojis" emojis
                                        "contains_masks" contains-masks
                                        "mask_position" mask-position}))

(defn add-sticker-to-set
  ``Adds a sticker to a set.

  Optional parameter keys are: :png-sticker, :tgs-sticker, :webm-sticker, and :mask-position

  https://core.telegram.org/bots/api#addstickertoset
  ``
  [bot user-id name emojis &named png-sticker
                                  tgs-sticker
                                  webm-sticker
                                  mask-position]
  (h/request bot "addStickerToSet" {"user_id" user-id
                                    "name" name
                                    "png_sticker" png-sticker
                                    "tgs_sticker" tgs-sticker
                                    "webm_sticker" webm-sticker
                                    "emojis" emojis
                                    "mask_position" mask-position}))

(defn set-sticker-position-in-set
  ``Sets a sticker's position in its set.

  https://core.telegram.org/bots/api#setstickerpositioninset
  ``
  [bot sticker position]
  (h/request bot "setStickerPositionInSet" {"sticker" sticker
                                            "position" position}))

(defn delete-sticker-from-set
  ``Deletes a sticker from its set.

  https://core.telegram.org/bots/api#deletestickerfromset
  ``
  [bot sticker]
  (h/request bot "deleteStickerFromSet" {"sticker" sticker}))

(defn set-sticker-set-thumb
  ``Sets thumbnail of a sticker set.

  Optional parameter keys are: thumb.

  https://core.telegram.org/bots/api#setstickersetthumb
  ``
  [bot name user-id &named thumb]
  (h/request bot "setStickerSetThumb" {"name" name
                                       "user_id" user-id
                                       "thumb" thumb}))

(defn send-video
  ``Sends a video.

  Optional parameter keys are: :message-thread-id, :duration, :caption, :parse-mode, :caption-entities, :has-spoiler, :supports-streaming, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendvideo
  ``
  [bot chat-id video &named message-thread-id
                            duration
                            caption
                            parse-mode
                            caption-entities
                            has-spoiler
                            supports-streaming
                            disable-notification
                            protect-content
                            reply-to-message-id
                            allow-sending-without-reply
                            reply-markup]
  (h/request bot "sendVideo" {"chat_id" chat-id
                              "message_thread_id" message-thread-id
                              "video" video
                              "duration" duration
                              "caption" caption
                              "parse_mode" parse-mode
                              "caption_entities" caption-entities
                              "has_spoiler" has-spoiler
                              "supports_streaming" supports-streaming
                              "disable_notification" disable-notification
                              "protect_content" protect-content
                              "reply_to_message_id" reply-to-message-id
                              "allow_sending_without_reply" allow-sending-without-reply
                              "reply_markup" reply-markup}))

(defn send-animation
  ``Sends an animation.

  Optional parameter keys are: :message-thread-id, :duration, :width, :height, :thumb, :caption, :parse-mode, :caption-entities, :has-spoiler, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendanimation
  ``
  [bot chat-id animation &named message-thread-id
                                duration
                                width
                                height
                                thumb
                                caption
                                parse-mode
                                caption-entities
                                has-spoiler
                                disable-notification
                                protect-content
                                reply-to-message-id
                                allow-sending-without-reply
                                reply-markup]
  (h/request bot "sendAnimation" {"chat_id" chat-id
                                  "message_thread_id" message-thread-id
                                  "animation" animation
                                  "duration" duration
                                  "width" width
                                  "height" height
                                  "thumb" thumb
                                  "caption" caption
                                  "parse_mode" parse-mode
                                  "caption_entities" caption-entities
                                  "has_spoiler" has-spoiler
                                  "disable_notification" disable-notification
                                  "protect_content" protect-content
                                  "reply_to_message_id" reply-to-message-id
                                  "allow_sending_without_reply" allow-sending-without-reply
                                  "reply_markup" reply-markup}))

(defn send-voice
  ``Sends a voice. (.ogg format only)

  Optional parameter keys are: :message-thread-id, :caption, :parse-mode, :caption-entities, :duration, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendvoice
  ``
  [bot chat-id voice &named message-thread-id
                            caption
                            parse-mode
                            caption-entities
                            duration
                            disable-notification
                            protect-content
                            reply-to-message-id
                            allow-sending-without-reply
                            reply-markup]
  (h/request bot "sendVoice" {"chat_id" chat-id
                              "message_thread_id" message-thread-id
                              "voice" voice
                              "caption" caption
                              "parse_mode" parse-mode
                              "caption_entities" caption-entities
                              "duration" duration
                              "disable_notification" disable-notification
                              "protect_content" protect-content
                              "reply_to_message_id" reply-to-message-id
                              "allow_sending_without_reply" allow-sending-without-reply
                              "reply_markup" reply-markup}))

(defn send-video-note
  ``Sends a video note.

  Optional parameter keys are: :message-thread-id, :duration, :length, :thumb, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.
  (XXX: API returns 'Bad Request: wrong video note length' when length is not given / 2017.05.19.)

  https://core.telegram.org/bots/api#sendvideonote
  ``
  [bot chat-id video-note &named message-thread-id
                                 duration
                                 length
                                 thumb
                                 disable-notification
                                 protect-content
                                 reply-to-message-id
                                 allow-sending-without-reply
                                 reply-markup]
  (h/request bot "sendVideoNote" {"chat_id" chat-id
                                  "message_thread_id" message-thread-id
                                  "video_note" video-note
                                  "duration" duration
                                  "length" length
                                  "thumb" thumb
                                  "disable_notification" disable-notification
                                  "protect_content" protect-content
                                  "reply_to_message_id" reply-to-message-id
                                  "allow_sending_without_reply" allow-sending-without-reply
                                  "reply_markup" reply-markup}))

(defn send-media-group
  ``Sends a media group of photos or videos.

  Optional parameter keys are: :message-thread-id, :disable-notification, :reply-to-message-id, and :allow-sending-without-reply.

  https://core.telegram.org/bots/api#sendmediagroup
  ``
  [bot chat-id media &named message-thread-id
                            disable-notification
                            protect-content
                            reply-to-message-id
                            allow-sending-without-reply]
  (h/request bot "sendMediaGroup" {"chat_id" chat-id
                                   "message_thread_id" message-thread-id
                                   "media" media
                                   "disable_notification" disable-notification
                                   "protect_content" protect-content
                                   "reply_to_message_id" reply-to-message-id
                                   "allow_sending_without_reply" allow-sending-without-reply}))

(defn send-location
  ``Sends a location.

  Optional parameter keys are: :message-thread-id, :horizontal-accuracy, :live-period, :heading, :proximity-alert-radius, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendlocation
  ``
  [bot chat-id latitude longitude &named message-thread-id
                                         horizontal-accuracy
                                         live-period
                                         heading
                                         proximity-alert-radius
                                         disable-notification
                                         protect-content
                                         reply-to-message-id
                                         allow-sending-without-reply
                                         reply-markup]
  (h/request bot "sendLocation" {"chat_id" chat-id
                                 "message_thread_id" message-thread-id
                                 "latitude" latitude
                                 "longitude" longitude
                                 "horizontal_accuracy" horizontal-accuracy
                                 "live_period" live-period
                                 "heading" heading
                                 "proximity_alert_radius" proximity-alert-radius
                                 "disable_notification" disable-notification
                                 "protect_content" protect-content
                                 "reply_to_message_id" reply-to-message-id
                                 "allow_sending_without_reply" allow-sending-without-reply
                                 "reply_markup" reply-markup}))

(defn send-venue
  ``Sends a venue.

  Optional parameter keys are: :message-thread-id, :foursquare-id, :foursquare-type, :google-place-id, :google-place-type, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendvenue
  ``
  [bot chat-id latitude longitude title address &named message-thread-id
                                                       foursquare-id
                                                       foursquare-type
                                                       google-place-id
                                                       google-place-type
                                                       disable-notification
                                                       protect-content
                                                       reply-to-message-id
                                                       allow-sending-without-reply
                                                       reply-markup]
  (h/request bot "sendVenue" {"chat_id" chat-id
                              "message_thread_id" message-thread-id
                              "latitude" latitude
                              "longitude" longitude
                              "title" title
                              "address" address
                              "foursquare_id" foursquare-id
                              "foursquare_type" foursquare-type
                              "google_place_id" google-place-id
                              "google_place_type" google-place-type
                              "disable_notification" disable-notification
                              "protect_content" protect-content
                              "reply_to_message_id" reply-to-message-id
                              "allow_sending_without_reply" allow-sending-without-reply
                              "reply_markup" reply-markup}))

(defn send-contact
  ``Sends a contact.

  Optional parameter keys are: :message-thread-id, :last-name, :vcard, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendcontact
  ``
  [bot chat-id phone-number first-name &named message-thread-id
                                              last-name
                                              vcard
                                              disable-notification
                                              protect-content
                                              reply-to-message-id
                                              allow-sending-without-reply
                                              reply-markup]
  (h/request bot "sendContact" {"chat_id" chat-id
                                "message_thread_id" message-thread-id
                                "phone_number" phone-number
                                "first_name" first-name
                                "last_name" last-name
                                "vcard" vcard
                                "disable_notification" disable-notification
                                "protect_content" protect-content
                                "reply_to_message_id" reply-to-message-id
                                "allow_sending_without_reply" allow-sending-without-reply
                                "reply_markup" reply-markup}))

(defn send-poll
  ``Sends a poll.

  Optional parameter keys are: :message-thread-id, :is-anonymous, :type, :allows-multiple-answers, :correct-option-id, :explanation, :explanation-parse-mode, :explanation-entities, :open-period, :close-date, :is-closed, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendpoll
  ``
  [bot chat-id question poll-options &named message-thread-id
                                            is-anonymous
                                            type
                                            allows-multiple-answers
                                            correct-option-id
                                            explanation
                                            explanation-parse-mode
                                            explanation-entities
                                            open-period
                                            close-date
                                            is-closed
                                            disable-notification
                                            protect-content
                                            reply-to-message-id
                                            allow-sending-without-reply
                                            reply-markup]
  (h/request bot "sendPoll" {"chat_id" chat-id
                             "message_thread_id" message-thread-id
                             "question" question
                             "options" poll-options
                             "is_anonymous" is-anonymous
                             "type" type
                             "allows_multiple_answers" allows-multiple-answers
                             "correct_option_id" correct-option-id
                             "explanation" explanation
                             "explanation_parse_mode" explanation-parse-mode
                             "explanation_entities" explanation-entities
                             "open_period" open-period
                             "close_date" close-date
                             "is_closed" is-closed
                             "disable_notification" disable-notification
                             "protect_content" protect-content
                             "reply_to_message_id" reply-to-message-id
                             "allow_sending_without_reply" allow-sending-without-reply
                             "reply_markup" reply-markup}))

(defn stop-poll
  ``Stops a poll.

  Optional parameter keys are: :reply-markup.

  https://core.telegram.org/bots/api#stoppoll
  ``
  [bot chat-id message-id &named reply-markup]
  (h/request bot "stopPoll" {"chat_id" chat-id
                             "message_id" message-id
                             "reply_markup" reply-markup}))

(defn send-chat-action
  ``Sends a chat action.

  Optional parameter keys are: :message-thread-id.

  `action` can be one of: :typing, :upload_photo, :record_video, :upload_video, :record_voice, :upload_voice, :upload_document, :choose_sticker, :find_location, :record_video_note, or :upload_video_note.

  https://core.telegram.org/bots/api#sendchataction
  ``
  [bot chat-id action &named message-thread-id]
  (h/request bot "sendChatAction" {"chat_id" chat-id
                                   "message_thread_id" message-thread-id
                                   "action" action}))

(defn send-dice
  ``Sends a dice.

  `emoji` can be one of: 🎲, 🎯, 🏀, ⚽, 🎳, or 🎰. (default: 🎲)

  Optional parameter keys are: :message-thread-id, :emoji, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#senddice
  ``
  [bot chat-id &named message-thread-id
                      emoji
                      disable-notification
                      protect-content
                      reply-to-message-id
                      allow-sending-without-reply
                      reply-markup]
  (h/request bot "sendDice" {"chat_id" chat-id
                             "message_thread_id" message-thread-id
                             "emoji" emoji
                             "disable_notification" disable-notification
                             "protect_content" protect-content
                             "reply_to_message_id" reply-to-message-id
                             "allow_sending_without_reply" allow-sending-without-reply
                             "reply_markup" reply-markup}))

(defn get-user-profile-photos
  ``Fetches user profile photos.

  Optional parameter keys are: :offset and :limit.

  https://core.telegram.org/bots/api#getuserprofilephotos
  ``
  [bot user-id &named offset
                      limit]
  (h/request bot "getUserProfilePhotos" {"user_id" user-id
                                         "offset" offset
                                         "limit" limit}))

(defn- get-file-url
  ``Generates a file's url from given :file-path.
  ``
  [bot file-path]
  (h/url-for-filepath bot file-path))

(defn get-file
  ``Fetches a file's info.

  https://core.telegram.org/bots/api#getfile
  ``
  [bot file-id]
  (let [result (h/request bot "getFile" {"file_id" file-id})]
    (if (result :ok)
      (let [file-path (get-in result [:result :file-path])
            file-url (get-file-url bot file-path)]
        (update-in result [:result :file-url] (fn [_]
                                               file-url))))))

(defn ban-chat-member
  ``Bans a chat member.

  Optional parameter keys are: :until-date and :revoke-messages

  https://core.telegram.org/bots/api#banchatmember
  ``
  [bot chat-id user-id &named until-date
                              revoke-messages]
  (h/request bot "banChatMember" {"chat_id" chat-id
                                  "user_id" user-id
                                  "until_date" until-date
                                  "revoke_messages" revoke-messages}))

(defn leave-chat
  ``Leaves a chat.

  https://core.telegram.org/bots/api#leavechat
  ``
  [bot chat-id]
  (h/request bot "leaveChat" {"chat_id" chat-id}))

(defn unban-chat-member
  ``Unbans a chat member.

  Optional parameter keys are: :only-if-banned

  https://core.telegram.org/bots/api#unbanchatmember
  ``
  [bot chat-id user-id &named only-if-banned]
  (h/request bot "unbanChatMember" {"chat_id" chat-id
                                    "user_id" user-id
                                    "only_if_banned" only-if-banned}))

(defn restrict-chat-member
  ``Restricts a chat member.

  Optional parameter keys are: :can-send-messages, :can-send-media-messages, :can-send-polls, :can-send-other-messages, :can-add-web-page-previews, :can-change-info, :can-invite-users, :can-pin-messages, and :until-date.

  https://core.telegram.org/bots/api#chatpermissions
  https://core.telegram.org/bots/api#restrictchatmember
  ``
  [bot chat-id user-id &named can-send-messages
                              can-send-media-messages
                              can-send-polls
                              can-send-other-messages
                              can-add-web-page-previews
                              can-change-info
                              can-invite-users
                              can-pin-messages
                              until-date]
  (h/request bot "restrictChatMember" {"chat_id" chat-id
                                       "user_id" user-id
                                       "permissions" {"can_send_messages" (or can-send-messages false)
                                                      "can_send_media_messages" (or can-send-media-messages false)
                                                      "can_send_polls" (or can-send-polls false)
                                                      "can_send_other_messages" (or can-send-other-messages false)
                                                      "can_add_web_page_previews" (or can-add-web-page-previews false)
                                                      "can_change_info" (or can-change-info false)
                                                      "can_invite_users" (or can-invite-users false)
                                                      "can_pin_messages" (or can-pin-messages false)}
                                       "until_date" until-date}))

(defn promote-chat-member
  ``Promotes a chat member.

  Optional parameter keys are: :is-anonymous, :can-manage-chat, :can-change-info, :can-post-messages, :can-edit-messages, :can-delete-messages, :can-manage-video-chats, :can-invite-users, :can-restrict-members, :can-pin-messages, :can-promote-members, and :can-manage-topics.

  https://core.telegram.org/bots/api#promotechatmember
  ``
  [bot chat-id user-id &named is-anonymous
                              can-manage-chat
                              can-change-info
                              can-post-messages
                              can-edit-messages
                              can-delete-messages
                              can-manage-video-chats
                              can-invite-users
                              can-restrict-members
                              can-pin-messages
                              can-promote-members
                              can-manage-topics]
  (h/request bot "promoteChatMember" {"chat_id" chat-id
                                      "user_id" user-id
                                      "is_anonymous" is-anonymous
                                      "can_manage_chat" can-manage-chat
                                      "can_change_info" can-change-info
                                      "can_post_messages" can-post-messages
                                      "can_edit_messages" can-edit-messages
                                      "can_delete_messages" can-delete-messages
                                      "can_manage_video_chats" can-manage-video-chats
                                      "can_invite_users" can-invite-users
                                      "can_restrict_members" can-restrict-members
                                      "can_pin_messages" can-pin-messages
                                      "can_promote_members" can-promote-members
                                      "can_manage_topics" can-manage-topics}))

(defn set-chat-administrator-custom-title
  ``Sets chat administrator's custom title.

  https://core.telegram.org/bots/api#setchatadministratorcustomtitle
  ``
  [bot chat-id user-id custom-title]
  (h/request bot "setChatAdministratorCustomTitle" {"chat_id" chat-id
                                                    "user_id" user-id
                                                    "custom_title" custom-title}))

(defn ban-chat-sender-chat
  ``Bans a channel chat in a supergroup or a channel.

  https://core.telegram.org/bots/api#banchatsenderchat
  ``
  [bot chat-id sender-chat-id]
  (h/request bot "banChatSenderChat" {"chat_id" chat-id
                                      "sender_chat_id" sender-chat-id}))

(defn unban-chat-sender-chat
  ``Unbans a previously banned channel in a supergroup or a channel.

  https://core.telegram.org/bots/api#unbanchatsenderchat
  ``
  [bot chat-id sender-chat-id]
  (h/request bot "unbanChatSenderChat" {"chat_id" chat-id
                                        "sender_chat_id" sender-chat-id}))

(defn set-chat-permission
  ``Sets chat permissions.

  Optional parameter keys are: :can-send-messages, :can-send-media-messages, :can-send-polls, :can-send-other-messages, :can-add-web-page-previews, :can-change-info, :can-invite-users, and :can-pin-messages.

  https://core.telegram.org/bots/api#setchatpermissions
  ``
  [bot chat-id &named can-send-messages
                      can-send-media-messages
                      can-send-polls
                      can-send-other-messages
                      can-add-web-page-previews
                      can-change-info
                      can-invite-users
                      can-pin-messages]
  (h/request bot "setChatPermission" {"chat_id" chat-id
                                      "permissions" {"can_send_messages" (or can-send-messages false)
                                                     "can_send_media_messages" (or can-send-media-messages false)
                                                     "can_send_polls" (or can-send-polls false)
                                                     "can_send_other_messages" (or can-send-other-messages false)
                                                     "can_add_web_page_previews" (or can-add-web-page-previews false)
                                                     "can_change_info" (or can-change-info false)
                                                     "can_invite_users" (or can-invite-users false)
                                                     "can_pin_messages" (or can-pin-messages false)}}))

(defn export-chat-invite-link
  ``Exports a chat invite link.

  https://core.telegram.org/bots/api#exportchatinvitelink
  ``
  [bot chat-id]
  (h/request bot "exportChatInviteLink" {"chat_id" chat-id}))

(defn create-chat-invite-link
  ``Creates a chat invite link.

  https://core.telegram.org/bots/api#createchatinvitelink
  ``
  [bot chat-id &named name
                      expire-date
                      member-limit
                      creates-join-request]
  (h/request bot "createChatInviteLink" {"chat_id" chat-id
                                         "name" name
                                         "expire_date" expire-date
                                         "member_limit" member-limit
                                         "creates_join_request" creates-join-request}))

(defn edit-chat-invite-link
  ``Edits a chat invite link.

  https://core.telegram.org/bots/api#editchatinvitelink
  ``
  [bot chat-id invite-link &named name
                                  expire-date
                                  member-limit
                                  creates-join-request]
  (h/request bot "editChatInviteLink" {"chat_id" chat-id
                                       "name" name
                                       "invite_link" invite-link
                                       "expire_date" expire-date
                                       "member_limit" member-limit
                                       "creates_join_request" creates-join-request}))

(defn revoke-chat-invite-link
  ``Revokes a chat invite link.

  https://core.telegram.org/bots/api#revokechatinvitelink
  ``
  [bot chat-id invite-link]
  (h/request bot "revokeChatInviteLink" {"chat_id" chat-id
                                         "invite_link" invite-link}))

(defn approve-chat-join-request
  ``Approves chat join request.

  https://core.telegram.org/bots/api#approvechatjoinrequest
  ``
  [bot chat-id user-id]
  (h/request bot "approveChatJoinRequest" {"chat_id" chat-id
                                           "user_id" user-id}))

(defn decline-chat-join-request
  ``Declines chat join request.

  https://core.telegram.org/bots/api#declinechatjoinrequest
  ``
  [bot chat-id user-id]
  (h/request bot "declineChatJoinRequest" {"chat_id" chat-id
                                           "user_id" user-id}))

(defn set-chat-photo
  ``Sets a chat photo.

  https://core.telegram.org/bots/api#setchatphoto
  ``
  [bot chat-id photo]
  (h/request bot "setChatPhoto" {"chat_id" chat-id
                                 "photo" photo}))

(defn delete-chat-photo
  ``Deletes a chat photo.

  https://core.telegram.org/bots/api#deletechatphoto
  ``
  [bot chat-id]
  (h/request bot "deleteChatPhoto" {"chat_id" chat-id}))

(defn set-chat-title
  ``Sets a chat title.

  https://core.telegram.org/bots/api#setchattitle
  ``
  [bot chat-id title]
  (h/request bot "setChatTitle" {"chat_id" chat-id
                                 "title" title}))

(defn set-chat-description
  ``Sets a chat description.

  https://core.telegram.org/bots/api#setchatdescription
  ``
  [bot chat-id description]
  (h/request bot "setChatDescription" {"chat_id" chat-id
                                       "description" description}))

(defn pin-chat-message
  ``Pins a chat message.

  Optional parameter keys are: :disable-notification.

  https://core.telegram.org/bots/api#pinchatmessage
  ``
  [bot chat-id message-id &named disable-notification]
  (h/request bot "pinChatMessage" {"chat_id" chat-id
                                   "message_id" message-id
                                   "disable_notification" disable-notification}))

(defn unpin-chat-message
  ``Unpins a chat message.

  https://core.telegram.org/bots/api#unpinchatmessage
  ``
  [bot chat-id &named message-id]
  (h/request bot "unpinChatMessage" {"chat_id" chat-id
                                     "message_id" message-id}))

(defn unpin-all-chat-messages
  ``Unpins all chat messages.

  https://core.telegram.org/bots/api#unpinallchatmessages
  ``
  [bot chat-id]
  (h/request bot "unpinAllChatMessages" {"chat_id" chat-id}))

(defn get-chat
  ``Fetches a chat.

  https://core.telegram.org/bots/api#getchat
  ``
  [bot chat-id]
  (h/request bot "getChat" {"chat_id" chat-id}))

(defn get-chat-administrators
  ``Fetches chat administrators.

  https://core.telegram.org/bots/api#getchatadministrators
  ``
  [bot chat-id]
  (h/request bot "getChatAdministrators" {"chat_id" chat-id}))

(defn get-chat-member-count
  ``Fetches the count of chat members.

  https://core.telegram.org/bots/api#getchatmembercount
  ``
  [bot chat-id]
  (h/request bot "getChatMemberCount" {"chat_id" chat-id}))

(defn get-chat-member
  ``Fetches a chat member.

  https://core.telegram.org/bots/api#getchatmember
  ``
  [bot chat-id user-id]
  (h/request bot "getChatMember" {"chat_id" chat-id
                                  "user_id" user-id}))

(defn set-chat-sticker-set
  ``Sets a chat sticker set.

  https://core.telegram.org/bots/api#setchatstickerset
  ``
  [bot chat-id sticker-set-name]
  (h/request bot "setChatStickerSet" {"chat_id" chat-id
                                      "sticker_set_name" sticker-set-name}))

(defn delete-chat-sticker-set
  ``Deletes a chat sticker set.

  https://core.telegram.org/bots/api#deletechatstickerset
  ``
  [bot chat-id]
  (h/request bot "deleteChatStickerSet" {"chat_id" chat-id}))

(defn answer-callback-query
  ``Answers a callback query.

  Optional parameter keys are: :text, :show-alert, :url, and :cache-time.

  https://core.telegram.org/bots/api#answercallbackquery
  ``
  [bot callback-query-id &named text
                                show-alert
                                url
                                cache-time]
  (h/request bot "answerCallbackQuery" {"callback_query_id" callback-query-id
                                        "text" text
                                        "show_alert" show-alert
                                        "url" url
                                        "cache_time" cache-time}))

(defn get-my-commands
  ``Gets this bot's commands.

  https://core.telegram.org/bots/api#getmycommands
  ``
  [bot &named scope
              language-code]
  (h/request bot "getMyCommands" {"scope" scope
                                  "language_code" language-code}))

(defn set-my-commands
  ``Sets this bot's commands.

  https://core.telegram.org/bots/api#setmycommands
  ``
  [bot commands &named scope
                       language-code]
  (h/request bot "setMyCommands" {"commands" commands
                                  "scope" scope
                                  "language_code" language-code}))

(defn delete-my-commands
  ``Deletes this bot's commands.

  https://core.telegram.org/bots/api#deletemycommands
  ``
  [bot &named scope
              language-code]
  (h/request bot "deleteMyCommands" {"scope" scope
                                     "language_code" language-code}))

(defn set-chat-menu-button
  ``Sets the bot's menu button.

  Optional parameter keys are: :chat-id, and :menu-button.

  https://core.telegram.org/bots/api#setchatmenubutton
  ``
  [bot &named chat-id
              menu-button]
  (h/request bot "setChatMenuButton" {"chat_id" chat-id
                                      "menu_button" menu-button}))

(defn get-chat-menu-button
  ``Gets the bot's menu button.

  Optional parameter keys are: :chat-id.

  https://core.telegram.org/bots/api#getchatmenubutton
  ``
  [bot &named chat-id]
  (h/request bot "getChatMenuButton" {"chat_id" chat-id}))

(defn set-my-default-administrator-rights
  ``Sets my default administrator rights.

  Optional parameter keys are: :rights, and :for-channels.

  https://core.telegram.org/bots/api#setmydefaultadministratorrights
  ``
  [bot &named rights
              for-channels]
  (h/request bot "setMyDefaultAdministratorRights" {"rights" rights
                                                    "for_channels" for-channels}))

(defn get-my-default-administrator-rights
  ``Gets my default administrator rights.

  Optional parameter keys are: :for-channels.

  https://core.telegram.org/bots/api#getmydefaultadministratorrights
  ``
  [bot &named for-channels]
  (h/request bot "getMyDefaultAdministratorRights" {"for_channels" for-channels}))

(defn edit-message-text
  ``Edits a message's text.

  Required parameter keys are: :chat-id + :message-id (when :inline-message-id is not given)
  or :inline-message-id (when :chat-id & :message-id are not given)

  Optional parameter keys are: :parse-mode, :entities, :disable-web-page-preview, and :reply-markup.

  https://core.telegram.org/bots/api#editmessagetext
  ``
  [bot text &named chat-id
                   message-id
                   inline-message-id
                   parse-mode
                   entities
                   disable-web-page-preview
                   reply-markup]
  (h/request bot "editMessageText" {"text" text
                                    "chat_id" chat-id
                                    "message_id" message-id
                                    "inline_message_id" inline-message-id
                                    "parse_mode" parse-mode
                                    "entities" entities
                                    "disable_web_page_preview" disable-web-page-preview
                                    "reply_markup" reply-markup}))

(defn edit-message-caption
  ``Edits a message's caption.

  Required parameter keys are: :chat-id + :message-id (when :inline-message-id is not given)
  or :inline-message-id (when :chat-id & :message-id are not given)

  Optional parameter keys are: :parse-mode, :caption-entities, and :reply-markup.

  https://core.telegram.org/bots/api#editmessagecaption
  ``
  [bot caption &named chat-id
                      message-id
                      inline-message-id
                      parse-mode
                      caption-entities
                      reply-markup]
  (h/request bot "editMessageCaption" {"caption" caption
                                       "chat_id" chat-id
                                       "message_id" message-id
                                       "inline_message_id" inline-message-id
                                       "parse_mode" parse-mode
                                       "caption_entities" caption-entities
                                       "reply_markup" reply-markup}))

(defn edit-message-media
  ``Edits a message's media.

  Required parameter keys are: :chat-id + :message-id (when :inline-message-id is not given)
  or :inline-message-id (when :chat-id & :message-id are not given)

  Optional parameter keys are: :reply-markup.

  https://core.telegram.org/bots/api#editmessagemedia
  ``
  [bot media &named chat-id
                    message-id
                    inline-message-id
                    reply-markup]
  (h/request bot "editMessageMedia" {"media" media
                                     "chat_id" chat-id
                                     "message_id" message-id
                                     "inline_message_id" inline-message-id
                                     "reply_markup" reply-markup}))

(defn edit-message-reply-markup
  ``Edits a message's reply markup.

  Required parameter keys are: :chat-id + :message-id (when :inline-message-id is not given)
  or :inline-message-id (when :chat-id & :message-id are not given)

  Optional parameter keys are: :reply-markup.

  https://core.telegram.org/bots/api#editmessagereplymarkup
  ``
  [bot &named chat-id
              message-id
              inline-message-id
              reply-markup]
  (h/request bot "editMessageReplyMarkup" {"chat_id" chat-id
                                           "message_id" message-id
                                           "inline_message_id" inline-message-id
                                           "reply_markup" reply-markup}))

(defn edit-message-live-location
  ``Edits a message's live location.

  Required parameter keys are: :chat-id + :message-id (when :inline-message-id is not given)
  or :inline-message-id (when :chat-id & :message-id are not given)

  Optional parameter keys are: :horizontal-accuracy, :heading, :proximity-alert-radius, and :reply-markup.

  https://core.telegram.org/bots/api#editmessagelivelocation
  ``
  [bot latitude longitude &named chat-id
                                 message-id
                                 inline-message-id
                                 horizontal-accuracy
                                 heading
                                 proximity-alert-radius
                                 reply-markup]
  (h/request bot "editMessageLiveLocation" {"chat_id" chat-id
                                            "message_id" message-id
                                            "inline_message_id" inline-message-id
                                            "latitude" latitude
                                            "longitude" longitude
                                            "horizontal_accuracy" horizontal-accuracy
                                            "heading" heading
                                            "proximity_alert_radius" proximity-alert-radius
                                            "reply_markup" reply-markup}))

(defn stop-message-live-location
  ``Stops a message's live location.

  Required parameter keys are: :chat-id + :message-id (when :inline-message-id is not given)
  or :inline-message-id (when :chat-id & :message-id are not given)

  Optional parameter keys are: :reply-markup.

  https://core.telegram.org/bots/api#stopmessagelivelocation
  ``
  [bot &named chat-id
              message-id
              inline-message-id
              reply-markup]
  (h/request bot "stopMessageLiveLocation" {"chat_id" chat-id
                                            "message_id" message-id
                                            "inline_message_id" inline-message-id
                                            "reply_markup" reply-markup}))

(defn delete-message
  ``Deletes a message.

  https://core.telegram.org/bots/api#deletemessage
  ``
  [bot chat-id message-id]
  (h/request bot "deleteMessage" {"chat_id" chat-id
                                  "message_id" message-id}))

(defn answer-inline-query
  ``Answers an inline query.

  Optional parameter keys are: :cache-time, :is-personal, :next-offset, :switch-pm-text, and :switch-pm-parameter.

  https://core.telegram.org/bots/api#answerinlinequery
  ``
  [bot inline-query-id results &named cache-time
                                      is-personal
                                      next-offset
                                      switch-pm-text
                                      switch-pm-parameter]
  (h/request bot "answerInlineQuery" {"inline_query_id" inline-query-id
                                      "results" results
                                      "cache_time" cache-time
                                      "is_personal" is-personal
                                      "next_offset" next-offset
                                      "switch_pm_text" switch-pm-text
                                      "switch_pm_parameter" switch-pm-parameter}))

(defn send-invoice
  ``Sends an invoice.

  Optional parameter keys are: :message-thread-id, :max-tip-amount, :suggested-tip-amounts, :start-parameter, :provider-data, :photo-url, :photo-size, :photo-width, :photo-height, :need-name, :need-phone-number, :need-email, :need-shipping-address, :send-phone-number-to-provider, :send-email-to-provider, :is-flexible, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendinvoice
  ``
  [bot chat-id title description payload provider-token currency prices &named message-thread-id
                                                                               max-tip-amount
                                                                               suggested-tip-amounts
                                                                               start-parameter
                                                                               provider-data
                                                                               photo-url
                                                                               photo-size
                                                                               photo-width
                                                                               photo-height
                                                                               need-name
                                                                               need-phone-number
                                                                               need-email
                                                                               need-shipping-address
                                                                               send-phone-number-to-provider
                                                                               send-email-to-provider
                                                                               is-flexible
                                                                               disable-notification
                                                                               protect-content
                                                                               reply-to-message-id
                                                                               allow-sending-without-reply
                                                                               reply-markup]
  (h/request bot "sendInvoice" {"chat_id" chat-id
                                "message_thread_id" message-thread-id
                                "title" title
                                "description" description
                                "payload" payload
                                "provider_token" provider-token
                                "currency" currency
                                "prices" prices
                                "max_tip_amount" max-tip-amount
                                "suggested_tip_amounts" suggested-tip-amounts
                                "start_parameter" start-parameter
                                "provider_data" provider-data
                                "photo_url" photo-url
                                "photo_size" photo-size
                                "photo_width" photo-width
                                "photo_height" photo-height
                                "need_name" need-name
                                "need_phone_number" need-phone-number
                                "need_email" need-email
                                "need_shipping_address" need-shipping-address
                                "send_phone_number_to_provider" send-phone-number-to-provider
                                "send_email_to_provider" send-email-to-provider
                                "is_flexible" is-flexible
                                "disable_notification" disable-notification
                                "protect_content" protect-content
                                "reply_to_message_id" reply-to-message-id
                                "allow_sending_without_reply" allow-sending-without-reply
                                "reply_markup" reply-markup}))

(defn answer-shipping-query
  ``Answers a shipping query.

  If `ok` is true, :shipping-options should be included in `options`. Otherwise, :error-message should be included.

  https://core.telegram.org/bots/api#answershippingquery
  ``
  [bot shipping-query-id ok &named shipping-options
                                   error-message]
  (h/request bot "answerShippingQuery" {"shipping_query_id" shipping-query-id
                                        "ok" ok
                                        "shipping_options" shipping-options
                                        "error_message" error-message}))

(defn answer-pre-checkout-query
  ``Answers a pre-checkout query.

  If `ok` is false, :error-message should be included in `options`.

  https://core.telegram.org/bots/api#answerprecheckoutquery
  ``
  [bot pre-checkout-query-id ok &named error-message]
  (h/request bot "answerPreCheckoutQuery" {"pre_checkout_query_id" pre-checkout-query-id
                                           "ok" ok
                                           "error_message" error-message}))

(defn answer-web-app-query
  ``Answers a web app query.

  https://core.telegram.org/bots/api#answerwebappquery
  ``
  [bot web-app-query-id result]
  (h/request bot "answerWebAppQuery" {"web_app_query_id" web-app-query-id
                                      "result" result}))

(defn send-game
  ``Sends a game.

  Optional parameter keys are: :message-thread-id, :disable-notification, :reply-to-message-id, :allow-sending-without-reply, and :reply-markup.

  https://core.telegram.org/bots/api#sendgame
  ``
  [bot chat-id game-short-name &named message-thread-id
                                      disable-notification
                                      protect-content
                                      reply-to-message-id
                                      allow-sending-without-reply
                                      reply-markup]
  (h/request bot "sendGame" {"chat_id" chat-id
                             "message_thread_id" message-thread-id
                             "game_short_name" game-short-name
                             "disable_notification" disable-notification
                             "protect_content" protect-content
                             "reply_to_message_id" reply-to-message-id
                             "allow_sending_without_reply" allow-sending-without-reply
                             "reply_markup" reply-markup}))

(defn set-game-score
  ``Sets score for a game.

  Required parameter keys are: :chat-id + :message-id (when :inline-message-id is not given)
  or :inline-message-id (when :chat-id & :message-id are not given)

  Optional parameter keys are: :force, and :disable-edit-message.

  https://core.telegram.org/bots/api#setgamescore
  ``
  [bot user-id score &named chat-id
                            message-id
                            inline-message-id
                            force
                            disable-edit-message]
  (h/request bot "setGameScore" {"user_id" user-id
                                 "score" score
                                 "chat_id" chat-id
                                 "message_id" message-id
                                 "inline_message_id" inline-message-id
                                 "force" force
                                 "disable_edit_message" disable-edit-message}))

(defn get-game-highscores
  ``Fetches a game's highscores.

  Required parameter keys are: :chat-id + :message-id (when :inline-message-id is not given)
  or :inline-message-id (when :chat-id & :message-id are not given)

  https://core.telegram.org/bots/api#getgamehighscores
  ``
  [bot user-id &named chat-id
                      message-id
                      inline-message-id]
  (h/request bot "getGameHighScores" {"user_id" user-id
                                      "chat_id" chat-id
                                      "message_id" message-id
                                      "inline_message_id" inline-message-id}))

(defn create-forum-topic
  ``Creates a topic in a forum supergroup chat.

  https://core.telegram.org/bots/api#createforumtopic
  ``
  [bot chat-id name &named icon-color
                           icon-custom-emoji-id]
  (h/request bot "createForumTopic" {"chat_id" chat-id
                                     "name" name
                                     "icon_color" icon-color
                                     "icon_custom_emoji_id" icon-custom-emoji-id}))

(defn edit-forum-topic
  ``Edits name and icon of a topic in a forum supergroup chat.

  Optional parameter keys are: :name, and :icon-custom-emoji-id.

  https://core.telegram.org/bots/api#editforumtopic
  ``
  [bot chat-id message-thread-id &named name
                                        icon-custom-emoji-id]
  (h/request bot "editForumTopic" {"chat_id" chat-id
                                   "message_thread_id" message-thread-id
                                   "name" name
                                   "icon_custom_emoji_id" icon-custom-emoji-id}))

(defn close-forum-topic
  ``Closes an open topic in a forum supergroup chat.

  https://core.telegram.org/bots/api#closeforumtopic
  ``
  [bot chat-id message-thread-id]
  (h/request bot "closeForumTopic" {"chat_id" chat-id
                                    "message_thread_id" message-thread-id}))

(defn reopen-forum-topic
  ``Reopens a closed topic in a forum supergroup chat.

  https://core.telegram.org/bots/api#reopenforumtopic
  ``
  [bot chat-id message-thread-id]
  (h/request bot "reopenForumTopic" {"chat_id" chat-id
                                     "message_thread_id" message-thread-id}))

(defn delete-forum-topic
  ``Deletes a forum topic along with all its messages in a forum supergroup chat.

  https://core.telegram.org/bots/api#deleteforumtopic
  ``
  [bot chat-id message-thread-id]
  (h/request bot "deleteForumTopic" {"chat_id" chat-id
                                     "message_thread_id" message-thread-id}))

(defn unpin-all-forum-topic-messages
  ``Clears the list of pinned messages in a forum topic.

  https://core.telegram.org/bots/api#unpinallforumtopicmessages
  ``
  [bot chat-id message-thread-id]
  (h/request bot "unpinAllForumTopicMessages" {"chat_id" chat-id
                                               "message_thread_id" message-thread-id}))

(defn edit-general-forum-topic
  ``Edits the name of the 'General' topic in a forum supergroup chat.

  https://core.telegram.org/bots/api#editgeneralforumtopic
  ``
  [bot chat-id name]
  (h/request bot "editGeneralForumTopic" {"chat_id" chat-id
                                          "name" name}))

(defn close-general-forum-topic
  ``Closes an open 'General' topic in a forum supergroup chat.

  https://core.telegram.org/bots/api#closegeneralforumtopic
  ``
  [bot chat-id]
  (h/request bot "closeGeneralForumTopic" {"chat_id" chat-id}))

(defn reopen-general-forum-topic
  ``Reopens a closed 'General' topic in a forum supergroup chat.

  https://core.telegram.org/bots/api#reopengeneralforumtopic
  ``
  [bot chat-id]
  (h/request bot "reopenGeneralForumTopic" {"chat_id" chat-id}))

(defn hide-general-forum-topic
  ``Hides the 'General' topic in a forum supergroup chat.

  https://core.telegram.org/bots/api#hidegeneralforumtopic
  ``
  [bot chat-id]
  (h/request bot "hideGeneralForumTopic" {"chat_id" chat-id}))

(defn unhide-general-forum-topic
  ``Unhides the 'General' topic in a forum supergroup chat.

  https://core.telegram.org/bots/api#unhidegeneralforumtopic
  ``
  [bot chat-id]
  (h/request bot "unhideGeneralForumTopic" {"chat_id" chat-id}))

(defn get-forum-topic-icon-stickers
  ``Gets custom emoji stickers.

  https://core.telegram.org/bots/api#getforumtopiciconstickers
  ``
  [bot]
  (h/request bot "getForumTopicIconStickers" {}))


########################
# bot specification and factory functions

# prototype of bot
(def Bot
  @{
    # properties
    :token "--not-set-yet--"
    :interval-seconds default-interval-seconds
    :limit-count default-limit-count
    :timeout-seconds default-timeout-seconds
    :verbose? false

    # functions (NOTE: append more here when they are added)
    :delete-webhook delete-webhook
    :get-me get-me
    :get-updates get-updates
    :poll-updates poll-updates
    :stop-polling-updates stop-polling-updates
    :send-message send-message
    :forward-message forward-message
    :copy-message copy-message
    :send-photo send-photo
    :send-audio send-audio
    :send-document send-document
    :send-sticker send-sticker
    :get-sticker-set get-sticker-set
    :upload-sticker-file upload-sticker-file
    :create-new-sticker-set create-new-sticker-set
    :add-sticker-to-set add-sticker-to-set
    :set-sticker-position-in-set set-sticker-position-in-set
    :delete-sticker-from-set delete-sticker-from-set
    :set-sticker-set-thumb set-sticker-set-thumb
    :send-video send-video
    :send-animation send-animation
    :send-voice send-voice
    :send-video-note send-video-note
    :send-media-group send-media-group
    :send-location send-location
    :send-venue send-venue
    :send-contact send-contact
    :send-poll send-poll
    :stop-poll stop-poll
    :send-chat-action send-chat-action
    :send-dice send-dice
    :get-user-profile-photos get-user-profile-photos
    :get-file get-file
    :ban-chat-member ban-chat-member
    :leave-chat leave-chat
    :unban-chat-member unban-chat-member
    :restrict-chat-member restrict-chat-member
    :promote-chat-member promote-chat-member
    :set-chat-administrator-custom-title set-chat-administrator-custom-title
    :ban-chat-sender-chat ban-chat-sender-chat
    :unban-chat-sender-chat unban-chat-sender-chat
    :set-chat-permission set-chat-permission
    :export-chat-invite-link export-chat-invite-link
    :create-chat-invite-link create-chat-invite-link
    :edit-chat-invite-link edit-chat-invite-link
    :revoke-chat-invite-link revoke-chat-invite-link
    :approve-chat-join-request approve-chat-join-request
    :decline-chat-join-request decline-chat-join-request
    :set-chat-photo set-chat-photo
    :delete-chat-photo delete-chat-photo
    :set-chat-title set-chat-title
    :set-chat-description set-chat-description
    :pin-chat-message pin-chat-message
    :unpin-chat-message unpin-chat-message
    :unpin-all-chat-messages unpin-all-chat-messages
    :get-chat get-chat
    :get-chat-administrators get-chat-administrators
    :get-chat-member-count get-chat-member-count
    :get-chat-member get-chat-member
    :set-chat-sticker-set set-chat-sticker-set
    :delete-chat-sticker-set delete-chat-sticker-set
    :answer-callback-query answer-callback-query
    :get-my-commands get-my-commands
    :set-my-commands set-my-commands
    :delete-my-commands delete-my-commands
    :set-chat-menu-button set-chat-menu-button
    :get-chat-menu-button get-chat-menu-button
    :set-my-default-administrator-rights set-my-default-administrator-rights
    :get-my-default-administrator-rights get-my-default-administrator-rights
    :edit-message-text edit-message-text
    :edit-message-caption edit-message-caption
    :edit-message-media edit-message-media
    :edit-message-reply-markup edit-message-reply-markup
    :edit-message-live-location edit-message-live-location
    :stop-message-live-location stop-message-live-location
    :delete-message delete-message
    :answer-inline-query answer-inline-query
    :send-invoice send-invoice
    :answer-shipping-query answer-shipping-query
    :answer-pre-checkout-query answer-pre-checkout-query
    :answer-web-app-query answer-web-app-query
    :send-game send-game
    :set-game-score set-game-score
    :get-game-highscores get-game-highscores
    :create-forum-topic create-forum-topic
    :edit-forum-topic edit-forum-topic
    :close-forum-topic close-forum-topic
    :reopen-forum-topic reopen-forum-topic
    :delete-forum-topic delete-forum-topic
    :unpin-all-forum-topic-messages unpin-all-forum-topic-messages
    :get-forum-topic-icon-stickers get-forum-topic-icon-stickers})

# create a new bot with given params
(defn new-bot
  ``Creates a new bot with given token and options.
  ``
  [token &named interval-seconds
                limit-count
                timeout-seconds
                verbose?]
  (table/setproto
    @{:token token
      :interval-seconds (or interval-seconds default-interval-seconds)
      :limit-count (or limit-count default-limit-count)
      :timeout-seconds (or timeout-seconds default-timeout-seconds)
      :verbose? (or verbose? false)}
    Bot))

(defn split-text
  ``Splits given `text` with new lines, into an array of strings.

  Each string's length does not exceed `chars-limit`.

  This function can be used to split long messages before sending.
  ``
  [text &opt chars-limit]

  (default chars-limit 4096)

  (let [lines (string/split "\n" text)]
    (reduce (fn [acc line]
              (if-let [lst (last acc)
                       candidate (string/join [lst line] "\n")]
                (if (<= (length candidate) chars-limit)
                  (do
                    (array/pop acc)
                    (array/concat acc candidate))
                  (array/concat acc line))
                (array/concat acc line))
              acc)
            @[] lines)))
