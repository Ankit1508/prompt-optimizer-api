class Api::OptimizeController < ApplicationController
  def optimize
    prompt = params[:prompt]

    if prompt.blank?
      render json: { error: "Prompt is required" }, status: :unprocessable_entity
      return
    end

    service = OpenaiService.new
    result = service.optimize_prompt(prompt)

    if result[:error]
      render json: result, status: :bad_gateway
    else
      render json: {
        corrected_prompt: result["corrected_prompt"],
        optimized_prompt: result["optimized_prompt"],
        original_tokens: result["original_tokens"],
        optimized_tokens: result["optimized_tokens"],
        is_demo: result["is_demo"]
      }
    end
  end
end
