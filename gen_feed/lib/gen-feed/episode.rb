module Radicaster
  module GenFeed
    class Episode
      attr_reader :url, :size, :last_modified, :definition

      def initialize(url:, size:, last_modified:, definition: nil)
        @url = url
        @size = size
        @last_modified = last_modified
        @definition = definition
      end

      def title
        filename = url.split("/")[-1]

        # Extract date from filename (assuming format like "20250925.m4a")
        if match = filename.match(/\b(\d{4})(\d{2})(\d{2})\b/)
          date_str = "#{match[1]}-#{match[2]}-#{match[3]}"

          # If definition has a title, use it with the date
          if definition && definition.title
            "#{definition.title} #{date_str}"
          else
            filename
          end
        else
          filename
        end
      end
    end
  end
end
