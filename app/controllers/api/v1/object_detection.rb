# frozen_string_literal: true

require "securerandom"
require "fileutils"

module API
  module V1
    class ObjectDetection < BaseAPI
      version "v1", using: :path

      desc "Detect objects in an image and return annotated image with metadata",
           success: { code: 200, message: "Detection successful" },
           failure: [
             { code: 400, message: "Invalid image URL" },
             { code: 413, message: "Image too large" },
             { code: 502, message: "Google Vision API error" }
           ]
      params do
        requires :image_url, type: String, desc: "URL of the image to analyze"
      end
      post :object_detection do
        image_url = params[:image_url]

        # Check cache first
        cached_result = ObjectDetection.find_by_image_url(image_url)
        if cached_result
          return cached_result.to_api_response(request.base_url)
        end

        # Download image
        downloader = ImageDownloader.new(image_url)
        temp_image_path = downloader.download

        begin
          # Get image dimensions
          image = MiniMagick::Image.open(temp_image_path)
          image_width = image.width
          image_height = image.height

          # Detect objects using Google Vision API
          vision_service = GoogleVisionService.new
          detected_objects = vision_service.detect_objects(temp_image_path)

          # Process and categorize objects
          processed_objects = process_objects(detected_objects, image_width, image_height)

          # Generate summary
          summary = generate_summary(processed_objects)

          # Annotate image with bounding boxes
          annotated_image_path = annotate_image(
            temp_image_path,
            image_width,
            image_height,
            processed_objects
          )

          # Save to cache
          detection = ObjectDetection.create!(
            image_url: image_url,
            image_hash: ObjectDetection.hash_for_url(image_url),
            annotated_image_path: annotated_image_path,
            image_width: image_width,
            image_height: image_height,
            total_objects: processed_objects.length,
            categories: summary[:categories],
            objects_data: processed_objects
          )

          # Return response
          detection.to_api_response(request.base_url)
        rescue ImageDownloader::ImageTooLargeError => e
          error!({ status: false, message: e.message, code: 413 }, 413)
        rescue ImageDownloader::InvalidImageURLError, ImageDownloader::UnsupportedImageTypeError => e
          error!({ status: false, message: e.message, code: 400 }, 400)
        rescue GoogleVisionService::VisionAPIError => e
          error!({ status: false, message: e.message, code: 502 }, 502)
        ensure
          downloader.cleanup
        end
      end

      private

      def process_objects(detected_objects, image_width, image_height)
        detected_objects.map.with_index(1) do |obj, index|
          label = obj[:name]
          category = ObjectCategorizer.categorize(label)
          confidence = obj[:score]
          bounding_box = obj[:bounding_poly]

          # Convert normalized coordinates to pixel coordinates
          pixel_coords = convert_to_pixels(bounding_box, image_width, image_height)

          {
            id: "obj_#{index}",
            label: label,
            category: category,
            confidence: confidence,
            bounding_box: bounding_box,
            thumbnail_crop: pixel_coords
          }
        end
      end

      def convert_to_pixels(bounding_box, image_width, image_height)
        return {} unless bounding_box

        {
          x: (bounding_box[:x_min] * image_width).to_i,
          y: (bounding_box[:y_min] * image_height).to_i,
          width: ((bounding_box[:x_max] - bounding_box[:x_min]) * image_width).to_i,
          height: ((bounding_box[:y_max] - bounding_box[:y_min]) * image_height).to_i
        }
      end

      def generate_summary(processed_objects)
        categories = processed_objects.each_with_object({}) do |obj, hash|
          category = obj[:category]
          hash[category] = (hash[category] || 0) + 1
        end

        {
          total_objects: processed_objects.length,
          categories: categories
        }
      end

      def annotate_image(image_path, image_width, image_height, objects)
        # Create output directory if it doesn't exist
        output_dir = Rails.root.join("public", "annotated_images")
        FileUtils.mkdir_p(output_dir)

        # Generate unique filename
        filename = "annotated_#{Time.current.to_i}_#{SecureRandom.hex(8)}.jpg"
        output_path = output_dir.join(filename)

        # Annotate image
        annotator = ImageAnnotator.new(image_path, image_width, image_height)
        annotator.annotate(objects, output_path.to_s)

        # Return relative path for URL generation
        "/annotated_images/#{filename}"
      end
    end
  end
end
