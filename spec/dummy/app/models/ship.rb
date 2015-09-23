class Ship < ActiveRecord::Base
  belongs_to :faction
  has_many :crew_members
end
