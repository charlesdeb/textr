# frozen_string_literal: true

# Used for suggesting words based to a user
class Suggester
  def initialize(suggestion_params)
    @show_analysis = (suggestion_params[:show_analysis] == 'true')
  end

  def suggest
    { candidates: [
      { token_text: 'the', probability: 0.75, chunk_size: 6 },
      { token_text: 'a', probability: 0.15, chunk_size: 4 },
      { token_text: 'this', probability: 0.05, chunk_size: 4 }
    ],
      analysis: [
        { chunk_size: 6,
          chunk: 'The cat in ', candidate_token_texts: [
            { token_text: 'the', probability: 0.75 },
            { token_text: 'a', probability: 0.15 },
            { token_text: 'this', probability: 0.05 }
          ] },
        { chunk_size: 5,
          chunk: ' cat in ', candidate_token_texts: [
            { token_text: 'the', probability: 0.75 },
            { token_text: 'a', probability: 0.15 },
            { token_text: 'this', probability: 0.05 }
          ] },
        { chunk_size: 4,
          chunk: 'cat in ', candidate_token_texts: [
            { token_text: 'the', probability: 0.75 },
            { token_text: 'a', probability: 0.15 },
            { token_text: 'this', probability: 0.05 }
          ] }
      ] }
  end
end
