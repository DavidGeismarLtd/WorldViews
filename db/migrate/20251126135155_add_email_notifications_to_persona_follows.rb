class AddEmailNotificationsToPersonaFollows < ActiveRecord::Migration[8.1]
  def change
    add_column :persona_follows, :email_notifications, :boolean, default: true, null: false
    add_column :persona_follows, :last_email_sent_at, :datetime
  end
end
