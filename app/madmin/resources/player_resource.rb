class PlayerResource < Madmin::Resource
  attribute :id, form: false
  attribute :name
  attribute :elo
  attribute :league 
  attribute :user 
  attribute :groups
  attribute :created_at, form: false
  attribute :updated_at, form: false

end
