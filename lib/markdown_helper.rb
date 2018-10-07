module GroupBuzz
  class MarkdownHelper

    def self.link(link, title, content)
      "[#{content}](#{link})"
    end

    def self.image(link, title, content)
      "![#{content}](#{link}#{title})"
    end

    def self.underline(text)
      "_#{text}_"
    end

    def self.emphasis(text)
      "*#{text}*"
    end

  end
end