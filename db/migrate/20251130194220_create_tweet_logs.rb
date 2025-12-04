class CreateTweetLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :tweet_logs do |t|
      t.references :persona, null: false, foreign_key: true
      t.references :news_story, null: false, foreign_key: true
      t.string :tweet_id
      t.text :tweet_text
      t.datetime :posted_at
      t.boolean :success, default: false, null: false
      t.text :error_message

      t.timestamps
    end

    add_index :tweet_logs, :posted_at
    add_index :tweet_logs, :success
    add_index :tweet_logs, :tweet_id, unique: true
  end
end
