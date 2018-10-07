require 'spec_helper'
require_relative 'support/data_helper'

describe GroupBuzz::TruncationProcessor do

  RSpec.configure do |c|
    c.include DataHelper
  end

  context "truncation tests on hidden markdown" do

    it "should truncate part of the link label" do
      link_content, link_href, link_in_markdown = default_link
      original_text = "This is an sentence. This is another sentence. #{link_in_markdown}"
      substitution_tracker, substituted_text = substitution_process(original_text)
      truncated = truncation_processor(substitution_tracker, 50).truncate(substituted_text)
    end

  end

  def truncation_processor(substitution_tracker, truncation_limit)
    GroupBuzz::TruncationProcessor.new(substitution_tracker, truncation_limit)
  end

  def substitution_process(original_text)
    substitution_tracker = GroupBuzz::SubstitutionTracker.new
    substituted_text = GroupBuzz::MarkdownProcessor.new.substitute_markdown_enclosed_text(substitution_tracker, original_text)
    return substitution_tracker, substituted_text
  end

end
