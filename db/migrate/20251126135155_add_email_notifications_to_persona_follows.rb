class AddEmailNotificationsToPersonaFollows < ActiveRecord::Migration[8.1]
  def change
    add_column :persona_follows, :email_notifications, :boolean, default: true, null: false
    add_column :persona_follows, :last_email_sent_at, :datetime

    # Add unique index to prevent duplicate follows (if it doesn't exist)
    unless index_exists?(:persona_follows, [ :user_id, :persona_id ])
      add_index :persona_follows, [ :user_id, :persona_id ], unique: true
    end
  end
end
