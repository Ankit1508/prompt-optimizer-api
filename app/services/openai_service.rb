class OpenaiService
  include HTTParty
  base_uri "https://api.openai.com/v1"

  def initialize
    @api_key = ENV["OPENAI_API_KEY"]
  end

  def optimize_prompt(prompt)
    options = {
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      },
      body: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are an elite prompt engineer. Fix grammar, improve clarity, optimize for token efficiency, preserve meaning. Return ONLY valid JSON with keys: corrected_prompt, optimized_prompt, original_token_estimate, optimized_token_estimate."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        response_format: { type: "json_object" }
      }.to_json
    }

    response = self.class.post("/chat/completions", options)
    
    if response.success?
      JSON.parse(response.parsed_response.dig("choices", 0, "message", "content"))
    else
      { error: "OpenAI API Error: #{response.code} - #{response.message}" }
    end
  end
end
