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

    if @persona.save
      redirect_to persona_path(@persona), notice: "🎉 Persona created successfully! It will now interpret news stories."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @persona set by before_action
  end

  def update
    if @persona.update(persona_params)
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
end
