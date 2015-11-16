require 'money-rails'

class Episode < ActiveRecord::Base
  belongs_to :series
  has_many :characters

  monetize :cost_cents, allow_nil: true

  scope :season_one, -> { where("production_number LIKE '1x%'") }
end
