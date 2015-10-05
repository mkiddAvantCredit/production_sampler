class CreateEpisodes < ActiveRecord::Migration
  def change
    create_table :episodes do |t|
      t.string :title
      t.string :production_number
      t.integer :series_id

      t.timestamps null: false
    end
  end
end
