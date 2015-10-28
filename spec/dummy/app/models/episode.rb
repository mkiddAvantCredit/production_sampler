require 'money-rails'

class Episode < ActiveRecord::Base
  belongs_to :series
  has_many :characters

  monetize :cost_cents, allow_nil: true
end
