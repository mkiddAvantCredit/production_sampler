class Episode < ActiveRecord::Base
  belongs_to :series
  has_many :characters
end
