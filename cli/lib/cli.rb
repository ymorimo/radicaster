#!/usr/bin/env ruby

require "aws-sdk-s3"
require "aws-sdk-lambda"
require "aws-sdk-eventbridge"

require "cli/handler"
require "cli/definition"
require "cli/eventbridge"
require "cli/execution_schedule"
require "cli/lambda"
require "cli/s3"

module Radicaster
  module CLI
    def main(argv)
      # Configure SSL for AWS SDK clients
      aws_config = configure_ssl

      bucket = ENV["RADICASTER_S3_BUCKET"] or raise "ENV['RADICASTER_S3_BUCKET'] must be set"
      s3_client = Aws::S3::Client.new(aws_config)
      storage = S3.new(s3_client, bucket)

      rec_radiko_arn = ENV["RADICASTER_REC_RADIKO_ARN"] or raise "ENV['RADICASTER_REC_RADIKO_ARN'] must be set"

      eb_client = Aws::EventBridge::Client.new(aws_config)
      scheduler = EventBridge.new(eb_client, rec_radiko_arn)

      lambda_client = Aws::Lambda::Client.new(aws_config)
      recorder = Lambda.new(lambda_client, rec_radiko_arn)

      h = Handler.new(storage, scheduler, recorder)
      h.handle(argv)
    end

    def configure_ssl
      config = {
        region: ENV["AWS_REGION"] || "ap-northeast-1"
      }

      # Try to use system CA bundle if available (for macOS/Linux)
      ca_bundle_paths = [
        "/etc/ssl/certs/ca-certificates.crt",  # Debian/Ubuntu/Gentoo etc.
        "/etc/ssl/certs/ca-bundle.crt",         # Fedora/RHEL 6
        "/etc/ssl/ca-bundle.pem",               # OpenSUSE
        "/etc/pki/tls/certs/ca-bundle.crt",    # Fedora/RHEL 7
        "/etc/ssl/cert.pem",                    # macOS/OS X
        "/usr/local/etc/openssl/cert.pem",     # Homebrew OpenSSL on macOS
        "/usr/local/etc/openssl@1.1/cert.pem"  # Homebrew OpenSSL 1.1 on macOS
      ]

      ca_bundle_path = ca_bundle_paths.find { |path| File.exist?(path) }
      if ca_bundle_path && ENV["RADICASTER_USE_SYSTEM_CA"] != "false"
        config[:ssl_ca_bundle] = ca_bundle_path
      end

      # If SSL issues persist, you can temporarily disable peer verification
      # WARNING: This reduces security and should only be used for development
      if ENV["RADICASTER_SKIP_SSL_VERIFY"] == "true"
        puts "WARNING: SSL verification disabled. This is insecure!"
        config[:ssl_verify_peer] = false
      end

      config
    end

    module_function :main, :configure_ssl
  end
end
