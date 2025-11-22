class CreateNewsStories < ActiveRecord::Migration[8.1]
  def change
    create_table :news_stories do |t|
      t.string :external_id, null: false
      t.string :headline, null: false
      t.text :summary
      t.text :full_content
      t.string :source, null: false
      t.string :source_url
      t.datetime :published_at
      t.string :category
      t.string :image_url
      t.boolean :featured, default: false, null: false
      t.boolean :active, default: true, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :news_stories, :external_id, unique: true
    add_index :news_stories, :published_at
    add_index :news_stories, :category
    add_index :news_stories, [ :featured, :active ]
    add_index :news_stories, :created_at
  end
end
