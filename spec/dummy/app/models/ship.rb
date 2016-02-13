class Ship < ActiveRecord::Base
  belongs_to :episode, foreign_key: :episode_uuid, primary_key: :uuid
end
