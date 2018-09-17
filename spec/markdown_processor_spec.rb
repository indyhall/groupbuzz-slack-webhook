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

  context "removal" do

    it "should remove all embedded uploads.groupbuzz.io image links" do
      original = "BeforeTheEmbed![giphy__281_29.gif](//s3.amazonaws.com/uploads.groupbuzz.io/production/uploads/3473/original/c5e8a744fe873dcfb4d70a7770db52f50f9b2348.gif?1526503036 'giphy__281_29.gif')AfterTheEmbed"
      modified = markdown_processor.remove_images(original)
      expect(modified).to eq('BeforeTheEmbedAfterTheEmbed')
    end

    it "should remove all embedded image links not just uploads.groupbuzz.io" do
      original = "BeforeTheEmbed![giphy__281_29.gif](http://www.myimagehost.com/imagelink123 'giphy__281_29.gif')AfterTheEmbed"
      modified = markdown_processor.remove_images(original)
      expect(modified).to eq('BeforeTheEmbedAfterTheEmbed')
    end

  end

  # TODO - typical message with italics, strong bold, bold, embedded images, links to verify single-pass retains what
  # should be retained and changes what should be changed

  def markdown_processor
    @markdown_processor ||= GroupBuzz::MarkdownProcessor.new()
  end

end
