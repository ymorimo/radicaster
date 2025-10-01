require "date"
require "time"

require "aws-sdk-s3"

module Radicaster
  module RecRadiko
    class RecCommand
      attr_reader :id

      def initialize(id:)
        @id = id
      end
    end

    # CloudWatchのイベントをハンドルしてradikoを録音する
    class Handler
      def initialize(logger, recorder, storage)
        @logger = logger
        @recorder = recorder
        @storage = storage
      end

      def handle(event:, context:)
        logger.debug(event)
        validate(event)
        cmd = build_command(event)

        # Parse time from event if provided
        time = nil
        if event["time"]
          begin
            time = Time.parse(event["time"])
            logger.info("Using provided time: #{time}")
          rescue => e
            logger.warn("Failed to parse time from event: #{e.message}, using current time")
          end
        end

        exec(cmd, time)
      end

      private

      attr_reader :logger, :recorder, :storage

      def validate(event)
        raise "id must be set" unless event["id"]
      end

      def build_command(event)
        id = event["id"]
        RecCommand.new(
          id: id,
        )
      end

      def exec(cmd, time = nil)
        def_ = storage.find_definition(cmd.id)
        logger.info("Definition #{cmd.id} found")

        # Use provided time or current time
        recording_time = time || Time.now
        logger.info("Starting recording for time: #{recording_time}")
        episode = recorder.rec(def_, recording_time)
        logger.info("Recording finished")

        logger.info("Saving the episode to storage")
        storage.save_episode(episode)
        logger.info("Finished saving the episode.")
      end
    end
  end
end
