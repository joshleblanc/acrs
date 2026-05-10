class InviteResource < Madmin::Resource
  attribute :id, form: false
  attribute :token
  attribute :expires_at
  attribute :max_signups
  attribute :signups_count, form: false
  attribute :created_at, form: false
  attribute :league


  def self.record_label(method)
    "#{method.token&.first(8)}..."
  end
end
