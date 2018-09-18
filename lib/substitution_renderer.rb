require 'facets'
require 'redcarpet'

# Based off of https://github.com/vmg/redcarpet/blob/master/lib/redcarpet/render_strip.rb
module GroupBuzz
  class SubstitutionRenderer < Redcarpet::Render::Base

    attr_accessor :substitution_tracker

    # Methods where the first argument is the text content
    [
      # block-level calls
      :block_code, :block_quote,
      :block_html, :list, :list_item,

      # span-level calls
      :autolink, :codespan, :double_emphasis,
      :emphasis, :underline, :raw_html,
      :triple_emphasis, :strikethrough,
      :superscript, :highlight, :quote,

      # footnotes
      :footnotes, :footnote_def, :footnote_ref,

      # low level rendering
      :entity, :normal_text
    ].each do |method|
      define_method method do |*args|
        args.first
      end
    end

    # Other methods where we don't return only a specific argument
    def link(link, title, content)
      substitute = @substitution_tracker.substitute("[#{content}](#{link})", content.length)
      substitute
    end

    def image(link, title, content)
      title_holder = title ?
        " '#{title}'" : ""
      @substitution_tracker.substitute("![#{content}](#{link}#{title_holder})", content.length)
    end

    def paragraph(text)
      text + "\r\n\r\n"
    end

  end
end