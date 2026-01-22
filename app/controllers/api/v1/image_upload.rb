# frozen_string_literal: true

require "securerandom"
require "fileutils"

module API
  module V1
    class ImageUpload < BaseAPI
      version "v1", using: :path

      desc "Upload an image file and return its URL",
           consumes: ["multipart/form-data"],
           success: { code: 200, message: "Image uploaded successfully" },
           failure: [
             { code: 400, message: "Invalid image file" },
             { code: 413, message: "Image too large" }
           ]
      params do
        requires :image,
                 type: File,
                 desc: "Image file to upload. Supported formats: JPEG, PNG, GIF, WEBP. Max size: 10MB",
                 documentation: {
                   type: "file",
                   param_type: "formData",
                   required: true
                 }
      end
      post :image_upload do
        uploaded_file = params[:image]

        # Validate file is present
        unless uploaded_file
          error!({ status: false, message: "Image file is required", code: 400 }, 400)
        end

        # Get file details
        tempfile = uploaded_file[:tempfile]
        filename = uploaded_file[:filename] || "uploaded_image"
        content_type = uploaded_file[:type]

        # Validate file size
        file_size = tempfile.size
        if file_size > ImageDownloader::MAX_IMAGE_SIZE
          error!({ status: false, message: "Image size (#{file_size} bytes) exceeds #{ImageDownloader::MAX_IMAGE_SIZE} bytes limit", code: 413 }, 413)
        end

        # Validate file format using MiniMagick
        begin
          image = MiniMagick::Image.open(tempfile.path)
          unless %w[JPEG PNG GIF WEBP].include?(image.type)
            error!({ status: false, message: "Unsupported image format: #{image.type}. Supported formats: JPEG, PNG, GIF, WEBP", code: 400 }, 400)
          end
        rescue MiniMagick::Invalid => e
          error!({ status: false, message: "Invalid image file: #{e.message}", code: 400 }, 400)
        end

        # Create uploads directory if it doesn't exist
        uploads_dir = Rails.root.join("public", "uploads")
        FileUtils.mkdir_p(uploads_dir)

        # Generate unique filename
        file_extension = File.extname(filename).presence || ".#{image.type.downcase}"
        unique_filename = "#{Time.current.to_i}_#{SecureRandom.hex(8)}#{file_extension}"
        file_path = uploads_dir.join(unique_filename)

        # Copy uploaded file to public directory
        FileUtils.cp(tempfile.path, file_path.to_s)

        # Return the public URL
        image_url = "#{request.base_url}/uploads/#{unique_filename}"

        {
          status: true,
          message: "Image uploaded successfully",
          image_url: image_url,
          filename: unique_filename,
          size: file_size,
          width: image.width,
          height: image.height,
          format: image.type
        }
      rescue StandardError => e
        error!({ status: false, message: "Failed to upload image: #{e.message}", code: 500 }, 500)
      end
    end
  end
end
