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
      original = "BeforeTheEmbed![title giphy__281_29.gif](//s3.amazonaws.com/uploads.groupbuzz.io/production/uploads/3473/original/c5e8a744fe873dcfb4d70a7770db52f50f9b2348.gif?1526503036 'giphy__281_29.gif')AfterTheEmbed"
      modified = markdown_processor.remove_images(original)
      expect(modified).to eq('BeforeTheEmbedAfterTheEmbed')
    end

    it "should remove all embedded image links not just uploads.groupbuzz.io" do
      original = "BeforeTheEmbed![giphy__281_29.gif](http://www.myimagehost.com/imagelink123 'giphy__281_29.gif')AfterTheEmbed"
      modified = markdown_processor.remove_images(original)
      expect(modified).to eq('BeforeTheEmbedAfterTheEmbed')
    end

    it "should remove embedded image but keep alt text if keep_image_alt_text enabled" do
      original = "BeforeTheEmbed![Image Alt Text Here](http://www.myimagehost.com/imagelink123 'giphy__281_29.gif')AfterTheEmbed"
      modified = markdown_processor(keep_image_alt_text: true).remove_images(original)
      expect(modified).to eq('BeforeTheEmbed[Image Alt Text Here]AfterTheEmbed')
    end

  end

  context "substitution" do

    it "should substitute image links" do
      image_alt_text = "Image Alt Text Here"
      original_text = "![#{image_alt_text}](http://www.myimagehost.com/imagelink123 'giphy__281_29.gif')"
      substitute_text(original_text, image_alt_text.length)
    end

    it "should substitute image links with space between content and the link and remove the spaces for the replacement" do
      image_alt_text = "Image Alt Text Here"
      content_part = "![#{image_alt_text}]"
      link_part = "(http://www.myimagehost.com/imagelink123 'giphy__281_29.gif')"
      original_text = "#{content_part}  #{link_part}"
      substitute_text(original_text, image_alt_text.length, 
        "#{content_part}#{link_part}")
    end

    it "should substitute links (sloppy)" do
    end

    def substitute_text(original_text, substitution_length, expected_retrieved_text = original_text)
      substitution_tracker = GroupBuzz::SubstitutionTracker.new
      modified_text = markdown_processor.substitute_markdown_enclosed_text(substitution_tracker, original_text)
      current_character_key = substitution_tracker.current_character_key
      expected_text = "#{current_character_key * substitution_length}"
      expect(expected_text).to eq(modified_text)
      expect(substitution_tracker.retrieve(current_character_key)).to eq(expected_retrieved_text)
    end

  end

  # TODO - typical message with italics, strong bold, bold, embedded images, links to verify single-pass retains what
  # should be retained and changes what should be changed

  def markdown_processor(keep_image_alt_text: keep_image_alt_text = false)
    @markdown_processor ||= GroupBuzz::MarkdownProcessor.new(keep_image_alt_text: keep_image_alt_text)
  end

end
