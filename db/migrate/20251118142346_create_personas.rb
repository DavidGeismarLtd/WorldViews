class CreatePersonas < ActiveRecord::Migration[8.1]
  def change
    create_table :personas do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.text :system_prompt, null: false
      t.string :avatar_url
      t.string :color_primary
      t.string :color_secondary
      t.integer :display_order, default: 0
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :personas, :slug, unique: true
    add_index :personas, :display_order
    add_index :personas, :active
  end
end
