require "time"
require "json"
require "aws-sdk-lambda"
require "net/http"

module Radicaster
  class RecordCLI
    def self.main(argv)
      if argv.length != 2
        puts "Usage: record <id> <YYYYMMDD>"
        puts "Example: record test-program 20250925"
        exit 1
      end

      id = argv[0]
      date_str = argv[1]

      # Parse date string
      begin
        # Parse YYYYMMDD format
        unless date_str.match?(/^\d{8}$/)
          raise ArgumentError, "Date must be in YYYYMMDD format"
        end

        year = date_str[0..3].to_i
        month = date_str[4..5].to_i
        day = date_str[6..7].to_i

        # Create timestamp for next day at 00:00:00 JST
        # TZ environment variable should be set to JST/Asia/Tokyo
        ENV["TZ"] = "Asia/Tokyo"
        next_day = Time.new(year, month, day) + (24 * 60 * 60)  # Add 1 day
        timestamp = Time.new(next_day.year, next_day.month, next_day.day, 0, 0, 0)
      rescue => e
        puts "Error parsing date: #{e.message}"
        exit 1
      end

      # Get Lambda function ARN from environment
      lambda_arn = ENV["RADICASTER_REC_RADIKO_ARN"]
      unless lambda_arn
        puts "Error: RADICASTER_REC_RADIKO_ARN environment variable is not set"
        exit 1
      end

      # Extract function name from ARN
      function_name = lambda_arn.split(":").last

      # Create Lambda client with SSL configuration
      lambda_config = {
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
        lambda_config[:ssl_ca_bundle] = ca_bundle_path
      end

      # If SSL issues persist, you can temporarily disable peer verification
      # WARNING: This reduces security and should only be used for development
      if ENV["RADICASTER_SKIP_SSL_VERIFY"] == "true"
        puts "WARNING: SSL verification disabled. This is insecure!"
        lambda_config[:ssl_verify_peer] = false
      end

      lambda_client = Aws::Lambda::Client.new(lambda_config)

      # Create event payload
      # The handler expects an event with "id" and optionally "time"
      event_payload = {
        id: id,
        time: timestamp.iso8601
      }

      puts "Recording program '#{id}' for date #{date_str} (using timestamp: #{timestamp})..."
      puts "Invoking Lambda function: #{function_name}"

      begin
        # Invoke Lambda function asynchronously
        response = lambda_client.invoke({
          function_name: function_name,
          invocation_type: "Event",  # Asynchronous invocation
          payload: JSON.generate(event_payload)
        })

        if response.status_code == 202
          puts "Recording task has been queued successfully!"
          puts "Lambda function invoked asynchronously."
          puts "Check CloudWatch logs for execution details."
        else
          puts "Failed to invoke Lambda function with status code: #{response.status_code}"
        end

      rescue Aws::Lambda::Errors::ServiceError => e
        puts "AWS Lambda error: #{e.message}"
        exit 1
      rescue => e
        puts "Error invoking Lambda: #{e.message}"
        exit 1
      end
    end
  end
end
