require "logger"

module Radicaster
  module RecRadiko
    class Recorder
      def initialize(radiko, concater, logger = nil)
        @radiko = radiko
        @concater = concater
        @logger = logger || Logger.new(STDOUT)
      end

      def rec(def_, now)
        start_times = def_.latest_start_times(now)
        logger.info "Recording #{start_times.length} segment(s) for program '#{def_.title}'"
        start_times.each_with_index do |st, idx|
          logger.info "  Segment #{idx + 1}: #{st.strftime('%Y-%m-%d %H:%M:%S')}"
        end

        paths = start_times.map.with_index { |st, idx|
          logger.info "Downloading segment #{idx + 1}/#{start_times.length}: #{st.strftime('%Y-%m-%d %H:%M:%S')}"
          path = radiko.rec(def_.area, def_.station, st)
          logger.info "Downloaded to: #{path}"
          path
        }

        logger.info "Concatenating #{paths.length} segment(s)..."
        concated_path = concater.concat(paths, def_)
        logger.info "Concatenated to: #{concated_path}"

        Episode.new(
          id: def_.id,
          station: def_.station,
          start_time: start_times[0],
          local_path: concated_path,
        )
      end

      private

      attr_reader :radiko, :concater, :logger
    end
  end
end
