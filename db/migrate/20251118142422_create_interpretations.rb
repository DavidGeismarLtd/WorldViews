class CreateInterpretations < ActiveRecord::Migration[8.1]
  def change
    create_table :interpretations do |t|
      t.references :news_story, null: false, foreign_key: true, index: true
      t.references :persona, null: false, foreign_key: true, index: true
      t.text :content, null: false
      t.string :llm_model
      t.integer :llm_tokens_used
      t.integer :generation_time_ms
      t.boolean :cached, default: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    # Ensure unique interpretation per story/persona combination
    add_index :interpretations, [ :news_story_id, :persona_id ], unique: true
    add_index :interpretations, :created_at
  end
end
