# slack_emoji_uploader
Move your Slack team emoji to other Slack team.

##What is this script for?
Move emoji from Slack team to other Slack team.

##What do I need to use this script?
*Environment:*  
 +Ruby 2.2.2 or Above (tested by 2.2.2, so may work other version)  
 +Ruby Gem: Mechanize  
 +Ruby Gem: json  
 +Ruby Gem: Mini_magick  
 +Image Magick  

##How to use this script?
*For windows*  
1. move all files to working folder
2. write all infomation to config file
3. write path to ruby in upload_emoji.bat file
4. drag&drop image file to upload_emoji.bat and emoji data are uploaded
5. done!
  
You can make bat file's shortcut to anywhere convenient to you.

*For mac*
1. move all files to working folder
2. write all infomation to config file
3. write path to this folder into slakcemojiuploader.plist 
4. move slackemojiuploader.plist to ~/Library/LaunchAgents
5. open terminal and copy&paste  
launchctl load ~/Library/LaunchAgents/slakcemojiuploader.plist
6. put image file to image folder and upload starts every 10 sec
7. done!


