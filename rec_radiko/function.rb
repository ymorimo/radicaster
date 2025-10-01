$LOAD_PATH.unshift(File.dirname(__FILE__) + "/lib")

require "logger"
require "rec-radiko"
require "aws-sdk-s3"

logger = Logger.new(STDOUT)

radigo_home = "/tmp"
radiko_mail = ENV["RADICASTER_RADIKO_MAIL"]
radiko_password = ENV["RADICASTER_RADIKO_PASSWORD"]
radiko = Radicaster::RecRadiko::Radigo.new(radigo_home, radiko_mail, radiko_password, logger)
concater = Radicaster::RecRadiko::Ffmpeg.new(logger)
recorder = Radicaster::RecRadiko::Recorder.new(radiko, concater, logger)

bucket = ENV["RADICASTER_S3_BUCKET"] or raise "ENV['RADICASTER_S3_BUCKET'] must be set"
s3 = Aws::S3::Client.new
storage = Radicaster::RecRadiko::S3.new(s3, bucket)

Handler = Radicaster::RecRadiko::Handler.new(logger, recorder, storage)
