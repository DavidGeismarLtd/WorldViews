class PersonasController < ApplicationController
  def index
    @personas = Persona.active.ordered
  end

  def show
    @persona = Persona.find_by!(slug: params[:slug])
    @recent_interpretations = @persona.recent_interpretations(10)
  end
end

