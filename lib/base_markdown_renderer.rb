require 'redcarpet'

module GroupBuzz
  class BaseMarkdownRenderer < Redcarpet::Render::Base

    # Define most methods to return nil by default
    # Exclusions: single_emphasis, double_emphasis
    # From https://github.com/vmg/redcarpet/blob/master/lib/redcarpet/render_strip.rb 
    [
      # block-level calls
      :block_code, :block_quote,
      :block_html, :list, :list_item,

      # span-level calls
      :autolink, :codespan,
      :raw_html,
      :triple_emphasis, :strikethrough,
      :superscript, :highlight, :quote,

      # footnotes
      :footnotes, :footnote_def, :footnote_ref,
    ].each do |method|
      define_method method do |*args|
        nil
      end
    end

  end
end