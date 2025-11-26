class PersonaFollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_persona

  def create
    @follow = current_user.persona_follows.build(persona: @persona)

    if @follow.save
      respond_to do |format|
        format.html { redirect_to @persona, notice: "You're now following #{@persona.name}! You'll receive daily takes in your inbox." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @persona, alert: "Unable to follow persona: #{@follow.errors.full_messages.join(', ')}" }
        format.turbo_stream
      end
    end
  end

  def destroy
    @follow = current_user.persona_follows.find_by!(persona: @persona)
    @follow.destroy

    respond_to do |format|
      format.html { redirect_to @persona, notice: "Unfollowed #{@persona.name}. You won't receive daily emails anymore." }
      format.turbo_stream
    end
  end

  private

  def set_persona
    @persona = Persona.find_by!(slug: params[:persona_slug])
  end
end

