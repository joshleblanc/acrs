class GroupResource < Madmin::Resource
  attribute :id, form: false
  attribute :name
  attribute :tier
  attribute :min_players
  attribute :max_players
  attribute :created_at, form: false
  attribute :league
end
