ENV["SSL_CERT_FILE"] = "./cacert.pem"

require 'mechanize'
require 'open-uri'
require 'json'
require 'mini_magick'

class SlackEmoji
  # variables
  ConfigFile = 'emoji_conf.txt'
  DefaultFile = 'default_emoji.txt'
  EmojiFile = 'emoji.txt'
  LogFile = 'emoji_log.txt'
  LoginFail = "Sorry, you entered an incorrect email address or password"
  AddSuccess = "Your new emoji has been saved"
  DuplicateEmoji = 'There is already an emoji named'
  ApiUrl = 'https://slack.com/api/emoji.list?pretty=1&token=' # Slack emoji list API
  @@url = '' # Slack team URL to import emoji
  @@email = ''
  @@password = ''

  def initialize
    if File.exist?('./temp.jpg')
      File.delete("temp.jpg")
    end
  end

  def uploadEmoji(orgName)
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

      if response.code != '200' || response.body.include?(LoginFail)
        log_file.write("Login failed! Please check Slack url, email and password.\n")
        return -1
      end
      log_file.write("Login success!\n")

      name = "temp.jpg"
      upName = File.basename(orgName,File.extname(orgName))
      agent.get(@@url + 'customize/emoji') do |emoji|
        if File.exist?(orgName)
          eresponse = emoji.form_with(:action => '/customize/emoji') do |eform|
            eform.field_with(:name => 'name').value = upName
            eform.radiobuttons_with(:name => 'mode')[0].check
            eform.file_upload_with(:name => 'img').file_name = name
          end.submit
          if eresponse.code != '200'
            log_file.write("F Name:[" + upName + "] FileName:[" + name + "] Result: ")
            log_file.write("Respose code is not 200. Failed to add emoji.\n")
          elsif eresponse.body.include?(AddSuccess)
            log_file.write("S Name:[" + upName + "] FileName:[" + name + "] Result: ")
            log_file.write("Successfully added.\n")
          elsif eresponse.body.include?(DuplicateEmoji)
            log_file.write("F Name:[" + upName + "] FileName:[" + name + "] Result: ")
            log_file.write("Same emoji name already exist.\n")
          else
            log_file.write("F Name:[" + upName + "] FileName:[" + name + "] Result: ")
            log_file.write("Unknown error occured.\n")
          end
        else
          log_file.write("F Name:[" + upName + "] FileName:[" + name + "] Result: ")
          log_file.write("File not exist.\n")
        end
      end
    end
  end

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
    image.write("temp.jpg")
  end      
end

emoji = SlackEmoji.new

emoji.readConfigFile

emoji.resizeImage(ARGV[0])
emoji.uploadEmoji(ARGV[0])

