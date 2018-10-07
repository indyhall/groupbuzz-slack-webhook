module DataHelper

  DEFAULT_MESSAGE_SUBJECT_PREFIX = '[indyhall]' 
  DEFAULT_SUBJECT = 'This is a subject'
  DEFAULT_SENDER_NAME = "\"Jane Doe\" via GroupBuzz"
  DEFAULT_EMAIL_BODY = 'This is the email body.'
  DEFAULT_STRIP_NEW_LINES = false
  DEFAULT_TRUNCATE_LENGTH = 239
  DEFAULT_TRUNCATE_LINES = 3

  def default_image
    image_content = "giphy_001.gif"
    image_link = "//s3.amazonaws.com/uploads.somesite.com/production/uploads/1234/original/dbd03b0e-11c5-4b81-82c5-e4c37b89b0ca.gif?123456788"
    image_title = "giphy-9.gif"
    image_in_markdown = "![#{image_content}](#{image_link} '#{image_title}')"
    return image_content, image_link, image_title, image_in_markdown
  end

  def default_link
    link_content = "This iS a link to click"
    link_href = "https://www.somesite.com/some/url/path?someparam=123"
    link_in_markdown = "[#{link_content}](#{link_href})"
    return link_content, link_href, link_in_markdown
  end

end