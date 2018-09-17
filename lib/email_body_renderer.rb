require 'redcarpet'
require 'redcarpet/render_strip'

# TODO - this base class may need to change to a base class that has more HTML methods stubbed out
# From the docs, nil return is 'stubbed out'
module GroupBuzz
  class EmailBodyRenderer < Redcarpet::Render::HTML

    def double_emphasis(text)
      enclose_with('*', text)
    end

    def emphasis(text)
      enclose_with('*', text)
    end

    def image(link, title, alt_text)
      ""
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