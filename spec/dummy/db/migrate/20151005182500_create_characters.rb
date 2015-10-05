class CreateCharacters < ActiveRecord::Migration
  def change
    create_table :characters do |t|
      t.string :name
      t.integer :species_id
      t.integer :episode_id

      t.timestamps null: false
    end
  end
end
