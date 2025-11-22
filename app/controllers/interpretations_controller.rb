class InterpretationsController < ApplicationController
  def show
    @interpretation = Interpretation.find(params[:id])
    @news_story = @interpretation.news_story
    @persona = @interpretation.persona

    # Enqueue background job to generate detailed interpretation if it doesn't exist
    if @interpretation.detailed_content.blank?
      GenerateDetailedInterpretationJob.perform_async(@interpretation.id)
    end
  end
end
