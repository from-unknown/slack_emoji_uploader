#!/usr/bin/env ruby

require 'mechanize'
require 'open-uri'
require 'json'
require 'mini_magick'
require 'find'
require 'fileutils'

# Class to upload emoji to slack team
class SlackEmoji
  # variables
  ConfigFile = 'emoji_conf.txt'
  DefaultFile = 'default_emoji.txt'
  EmojiFile = 'emoji.txt'
  LogFile = 'emoji_log.txt'
  ResizeName = "./resize.jpg"

  # messages to judge upload was success or fail
  LoginFail = "Sorry, you entered an incorrect email address or password"
  AddSuccess = "Your new emoji has been saved"
  DuplicateEmoji = 'There is already an emoji named'
  
  # variables from config file
  @@url = '' # Slack team URL to import emoji
  @@email = ''
  @@password = ''

  # delete temp image
  def initialize
    if File.exist?(ResizeName)
      File.delete(ResizeName)
    end
  end

  # Login to Slack team and upload all emoji by using Mechanize
  #
  # @return int -1 error
  #              0 success
  def uploadEmoji
    log_file = open(LogFile, 'wb')
    agent = Mechanize.new
    agent.user_agent = 'Windows Mozilla'
    agent.get(@@url) do |page|
      response = page.form_with(:action => '/') do |form|
        formdata = {
          :email => @@email, # login mail address
          :password => @@password # login @@password
        }
        form.field_with(:name => 'email').value = formdata[:email]
        form.field_with(:name => 'password').value = formdata[:password]
      end.submit

      # if login fails, write error to log file and exit
      if response.code != '200' || response.body.include?(LoginFail)
        log_file.write("Login failed! Please check Slack url, email and password.\n")
        return -1
      end
      log_file.write("Login success!\n")

      # upload emoji
      Find.find("./image/") do |image|
        next unless FileTest.file?(image) && (image =~ /\.jpg\Z/ || image =~ /\.jpeg\Z/ ||
                      image =~ /\.png\Z/ || image =~ /\.gif\Z/)
        resizeImage(image)
        upName = File.basename(image,File.extname(image))
        agent.get(@@url + 'customize/emoji') do |emoji|
          if File.exist?(image)
            eresponse = emoji.form_with(:action => '/customize/emoji') do |eform|
              eform.field_with(:name => 'name').value = upName
              eform.radiobuttons_with(:name => 'mode')[0].check
              eform.file_upload_with(:name => 'img').file_name = ResizeName
            end.submit
            # write result to log
            # check responce code and body to decide success or failer
            if eresponse.code != '200' # check response code
              log_file.write("F Name:[" + upName + "] Result: ")
              log_file.write("Respose code is not 200. Failed to add emoji.\n")
            elsif eresponse.body.include?(AddSuccess) # add success log
              log_file.write("S Name:[" + upName + "] Result: ")
              log_file.write("Successfully added.\n")
            elsif eresponse.body.include?(DuplicateEmoji) # add error log - duplicate error
              log_file.write("F Name:[" + upName + "] Result: ")
              log_file.write("Same emoji name already exist.\n")
            else # add error log - unknown error
              log_file.write("F Name:[" + upName + "] Result: ")
              log_file.write("Unknown error occured.\n")
            end
          else # add error log - file not found
            log_file.write("F Name:[" + upName + "] Result: ")
            log_file.write("File not exist.\n")
          end
        end
      end
    end
  end

  # Read config file
  def readConfigFile
    config = Array.new
    File.open(ConfigFile, 'r') do |file|
      file.each_line do |line|
        stripLine = line.strip
        if stripLine !~ /^#/ && !stripLine.empty?
          config.push(line.strip)
        end
      end
    end
    @@url = config[0]
    @@email = config[1]
    @@password = config[2]
  end

  # resize image - To upload image file, size must be 128 x 128 or less
  def resizeImage(imageName)
    image = MiniMagick::Image.open(imageName)
    height = image.height
    width = image.width

    if height > width
      ratio = 128.0 / height
      reHeight = (height * ratio).floor
      reWidth = (width * ratio).floor
    else
      ratio = 128.0 / width
      reHeight = (height * ratio).floor
      reWidth = (width * ratio).floor
    end

    image.resize("#{reHeight} x #{reWidth}")
    image.write("resize.jpg")
  end

  # check image files exist
  def checkImageExists
    Find.find("./image/") do |image|
      next unless FileTest.file?(image) && (image =~ /\.jpg\Z/ || image =~ /\.jpeg\Z/ ||
                    image =~ /\.png\Z/ || image =~ /\.gif\Z/)
      return true
    end
    return false
  end

  # backup image files after upload
  def backupImage
    Find.find("./image/") do |image|
      next unless FileTest.file?(image) && (image =~ /\.jpg\Z/ || image =~ /\.jpeg\Z/ ||
                    image =~ /\.png\Z/ || image =~ /\.gif\Z/)
      FileUtils.mv(image, "./bkimage")
    end
  end
end

# create object
emoji = SlackEmoji.new

# check if file exists
if emoji.checkImageExists == true
  emoji.readConfigFile
  emoji.uploadEmoji
  emoji.backupImage
end
