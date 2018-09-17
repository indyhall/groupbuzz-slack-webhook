require 'redcarpet'

# TODO - have single method to process Markdown if can do in single pass
# TODO - make this abstract base class if cannot do in single pass
module GroupBuzz
  class MarkdownProcessor
  
    # GB uses Markdown's strong emphasis of double asterisks. Text like **text** does not render as bold in 
    # Slack until it is converted to single asterisks.
    # Render demo: https://api.slack.com/docs/messages/builder?msg=%7B%22text%22%3A%22This%20is%20**strong%20bold%20formatted**%22%2C%22username%22%3A%22markdownbot%22%7D
    def format_double_bold(text)
      redcarpet_markdown.render(text)
    end

    def remove_images(text)
      redcarpet_markdown.render(text)
    end
    
    private

    def redcarpet_markdown(renderer = email_body_renderer)
      Redcarpet::Markdown.new(renderer, underline: true)
    end

    def email_body_renderer
      @email_body_renderer ||= GroupBuzz::EmailBodyRenderer.new
    end

  end
end