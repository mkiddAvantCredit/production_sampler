require 'money-rails'

class Episode < ActiveRecord::Base
  belongs_to :series
  has_many :characters
  has_many :ships, foreign_key: :episode_uuid, primary_key: :uuid

  monetize :cost_cents, allow_nil: true

  scope :season_one, -> { where("production_number LIKE '1x%'") }
end
