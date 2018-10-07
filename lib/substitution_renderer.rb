require 'facets'
require 'redcarpet'

# Based off of https://github.com/vmg/redcarpet/blob/master/lib/redcarpet/render_strip.rb
module GroupBuzz
  class SubstitutionRenderer < Redcarpet::Render::Base

    attr_accessor :substitution_tracker

    # Methods where the first argument is the text content
    # :underline, :link, :image removed from below
    [
      # block-level calls
      :block_code, :block_quote,
      :block_html, :list, :list_item,

      # span-level calls
      :autolink, :codespan, :double_emphasis,
      :emphasis, :raw_html,
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
      @substitution_tracker.substitute(
        :link, 
        GroupBuzz::MarkdownHelper.link(link, nil, content), 
        content, 
        content.length)
    end

    def image(link, title, content)
      title_holder = title ?
        " '#{title}'" : ""
      @substitution_tracker.substitute(
        :image, 
        GroupBuzz::MarkdownHelper.image(link, title_holder, content), 
        content, 
        content.length)
    end

    def paragraph(text)
      text + "\r\n\r\n"
    end

    def underline(text)
      @substitution_tracker.substitute(
        :underline, 
        GroupBuzz::MarkdownHelper.underline(text), 
        text, 
        text.length)
    end

    def emphasis(text)
      @substitution_tracker.substitute(
        :emphasis, 
        GroupBuzz::MarkdownHelper.emphasis(text), 
        text, 
        text.length)
    end

  end
end