module GroupBuzz
  class SubstitutionTracker
  
    STARTING_CHARACTER_INDEX = 192

    attr_accessor :substitution_characters

    def initialize
      @substitutions_by_character = {}
      @character_index = STARTING_CHARACTER_INDEX
      @substitution_characters = []
    end

    def retrieve(character)
      @substitutions_by_character[character]
    end

    def store(character, original_text)
      @substitutions_by_character[character] = original_text
      return character
    end

    def substitute(original_text, substitute_length)
      key = new_character_key
      store(key, original_text)
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