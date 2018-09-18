require 'redcarpet'

module GroupBuzz
  class MarkdownProcessor
  
    def initialize(keep_image_alt_text: keep_image_alt_text = false)
      @keep_image_alt_text = keep_image_alt_text
    end

    # GB uses Markdown's strong emphasis of double asterisks. Text like **text** does not render as bold in 
    # Slack until it is converted to single asterisks.
    # Render demo: https://api.slack.com/docs/messages/builder?msg=%7B%22text%22%3A%22This%20is%20**strong%20bold%20formatted**%22%2C%22username%22%3A%22markdownbot%22%7D
    def format_double_bold(text)
      redcarpet_markdown.render(text)
    end

    def remove_images(text)
      redcarpet_markdown.render(text)
    end

    def substitute_markdown_enclosed_text(substitution_tracker, text)
      substitution_renderer = GroupBuzz::SubstitutionRenderer.new
      substitution_renderer.substitution_tracker = substitution_tracker
      redcarpet_markdown(substitution_renderer).render(text).lstrip.rstrip
    end
    
    private

    def redcarpet_markdown(renderer = email_body_renderer)
      Redcarpet::Markdown.new(renderer, underline: true)
    end

    def email_body_renderer
      @email_body_renderer ||= GroupBuzz::EmailBodyRenderer.new(keep_image_alt_text: @keep_image_alt_text)
    end

  end
end