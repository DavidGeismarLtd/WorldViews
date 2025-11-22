class AddDetailedContentToInterpretations < ActiveRecord::Migration[8.1]
  def change
    add_column :interpretations, :detailed_content, :text
  end
end
