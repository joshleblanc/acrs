class MatchGame < ApplicationRecord
  belongs_to :match
  belongs_to :map, optional: true
  belongs_to :winner, class_name: "Player", optional: true
  
  enum :status, [:pending, :races_selected, :map_set, :completed]
  
  validates :game_number, presence: true, uniqueness: { scope: :match }
end
