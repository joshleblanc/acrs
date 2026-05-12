class League < ApplicationRecord
  belongs_to :game
  has_many :players, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :league_maps, dependent: :destroy
  has_many :maps, through: :league_maps
  
  normalizes :name, with: ->(n) { n.strip }
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  
  before_validation :generate_slug, if: -> { name.present? && slug.blank? }
  
  enum :status, [:draft, :accepting_signups, :active, :completed], default: :draft
  enum :match_day, { sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6 }
  
  # Scopes for Madmin
  scope :draft, -> { where(status: :draft) }
  scope :accepting_signups, -> { where(status: :accepting_signups) }
  scope :active, -> { where(status: :active) }
  scope :completed, -> { where(status: :completed) }
  
  def active_invite
    invites.active.available.first
  end
  
  def player_for(user)
    players.find_by(user: user)
  end
  
  def user_signed_up?(user)
    players.exists?(user: user)
  end
  
  def activate!
    LeagueActivationService.new(self).activate!
  end
  
  def deactivate_signups!
    update!(status: :active)
  end
  
  def players_count
    players.count
  end
  
  def groups_count
    groups.count
  end
  
  def group_standings
    groups.map do |group|
      {
        group: group,
        players: group.players.sort_by do |player|
          -player.wins_count
        end
      }
    end
  end

  def map_for_match(match)
    return nil if maps.empty?
    sorted_maps = maps.order('"league_maps"."order" ASC').to_a
    # Determine map index based on match's position in league
    match_index = matches.order(:id).pluck(:id).index(match.id) || 0
    sorted_maps[match_index % sorted_maps.size]
  end

  private
    def generate_slug
      self.slug = name.parameterize
    end
end
