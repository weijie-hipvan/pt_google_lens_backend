module Entities
  class Example < Grape::Entity
    expose :id
    expose :name
    expose :description
    expose :active
    expose :created_at
    expose :updated_at
  end
end
