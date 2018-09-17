require 'spec_helper'

describe GroupBuzz::MarkdownProcessor do

  context "formatting" do

    it "should convert Markdown strong emphasis (double asterisks) to single asterisks for Slack" do
      original = 'This is **strong bold formatted** This is a lone asterisk * just, _italics_ another one couple * * out there *bold*'      
      expected = 'This is *strong bold formatted* This is a lone asterisk * just, _italics_ another one couple * * out there *bold*'
      formatted = markdown_processor.format_double_bold(original)
      expect(formatted).to eq(expected)
    end

  end

  def markdown_processor
    @markdown_processor ||= GroupBuzz::MarkdownProcessor.new()
  end

end
