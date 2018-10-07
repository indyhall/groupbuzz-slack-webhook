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
      substitute_text(:image, original_text, image_alt_text.length, image_alt_text)
    end

    it "should substitute image links with space between content and the link and remove the spaces for the replacement" do
      image_alt_text = "Image Alt Text Here"
      content_part = "![#{image_alt_text}]"
      link_part = "(http://www.myimagehost.com/imagelink123 'giphy__281_29.gif')"
      original_text = "#{content_part}  #{link_part}"
      substitute_text(:image, original_text, image_alt_text.length, image_alt_text,
        "#{content_part}#{link_part}")
    end

    it "should substitute links with newlines embedded before end of markdown link part" do
      label = "something happening at somewhere on a date"
      content_part = "[#{label}]"
      link = "https://www.aneventsite.com/e/someeventurlhere/some-uuid-tracker?someparam=somevalue"
      link_part = "#{link}\r\n"
      original_text = "#{content_part}(#{link_part})"
      substitute_text(:link, original_text, label.length, label, "#{content_part}(#{link})")
    end

    it "should substitute links with whitespace embedded before end of markdown link part" do
      label = "something happening at somewhere on a date"
      content_part = "[#{label}]"
      link = "https://www.aneventsite.com/e/someeventurlhere/some-uuid-tracker?someparam=somevalue"
      link_part = "#{link}  "
      original_text = "#{content_part}(#{link_part})"
      substitute_text(:link, original_text, label.length, label, "#{content_part}(#{link})")
    end

    it "should substitute italic links" do
      original_text = "_italicized_"
      substitute_text(:underline, original_text, original_text.length - 2, slice_end_characters(original_text),  original_text)
    end

    it "should substitute bold (single asterisk after double asterisk change) links" do
      original_text = "*bolded*"
      substitute_text(:emphasis, original_text, original_text.length - 2, slice_end_characters(original_text), original_text)
    end

    it "should not currently handle double asterisk bold markup as it should be handled in prior processing step and return empty text by default" do
      original_text = "**double bolded**"
      substitute_text(:double_emphasis, original_text, 0, "", "")
    end

    it "should substitute a simple combination" do
      first_part = "_firstitalic_"
      second_part = "_seconditalic_"
      original_text = "#{first_part} and then #{second_part}"
      original_text_parts = [
        original_text_part(:underline, first_part, 2, slice_end_characters(first_part)),
        original_text_part(:underline, second_part, 2, slice_end_characters(second_part))
      ]
      substitute_texts(original_text, original_text_parts)
    end

    it "should substitute a more complex combination" do
      italic_part = "_italic part_"
      image_content = "giphy_281_29.gif"
      link_content = "link to tickets"
      image_part = "![#{image_content}](//s3.amazonaws.com/uploads.groupbuzz.io/production/uploads/3473/original/somelongid.gif?someidentifier 'giphy_3_45.gif')"
      link_part = "[#{link_content}](https://2018.someconference.org/tickets)"
      original_text = "Are you #{italic_part}? Feeling like this? #{image_part}\r\n\r\nYou can get your tickets here: #{link_part}\r\n\r\n"
      original_text_parts = [
        original_text_part(:underline, italic_part, italic_part.length - 2, slice_end_characters(italic_part)),
        original_text_part(:image, image_content, image_content.length, image_content, image_part),
        original_text_part(:link, link_part, link_content.length, link_content)
      ]
      substitute_texts(original_text, original_text_parts)
    end

    it "should substitute an email body based on an actual GB email with malformed markdown" do
      link_content = "this"
      link_href = "https://www.somesite.com?t=1234567890"
      link_content_2 = "Some Organization's Time-based party on Weekday the XXth"
      link_href_2 = "https://www.myticketingsite.com/e/path-to-event-uuid-1234567890?ref=sometrackingref"
      bold_content_1 = "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.!"
      bold_content_2 = "lorem ipsum"
      bold_content_3 = "Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur"
      # note images should be stripped out already but keeping them here
      image_content, image_link, image_title, image_in_markdown = default_image
      
      email_body = "\r\n\r\nLorem ipsum,\r\n\r\ndolor sit amet, consectetur adipiscing elit, [#{link_content}] (#{link_href}) sed do [#{link_content_2}](#{link_href_2}\r\n)  \r\n\r\nSed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium *#{bold_content_1}*\r\n\r\ntotam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo *#{bold_content_2}* Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit \r\n\r\n*#{bold_content_3}* Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur\r\n\r\n\r\n\r\n![#{image_content}](#{image_link} '#{image_title}')\r\n\r\n\r\n"

      original_text_parts = [
        original_text_part(:link, link_content, link_content.length, link_content, "[#{link_content}](#{link_href})"),
        original_text_part(:link, link_content_2, link_content_2.length, link_content_2, "[#{link_content_2}](#{link_href_2})"),
        original_text_part(:emphasis, bold_content_1, bold_content_1.length, bold_content_1, "*#{bold_content_1}*"),
        original_text_part(:emphasis, bold_content_2, bold_content_2.length, bold_content_2, "*#{bold_content_2}*"),
        original_text_part(:emphasis, bold_content_3, bold_content_3.length, bold_content_3, "*#{bold_content_3}*"),
        original_text_part(:image, image_content, image_content.length, image_content, image_in_markdown)
      ]
      substitute_texts(email_body, original_text_parts)
    end

    it "should substitute an email body based on an actual GB email with an instagram link as the link content" do
      # note images should be stripped out already but keeping them here
      image_content, image_link, image_title, image_in_markdown = default_image      
      link_content = "@some_usersname"
      link_href = "https://www.instagram.com/some_usersname/"
      italic_content = "sapiente delectus"
      email_body = "\r\n\r\nLorem ipsum,!\r\n\r\ndolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. \r\n\r\n![#{image_content}](#{image_link} '#{image_title}')\r\n(quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat., [#{link_content}](#{link_href}))\r\n\r\nAt vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti _#{italic_content}_ Et harum quidem rerum facilis est et expedita distinctio.\r\n\r\nNam libero tempore, cum soluta nobis est eligendi \r\n\r\nTemporibus autem quibusdam et aut officiis debitis aut rerum!\r\n\r\nLorem,\r\nIpsum\r\n\r\n"
      original_text_parts = [
        original_text_part(:image, image_content, image_content.length, image_content, image_in_markdown),
        original_text_part(:link, link_content, link_content.length, link_content, "[#{link_content}](#{link_href})"),
        original_text_part(:underline, italic_content, italic_content.length, italic_content, "_#{italic_content}_")
      ]
      substitute_texts(email_body, original_text_parts)
    end

    def original_text_part(markdown_type, original_text, expected_length, non_hidden_text, retrieved_text = original_text)
      {
        markdown_type: markdown_type,
        text: original_text,
        length: expected_length,
        non_hidden_text: non_hidden_text,
        retrieved_text: retrieved_text
      }
    end

    def substitute_text(markdown_type, original_text, substitution_length, non_hidden_text, expected_retrieved_text = original_text)
      substitute_texts(original_text,
        [original_text_part(markdown_type, original_text, substitution_length, non_hidden_text, expected_retrieved_text)])
    end

    def substitute_texts(complete_original_text, original_text_parts)
      substitution_tracker = GroupBuzz::SubstitutionTracker.new
      modified_text = markdown_processor.substitute_markdown_enclosed_text(substitution_tracker, complete_original_text)
      substitution_characters = substitution_tracker.substitution_characters

      original_text_parts.each_with_index do |text_part, index|
        next if text_part[:length] == 0
        current_character_key = substitution_characters[index]

        expect(substitution_tracker.substituted_character_index(current_character_key)).to eq(index)

        expect(substitution_tracker.retrieve(current_character_key, :markdown_type)).to eq(text_part[:markdown_type])

        substituted_text = "#{current_character_key * text_part[:length]}"
        expect(modified_text.include? substituted_text).to be true

        retrieved_text = substitution_tracker.retrieve(current_character_key)
        expect(retrieved_text).to eq(text_part[:retrieved_text])

        non_hidden_text = substitution_tracker.retrieve(current_character_key, :non_hidden_text)
        expect(non_hidden_text).to eq(text_part[:non_hidden_text])
      end      
    end

    def slice_end_characters(text)
      text[1, text.length - 2]
    end

  end

  def markdown_processor(keep_image_alt_text: keep_image_alt_text = false)
    @markdown_processor ||= GroupBuzz::MarkdownProcessor.new(keep_image_alt_text: keep_image_alt_text)
  end

end
