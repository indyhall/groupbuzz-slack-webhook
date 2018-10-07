module GroupBuzz
  class SubstitutionTracker
  
    STARTING_CHARACTER_INDEX = 192

    attr_accessor :substitution_characters

    def initialize
      @substitutions_by_character = {}
      @character_index = STARTING_CHARACTER_INDEX
      @substitution_characters = []
    end

    def substituted_character_index(character)
      @substitution_characters.index(character)
    end

    def retrieve(character, key = :original_text)
      @substitutions_by_character[character][key]
    end

    def store(character, markdown_type, original_text, non_hidden_text)
      @substitutions_by_character[character] = 
        {
          markdown_type: markdown_type, original_text: original_text, non_hidden_text: non_hidden_text
        }
      return character
    end

    def substitute(markdown_type, original_text, non_hidden_text, substitute_length)
      key = new_character_key
      store(key, markdown_type, original_text, non_hidden_text)
      key * substitute_length
    end

    def current_character_key
      @character_index.chr(Encoding::UTF_8)
    end

    private

    def new_character_key
      @character_index += 1
      key = current_character_key
      substitution_characters << key
      key
    end

  end
end