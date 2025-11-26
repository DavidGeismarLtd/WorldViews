# == Schema Information
#
# Table name: persona_follows
#
#  id                  :bigint           not null, primary key
#  email_notifications :boolean          default(TRUE), not null
#  last_email_sent_at  :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  persona_id          :bigint           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_persona_follows_on_persona_id              (persona_id)
#  index_persona_follows_on_user_id                 (user_id)
#  index_persona_follows_on_user_id_and_persona_id  (user_id,persona_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (persona_id => personas.id)
#  fk_rails_...  (user_id => users.id)
#
class PersonaFollow < ApplicationRecord
  belongs_to :user
  belongs_to :persona

  validates :user_id, uniqueness: { scope: :persona_id, message: "already following this persona" }
  validates :persona, presence: true
  validates :user, presence: true

  # Scope for users who want email notifications
  scope :with_email_notifications, -> { where(email_notifications: true) }

  # Scope for follows that haven't received today's email
  scope :pending_daily_email, -> {
    with_email_notifications.where(
      "last_email_sent_at IS NULL OR last_email_sent_at < ?",
      Time.current.beginning_of_day
    )
  }
end

