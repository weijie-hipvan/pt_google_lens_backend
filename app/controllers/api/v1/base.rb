module API
  module V1
    class Base < BaseAPI
      version "v1", using: :path

      desc "Health check endpoint"
      get :health do
        { status: "ok", timestamp: Time.current.iso8601 }
      end

      # Mount other API endpoints here
      mount API::V1::Examples
      # mount API::V1::Users
      # mount API::V1::Products

      add_swagger_documentation(
        api_version: "v1",
        hide_documentation_path: true,
        mount_path: "/swagger_doc",
        info: {
          title: "PT Google Lens Backend API",
          description: "RESTful API documentation for PT Google Lens Backend",
          version: "v1"
        }
      )
    end
  end
end
