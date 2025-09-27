require "tempfile"
require "time"

module Radicaster
  module RecRadiko
    class Ffmpeg
      def concat(aac_paths, def_ = nil)
        # NOTE:
        # ffmpegでファイルを連結するには元ファイルのリストを書いたテキストを
        # 入力ファイルとして食わせる必要がある
        # https://trac.ffmpeg.org/wiki/Concatenate
        f = Tempfile.new("inputs")
        aac_paths.each do |aac_path|
          f.write("file '#{aac_path}'\n")
        end
        f.close

        # NOTE:
        # Apple Podcast Appでaacをうまく扱えなかったので連結ついでにm4aに変換
        m4a_path = aac_paths[0].sub(/.aac\z/, ".m4a")

        # Build ffmpeg command with optional metadata
        cmd_parts = ["ffmpeg -y -f concat -safe 0 -i #{f.path}"]

        if def_ && (def_.title || def_.author)
          # Add metadata if available
          if def_.title
            # Album metadata with "Radio: " prefix
            cmd_parts << "-metadata \"album=Radio: #{def_.title}\""

            # Title metadata with date
            date_str = Time.now.strftime("%Y-%m-%d")
            cmd_parts << "-metadata \"title=#{def_.title} #{date_str}\""
          end

          if def_.author
            cmd_parts << "-metadata \"artist=#{def_.author}\""
          end
        end

        cmd_parts << "-c copy #{m4a_path}"
        cmd = cmd_parts.join(" ")

        system(cmd, exception: true)
        m4a_path
      end
    end
  end
end
