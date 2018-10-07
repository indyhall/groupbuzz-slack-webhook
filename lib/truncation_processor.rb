module GroupBuzz
  class TruncationProcessor

    def initialize(substitution_tracker, truncate_limit)
      @substitution_tracker = substitution_tracker
      @truncate_limit = truncate_limit
    end

    def truncate(text)
      character_at_limit = character_at(text, @truncate_limit)

      if !@substitution_tracker.substituted_character_index(character_at_limit).nil?
        return truncate_in_substitution(text.clone, character_at_limit)
      elsif is_character_whitespace?(character)
      else
      end
    end
  
    def truncate_in_substitution(complete_text, character_at_limit)
      complete_text_copy = complete_text.clone

      # substitute back the non_hidden_text for the character in question, starting at the first index of the character
      non_hidden_text = @substitution_tracker.retrieve(character_at_limit, :non_hidden_text)
       
      complete_text.sub! character_at_limit * non_hidden_text.length, non_hidden_text

      substituted_character_at_limit = character_at(complete_text, @truncate_limit)

      # check if substituted character at limit is whitespace
      next_character = character_at(complete_text, @truncate_limit + 1)

      is_whitespace = is_character_whitespace?(next_character)

      if is_whitespace
        # get substring that is not cut off
        # recreate previous substitutions before this one
        # recreate this substitution with a truncated link
      end
#      return complete_text[0, @truncate_limit + 1] if is_whitespace
    end

    private

    def character_at(text, index)
      # TODO handle out of bounds
      text[index,1]
    end

    # check for apostrophe, other punctuation?
    # don't break on punctuation?

    def is_character_whitespace?(character)
      !character.match(/\s/).nil?
    end

  end
end