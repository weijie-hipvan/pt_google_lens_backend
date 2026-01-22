module API
  module V1
    class Examples < Grape::API
      version "v1", using: :path

      resource :examples do
        desc "Get all examples"
        get do
          examples = Example.all
          present examples, with: Entities::Example
        end

        desc "Get a specific example"
        params do
          requires :id, type: String, desc: "Example ID"
        end
        get ":id" do
          example = Example.find(params[:id])
          present example, with: Entities::Example
        end

        desc "Create a new example"
        params do
          requires :name, type: String, desc: "Example name"
          optional :description, type: String, desc: "Example description"
          optional :active, type: Boolean, desc: "Active status", default: true
        end
        post do
          example = Example.create!(
            name: params[:name],
            description: params[:description],
            active: params[:active]
          )
          present example, with: Entities::Example
        end

        desc "Update an example"
        params do
          requires :id, type: String, desc: "Example ID"
          optional :name, type: String, desc: "Example name"
          optional :description, type: String, desc: "Example description"
          optional :active, type: Boolean, desc: "Active status"
        end
        put ":id" do
          example = Example.find(params[:id])
          update_params = declared(params, include_missing: false).except(:id)
          example.update!(update_params.to_h)
          present example, with: Entities::Example
        end

        desc "Delete an example"
        params do
          requires :id, type: String, desc: "Example ID"
        end
        delete ":id" do
          example = Example.find(params[:id])
          example.destroy
          { message: "Example deleted successfully" }
        end
      end
    end
  end
end
