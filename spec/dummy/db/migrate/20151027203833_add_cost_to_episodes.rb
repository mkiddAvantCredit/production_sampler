class AddCostToEpisodes < ActiveRecord::Migration
  def change
    add_column  :episodes, :cost_cents, :integer
  end
end
