class AddUuidToEpisode < ActiveRecord::Migration
  def change
    add_column :episodes, :uuid, :string
  end
end
