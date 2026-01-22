class Example
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :active, type: Boolean, default: true

  validates :name, presence: true
end
