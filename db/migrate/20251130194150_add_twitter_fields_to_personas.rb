class AddTwitterFieldsToPersonas < ActiveRecord::Migration[8.1]
  def change
    add_column :personas, :twitter_handle, :string
    add_column :personas, :twitter_enabled, :boolean, default: false, null: false
    add_column :personas, :last_tweet_at, :datetime
    add_column :personas, :twitter_access_token, :string
    add_column :personas, :twitter_access_token_secret, :string

    add_index :personas, :twitter_handle, unique: true
    add_index :personas, :twitter_enabled
  end
end
