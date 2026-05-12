class LeagueResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :status
  attribute :description
  attribute :match_day
  attribute :created_at, form: false
  attribute :updated_at, form: false
  
  # Computed attributes
  attribute :players_count, form: false
  attribute :groups_count, form: false

  # Associations
  attribute :game
  attribute :players
  attribute :groups
  attribute :maps

  # Scopes
  scope :draft
  scope :accepting_signups
  scope :active
  scope :completed
 
  # Customize the display name of records in the admin area.
  def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  def self.default_sort_column = "created_at"
  def self.default_sort_direction = "desc"
end
