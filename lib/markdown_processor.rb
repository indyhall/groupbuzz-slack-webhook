require 'redcarpet'

# TODO - have single method to process Markdown if can do in single pass
# TODO - make this abstract base class if cannot do in single pass
module GroupBuzz
  class MarkdownProcessor
  
    # GB uses Markdown's strong emphasis of double asterisks. Text like **text** does not render as bold in 
    # Slack until it is converted to single asterisks.
    # Render demo: https://api.slack.com/docs/messages/builder?msg=%7B%22text%22%3A%22This%20is%20**strong%20bold%20formatted**%22%2C%22username%22%3A%22markdownbot%22%7D
    def format_double_bold(text)
      redcarpet_markdown(GroupBuzz::ConvertDoubleAsterisksRenderer.new).render(text)
    end
    
    private

    def redcarpet_markdown(renderer = html_renderer)
      Redcarpet::Markdown.new(renderer, underline: true)
    end

    def html_renderer
      @render_html ||= Redcarpet::Render::HTML.new(render_options = {})
    end

  end
end