## groupbuzzslackrelay

This project is a way to relay messages from Groupbuzz to Slack. Currently, Groupbuzz messages are relayed to Slack via the [Zapier](https://zapier.com/) automation platform. The templating capabilities that Zapier provides are limited.

### Proof-of-concept

The proof of concept will provide an HTTP endpoint which will consume messages from Groupbuzz in the JSON format that is currently sent to Zapier. It will be configured with a Slack API key that will post the messages to a test Slack (https://creativetimemgmt.slack.com/).

### JSON post format

```{"sender_name": "\"Sam Abrams\" via GroupBuzz", "email_body": "Please REPLY ABOVE THIS LINE to respond by email.\r\n\r\nWondering how to get your face on the tv screens around Indy Hall? Or do you see your pic and think \"oh jeez, that's so old!\"\r\n\r\nI'm here to help!\r\n\r\n**All next week** I'll have my camera around Indy Hall, ready to snap your member photo! It'll be quick, easy, and (believe it or not) you might have fun! I'll be inviting folks who don't have pics yet to get one, but if you would like a new photo, don't hesitate to ask- I'm happy to update yours!\r\n\r\nPluuuus if you like I'll send you your photo to use for linkedin, facebook, whatever (just credit me at [Sam Abrams Photography](https://www.samabramsphotography.com/) ;) )\r\n\r\nI'll see you next week- come see me whenever you're feeling photogenic!\r\n\r\n\r\n![giphy__281_29.gif](//s3.amazonaws.com/uploads.groupbuzz.io/production/uploads/3473/original/c5e8a744fe873dcfb4d70a7770db52f50f9b2348.gif?1526503036 'giphy__281_29.gif')\r\n\r\n\r\nFollow this topic if you would like to be notified of new posts in this discussion: http://indyhall.groupbuzz.io/topics/16997-next-week-is-member-photo-week/subscribe", "subject": "[indyhall] Next week is Member photo... WEEK?!"}```
    
In the example JSON post above, it appears that the text is formatted via Markdown. 

### Implementation

Since Slack already understands Markdown, this could be a very simple app that simply takes the input JSON and truncates it to a configurable length, removing new line (\n, \r) markers if needed. It might be made a little more fancy with formatting.

### Slack documentation/tools

[Interactive message previewer](https://api.slack.com/docs/messages/builder?msg=%7B%22text%22%3A%22Hello%2C%20world%22%7D)

[An introduction to messages](https://api.slack.com/docs/messages)

[Basic message formatting](https://api.slack.com/docs/message-formatting)

[Attaching content and links to messages](https://api.slack.com/docs/message-attachments)

[Real Time Messaging API
](https://api.slack.com/rtm) (WebSocket) - probably overkill

### Deployment

The proof-of-concept will be deployed to Heroku's free tier. Since Heroku's free-tier [no longer](https://medium.com/@bantic/free-tls-with-letsencrypt-and-heroku-in-5-minutes-807361cca5d3) allows apps to use [Let's Encrypt's](https://letsencrypt.org/) free SSL certificates, deploying this with SSL will require deployment to a Heroku account at the [Hobby](https://www.heroku.com/pricing) level (or above) or another Cloud provider/host.

### Language choice

Ruby was chosen, since I am most familiar with Ruby and it has [RSpec](http://rspec.info/). Trying to write this in Node.js, Serverless, etc. would delay the proof-of-concept because I am not at all comfortable or familiar with those.

