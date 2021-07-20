module Refinements
  refine String do
    def whitespace?
      self == ' ' || self == '.' || self == ','
    end

    def punctuation?
      self == '.' ||
        self == ',' ||
        self == '"' ||
        self == '$' ||
        self == '%' ||
        self == '^' ||
        self == '*' ||
        self == '(' ||
        self == ')' ||
        self == '?' ||
        self == ':' ||
        self == ';' ||
        self == '&' ||
        self == '!'
    end
  end
end
