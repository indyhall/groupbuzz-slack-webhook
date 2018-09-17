## groupbuzz-slack-webhook

This project is a way to relay messages from GroupBuzz to Slack. Currently, GroupBuzz messages are relayed to Slack via the [Zapier](https://zapier.com/) automation platform. The [formatting](https://zapier.com/help/formatter/) capabilities that Zapier provides are limited when it comes to templating.

### Project description

This project provides an HTTP endpoint which will consume messages from GroupBuzz in the JSON format that is currently sent by Zapier and post them to Slack in an abbreviated "preview" type format. 

### JSON post format

See the spec/examples directory for multiple examples of individual and digest message posts.
    
### Message Processing Requirements

Originally, before the project started, since Slack already understands Markdown, it was thought that this could be a very simple app that simply takes the input JSON and truncates it to a configurable length, removing new line (\n, \r) markers if needed. 

During the implementation of the first version, a long list of processing tasks to be done before the message is posted to Slack in the categories of *removal*, *formatting*, or *extraction* was discovered. Most of these were addressed in the first version. Some of the processing tasks in different categories are done simultaneously.

##### Removal

1. From the subject, remove the prefix of "[indyhall]".
2. From the email\_body, remove the header of "Please REPLY ABOVE THIS LINE to respond by email."
3. From the email\_body, remove any line breaks before the first line of the message.
4. From the email\_body, remove any embedded image links of this form:
```![giphy__281_29.gif](//... 'giphy__281_29.gif')```. Usually, the URL host contains `uploads.groupbuzz.io` but that might not be able to be assumed always. All images links should be removed from the preview because we can control neither the height or width of the embedded image without resizing it.
5. From the email\_body, remove the footer in the email body text of "Follow this topic if you would like to be notified of new posts in this discussion:"
6. From the email\_body, remove any line breaks after the last line of the message that was before the footer.

##### Extraction

1. From the email\_body, extract the topic link from the link following the footer by removing the '/subscribe' part of the URL.
2. From the sender\_name, extract the name by removing the quotes and the "via GroupBuzz" suffix. If the sender\_name happens to not be formatted that way, just pass it through.

##### Formatting

1. Change all Markdown links to Slack's [linking to URLs](https://api.slack.com/docs/message-formatting#linking_to_urls) format.
2. Change all GB marked up bold `**text**` to single asterisk Markdown [bold](https://get.slack.help/hc/en-us/articles/202288908-how-can-i-add-formatting-to-my-messages-) `*text*`.
3. Change &, <, > to Slack's [escaped characters](https://api.slack.com/docs/message-formatting#how_to_escape_characters) equivalents. TBD - This may or may not apply to URLs in links.

#### Truncation

1. Truncate on a character limit.
2. Truncate on the first n lines of text, as identified by line breaks.

### Implementation

#### Version 1

The first version used a single `GroupBuzz::SlackMessagePreparer` class that used a combination of normal String manipulation along with a set of regular expressions borrowed and adapted from various, cited sources to perform most of the required processing tasks, including attempting to not truncate 'in the middle' of a word. It wasn't the best implementation. However, it was good for a first pass and unit tested.

During development and testing, a third rule emerged to complement the first rule of truncation: "The character limit should only include visible characters and not include characters incurred by Markdown formatting or metadata like a link URL or line break/tab characters." For example, ```[my site](http://www.mysite.com)``` has a visible character length of `my site` or 7 characters, not the 32! when all markdown and the URL is included.

The first version was not able to adhere to the 3rd rule due to the increasing complexity of the regular expressions.

In addition, an email message received during live testing had sloppy Markdown formatting. 

1. ```[link] (https://www.mysite.com/```. A Markdown link with whitespace between the link label and the link URL: 
 

2. ```[another link](https://www.mysite.com/...\r\n)```. A Markdown link with a ```\r\n``` sequence *inside* the link.   

#### Version 2

As a result of the parsing and formatting bugs, a decision has most likely already been made to completely scrap most of the regular expressions used for processing the message, in favor of using a real Markdown parser/formatter library called [redcarpet](https://github.com/vmg/redcarpet). A quick test showed that `redcarpet` successfully parsed and cleaned the two sloppy Markdown formatting examples automatically without issues.

The implementation will follow a pipeline-style design.

1. Process sender\_name to get the real sender name.
2. Process subject to get the subject without the GB prefix.
3. From the email\_body, remove the GB header and footer, storing the extracted topic link for later use.
4. Parse the modified email\_body of step 3 with the `redcarpet` Markdown parser. Use a formatter subclass to remove all embedded images and output an email\_body (body\_for\_processing) without the header, footer, and any embedded images.
5. From body\_for\_processing, use a formatter subclass to render all link labels to be uniquely identifiable by repeating sequences of a single unicode character (unicode aliases) and remove the link and link formatting. Call it special\_body. See below for explainer. 
6. From special\_body, test to truncate by allowed line breaks. If the character count before the final allowed line break is less than the maximum characters allowed, return all the text prior to that line break as the body content, after replacing all of the unicode-aliased link label(s) back to the original Markdown link(s).
7. From special\_body, test to truncate by maximum character count. If the character at the end is a non-whitespace character, backtrack until whitespace is encountered and then the end of another word (a word or link label). Replace all the unicode-aliased link labels back the original Markdown link(s).
8. Format the links in the message to be Slack's format.
9. Format the &, <, > escaped characters to be Slack's format.
10. Collect the subject, sender name, and body and post a message to Slack's incoming webhook.

##### Step 5 explainer

This formatter will change the label for a link to a repeated sequence of a unicode character that is unique for that particular label and also unique in the entire email\_body. To do this, we can increment an index to get a different unicode. During the formatting, 

For example, embedded links like ```[link one](http://www.mysite.com) blah blah blah. This is [link two if you need it](http://www.mysite2.com).```  will be rendered to ```ÀÀÀÀÀÀÀÀ blah blah blah. This is ÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁÁ.``` The idea is that if the ```Á``` character is found at the index of the character truncation limit (minus 1), then we know it is is the second ```[link two if you need it]``` label. 

### Language choice

Ruby was chosen, since I am most familiar with Ruby and it has [RSpec](http://rspec.info/). Trying to write this in Node.js, Serverless, etc. would delay the proof-of-concept because I am not at all comfortable or familiar with those.

### Resources - Slack documentation/tools

[Interactive message previewer](https://api.slack.com/docs/messages/builder?msg=%7B%22text%22%3A%22Hello%2C%20world%22%7D)

[An introduction to messages](https://api.slack.com/docs/messages)

[Basic message formatting](https://api.slack.com/docs/message-formatting)

[Attaching content and links to messages](https://api.slack.com/docs/message-attachments)

[Real Time Messaging API
](https://api.slack.com/rtm) (WebSocket) - probably overkill

### Deployment

Please see DEPLOYMENT.md


