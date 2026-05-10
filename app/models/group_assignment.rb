class GroupAssignment < ApplicationRecord
  belongs_to :group
  belongs_to :player
  
  validates :player_id, uniqueness: { scope: :group }
end
