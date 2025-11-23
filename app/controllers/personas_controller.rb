class PersonasController < ApplicationController
  before_action :authenticate_user!, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_persona, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_persona_owner!, only: [ :edit, :update, :destroy ]

  def index
    @personas = Persona.active.ordered
  end

  def show
    unless @persona.viewable_by?(current_user)
      redirect_to personas_path, alert: "You don't have permission to view this persona."
      return
    end
    @recent_interpretations = @persona.recent_interpretations(10)
  end

  def new
    @persona = current_user.personas.build(
      visibility: "public",
      active: true,
      official: false
    )
  end

  def create
    @persona = current_user.personas.build(persona_params)
    @persona.official = false # Ensure user personas are never official

    # Handle avatar based on avatar_type
    handle_avatar_selection(@persona)

    if @persona.save
      # Generate avatar in background if AI option selected
      if params[:avatar_type] == "ai" && @persona.avatar_url.blank?
        GeneratePersonaAvatarJob.perform_async(@persona.id)
      end

      redirect_to persona_path(@persona), notice: "🎉 Persona created successfully! It will now interpret news stories."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @persona set by before_action
  end

  def update
    # Handle avatar based on avatar_type
    handle_avatar_selection(@persona)

    if @persona.update(persona_params)
      # Generate avatar in background if AI option selected and no avatar exists
      if params[:avatar_type] == "ai" && @persona.avatar_url.blank?
        GeneratePersonaAvatarJob.perform_async(@persona.id)
      end

      redirect_to persona_path(@persona), notice: "Persona updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @persona.destroy
    redirect_to personas_path, notice: "Persona deleted successfully."
  end

  private

  def set_persona
    @persona = Persona.find_by!(slug: params[:slug])
  end

  def authorize_persona_owner!
    unless @persona.editable_by?(current_user)
      redirect_to persona_path(@persona), alert: "You don't have permission to edit this persona."
    end
  end

  def persona_params
    params.require(:persona).permit(
      :name,
      :description,
      :system_prompt,
      :avatar_url,
      :color_primary,
      :color_secondary,
      :visibility,
      :active
    )
  end

  def handle_avatar_selection(persona)
    avatar_type = params[:avatar_type]

    case avatar_type
    when "letter"
      # Clear avatar_url to use first letter fallback
      persona.avatar_url = nil
    when "ai"
      # Clear avatar_url to trigger AI generation
      persona.avatar_url = nil
    when "upload"
      # File upload would be handled here
      # For now, avatar_url from params will be used (base64 or cloud URL)
      # In production, you'd upload to S3/Cloudinary first
    when "link"
      # avatar_url from params will be used directly
      # No additional processing needed
    end
  end
end
