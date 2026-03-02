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
        original_token_estimate: result["original_token_estimate"],
        optimized_token_estimate: result["optimized_token_estimate"]
      }
    end
  end
end
