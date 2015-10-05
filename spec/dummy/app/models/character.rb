class Character < ActiveRecord::Base
  belongs_to :species
  belongs_to :episode
end
