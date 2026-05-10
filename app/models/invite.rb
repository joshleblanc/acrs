class Invite < ApplicationRecord
  belongs_to :league
  
  has_secure_token :token
  
  validates :max_signups, numericality: { greater_than: 0 }, allow_nil: true
  
  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :available, -> { active.where("max_signups IS NULL OR signups_count < max_signups") }
  
  def signups_count
    league.players.joins(:user).where.not(users: { id: nil }).count
  end
  
  def available?
    (expires_at.nil? || expires_at > Time.current) && 
    (max_signups.nil? || signups_count < max_signups)
  end
  
  def expired?
    expires_at.present? && expires_at <= Time.current
  end
end
