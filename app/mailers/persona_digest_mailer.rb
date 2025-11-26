class PersonaDigestMailer < ApplicationMailer
  default from: "WorldViews <noreply@worldviews.app>"

  def daily_digest(user, persona, interpretations)
    @user = user
    @persona = persona
    @interpretations = interpretations
    @date = Date.current

    mail(
      to: user.email,
      subject: "#{persona.name}'s Daily Takes - #{@date.strftime('%B %d, %Y')}"
    )
  end
end

