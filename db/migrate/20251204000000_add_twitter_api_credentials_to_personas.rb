class AddTwitterApiCredentialsToPersonas < ActiveRecord::Migration[7.0]
  def change
    add_column :personas, :twitter_api_key, :string
    add_column :personas, :twitter_api_secret, :string
  end
end

