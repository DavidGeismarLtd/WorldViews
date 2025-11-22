class AddUserAndOfficialToPersonas < ActiveRecord::Migration[8.1]
  def change
    add_reference :personas, :user, null: true, foreign_key: true
    add_column :personas, :official, :boolean, default: false, null: false
    add_column :personas, :visibility, :string, default: 'public', null: false

    # Mark existing personas as official
    reversible do |dir|
      dir.up do
        execute "UPDATE personas SET official = true WHERE user_id IS NULL"
      end
    end
  end
end
