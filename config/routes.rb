Rails.application.routes.draw do
  mount GrapeSwaggerRails::Engine => "/docs"
  mount API::V1::Base => "/"
end
