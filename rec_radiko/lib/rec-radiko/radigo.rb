require "logger"

module Radicaster
  module RecRadiko
    class Radigo
      def initialize(workdir, email = nil, password = nil, logger = nil)
        @workdir = workdir
        @logger = logger || Logger.new(STDOUT)

        raise "email and password must be passed in together" if email.nil? ^ password.nil?
        @email = email
        @password = password
      end

      def rec(area, station, start_time)
        env = ["RADIGO_HOME=#{workdir}"]
        if !email.nil? && !password.nil?
          env.push("RADIKO_MAIL=#{email}", "RADIKO_PASSWORD=#{password}")
        end
        start_str = start_time.strftime("%Y%m%d%H%M%S")

        rm_cmd = "rm -f #{output_path(workdir, start_str, station)}"
        @logger.info("Executing command: #{rm_cmd}")
        system(rm_cmd)

        radigo_cmd = "/usr/bin/env #{env.join(" ")} radigo rec -area=#{area} -id=#{station} -s=#{start_str}"
        @logger.info("Executing command: #{radigo_cmd}")
        system(radigo_cmd, exception: true)

        output_path(workdir, start_str, station)
      end

      private

      def output_path(workdir, start, station)
        "#{workdir}/#{start}-#{station}.aac"
      end

      attr_reader :workdir, :email, :password, :logger
    end
  end
end
