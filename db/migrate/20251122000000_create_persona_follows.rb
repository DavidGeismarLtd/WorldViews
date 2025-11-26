class CreatePersonaFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :persona_follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :persona, null: false, foreign_key: true

      t.timestamps
    end

    add_index :persona_follows, [ :user_id, :persona_id ], unique: true
  end
end

