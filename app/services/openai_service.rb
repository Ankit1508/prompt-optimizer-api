class OpenaiService
  include HTTParty
  base_uri "https://api.openai.com/v1"

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a world-class prompt optimization specialist and expert communicator.

    Your job is to take a user's raw, messy, or poorly written prompt and transform it into a highly effective, professional, and optimized prompt.

    ## Your Process:
    1. **Understand Intent**: Deeply analyze what the user is really trying to achieve, even if their input is riddled with typos, shorthand, or vague language.
    2. **Correct Everything**: Fix all grammar, spelling, punctuation, and sentence structure errors.
    3. **Expand & Enrich**: If the input is too brief or vague, intelligently expand it with relevant context, structure, and detail that aligns with the user's likely intent.
    4. **Professional Structure**: Convert the prompt into a clear, well-organized, professional format with:
       - A clear objective/role statement
       - Specific context and constraints
       - Actionable instructions
       - Desired output format or tone when applicable
    5. **Token Optimize**: Remove redundancy while keeping all meaningful content. Every word should earn its place.
    6. **Preserve Intent**: Never change what the user wants — only improve HOW they ask for it.

    ## Examples of your work:
    - Input: "rite a mail to hr for hiike" 
    - Output: "Write a professional salary hike request email to HR. I am a dedicated employee who has consistently delivered results. The email should be confident, respectful, and persuasive. Keep it concise and impactful. Include a subject line."

    - Input: "make website dark mode"
    - Output: "Implement a dark mode theme for the website. Add a toggle switch in the navigation bar. Use CSS custom properties for theme colors. Ensure all components, backgrounds, text, and interactive elements adapt properly. Maintain accessibility contrast ratios. Persist user preference in localStorage."

    ## Output Rules:
    - Return ONLY valid JSON, nothing else.
    - No explanations, no commentary, no markdown outside JSON.
    - JSON keys: corrected_prompt, optimized_prompt, original_tokens, optimized_tokens
    - corrected_prompt: The user's original prompt with ONLY grammar/spelling fixes (minimal changes).
    - optimized_prompt: The fully expanded, enriched, professional, token-optimized version.
    - original_tokens: Estimated token count of the original input.
    - optimized_tokens: Estimated token count of the optimized output.
  PROMPT

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
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: prompt }
        ],
        response_format: { type: "json_object" },
        temperature: 0.7
      }.to_json
    }

    response = self.class.post("/chat/completions", options)

    if response.success?
      begin
        JSON.parse(response.parsed_response.dig("choices", 0, "message", "content"))
      rescue JSON::ParserError
        smart_fallback(prompt)
      rescue => e
        smart_fallback(prompt)
      end
    elsif response.code == 429 || response.code == 401
      smart_fallback(prompt)
    else
      { error: "OpenAI API Error: #{response.code} - #{response.message}" }
    end
  end

  private

  def smart_fallback(prompt)
    corrected = auto_correct(prompt)
    optimized = expand_prompt(corrected)

    original_tok = estimate_tokens(prompt)
    optimized_tok = estimate_tokens(optimized)

    {
      "corrected_prompt" => corrected,
      "optimized_prompt" => optimized,
      "original_tokens" => original_tok,
      "optimized_tokens" => optimized_tok,
      "is_demo" => true
    }
  end

  def auto_correct(text)
    # Basic spelling corrections for common mistakes
    corrections = {
      "rite" => "write", "wright" => "write", "writ" => "write",
      "hiike" => "hike", "hike" => "hike",
      "mai" => "mail", "emai" => "email",
      "plz" => "please", "pls" => "please",
      "u" => "you", "ur" => "your", "r" => "are",
      "b4" => "before", "2" => "to", "4" => "for",
      "msg" => "message", "thx" => "thanks", "tnx" => "thanks",
      "abt" => "about", "govt" => "government",
      "yr" => "year", "yrs" => "years",
      "hr" => "HR", "ceo" => "CEO", "cto" => "CTO",
      "mgr" => "manager", "dept" => "department",
      "appl" => "application", "app" => "application",
      "dev" => "development", "prod" => "production",
      "impl" => "implement", "config" => "configure",
      "db" => "database", "api" => "API",
      "auth" => "authentication", "admin" => "administration",
      "btn" => "button", "nav" => "navigation",
      "bg" => "background", "img" => "image",
      "func" => "function", "vars" => "variables",
      "repo" => "repository", "env" => "environment",
      "info" => "information", "docs" => "documentation",
      "perf" => "performance", "opt" => "optimize"
    }

    words = text.split(/\s+/)
    corrected_words = words.map do |word|
      clean = word.downcase.gsub(/[^a-z0-9]/, "")
      replacement = corrections[clean]
      if replacement
        # Preserve punctuation
        word.gsub(/[a-zA-Z]+/, replacement)
      else
        word
      end
    end

    result = corrected_words.join(" ")
    # Capitalize first letter
    result = result.strip
    result[0] = result[0].upcase if result.length > 0
    # Ensure ends with period
    result += "." unless result.match?(/[.!?]\s*$/)
    result
  end

  def expand_prompt(corrected)
    # Detect intent categories and expand accordingly
    text_lower = corrected.downcase

    expansions = []

    if text_lower.include?("mail") || text_lower.include?("email") || text_lower.include?("letter")
      if text_lower.include?("hike") || text_lower.include?("salary") || text_lower.include?("raise")
        expansions = [
          "Write a professional salary hike request email to HR.",
          "Highlight consistent performance, project deliveries, and key contributions.",
          "The tone should be confident, respectful, and persuasive.",
          "Keep it concise and impactful.",
          "Include a compelling subject line."
        ]
      elsif text_lower.include?("leave") || text_lower.include?("vacation") || text_lower.include?("off")
        expansions = [
          "Write a professional leave application email.",
          "Clearly state the leave dates and reason.",
          "Mention any planned handover of responsibilities.",
          "Keep the tone polite and professional.",
          "Include a clear subject line."
        ]
      elsif text_lower.include?("resign") || text_lower.include?("quit")
        expansions = [
          "Write a professional resignation email.",
          "Express gratitude for the opportunities provided.",
          "State the last working day clearly.",
          "Offer to assist with the transition.",
          "Keep the tone respectful and professional.",
          "Include a subject line."
        ]
      else
        expansions = [
          corrected,
          "Write in a professional and clear tone.",
          "Structure the email with proper greeting, body, and closing.",
          "Keep it concise and to the point.",
          "Include a subject line."
        ]
      end
    elsif text_lower.include?("website") || text_lower.include?("web") || text_lower.include?("page")
      expansions = [
        corrected,
        "Ensure modern, responsive design principles.",
        "Follow accessibility best practices.",
        "Use clean, maintainable code structure.",
        "Optimize for performance and user experience."
      ]
    elsif text_lower.include?("code") || text_lower.include?("function") || text_lower.include?("implement") || text_lower.include?("build") || text_lower.include?("create")
      expansions = [
        corrected,
        "Write clean, well-documented, and maintainable code.",
        "Follow best practices and design patterns.",
        "Include error handling and edge cases.",
        "Add clear comments where necessary."
      ]
    else
      expansions = [
        corrected,
        "Provide a comprehensive and well-structured response.",
        "Be specific, actionable, and clear.",
        "Use professional tone and accurate details.",
        "Organize with clear sections if needed."
      ]
    end

    expansions.join("\n")
  end

  def estimate_tokens(text)
    # Approximate: 1 token ≈ 4 characters for English text
    (text.length / 4.0).ceil
  end
end
