class CreateShips < ActiveRecord::Migration
  def change
    create_table :ships do |t|
      t.string :name
      t.string :registry_number
      t.string :episode_uuid

      t.timestamps null: false
    end
  end
end
