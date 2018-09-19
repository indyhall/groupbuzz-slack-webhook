require_relative 'base_markdown_renderer'

module GroupBuzz
  class EmailBodyRenderer < GroupBuzz::BaseMarkdownRenderer

    def initialize(keep_image_alt_text: keep_image_alt_text)
      super()
      @keep_image_alt_text = keep_image_alt_text
    end

    def double_emphasis(text)
      enclose_with('*', text)
    end

    def emphasis(text)
      enclose_with('*', text)
    end

    def image(link, title, alt_text)
      return @keep_image_alt_text ? 
        "[#{alt_text}]" : ""
    end

    def paragraph(text)
      text
    end

    # :underline: option must be passed to Redcarpet::Markdown initialization
    def underline(text)
      enclose_with('_', text)
    end

    private

    def enclose_with(character, text)
      "#{character}#{text}#{character}"
    end

  end
end