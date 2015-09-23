class CreateShips < ActiveRecord::Migration
  def change
    create_table :ships do |t|
      t.string :name
      t.string :registry_number
      t.integer :faction_id

      t.timestamps null: false
    end
  end
end
