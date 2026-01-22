# frozen_string_literal: true

require "securerandom"
require "fileutils"

module API
  module V1
    class ObjectDetection < BaseAPI
      version "v1", using: :path

      helpers Helpers::ObjectDetectionHelpers

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

        # Check cache first if caching is enabled
        if ::ObjectDetection::ENABLE_CACHING
          cached_result = ::ObjectDetection.find_by_image_url(image_url)
          if cached_result
            return cached_result.to_api_response(request.base_url)
          end
        end

        # Download image
        downloader = ImageDownloader.new(image_url)
        temp_image_path = downloader.download

        begin
          # Get original image dimensions (for annotation)
          original_image = MiniMagick::Image.open(temp_image_path)
          original_width = original_image.width
          original_height = original_image.height

          # Detect objects using Google Vision API (may resize internally)
          vision_service = GoogleVisionService.new
          detection_result = vision_service.detect_objects(temp_image_path)

          detected_objects = detection_result[:objects]
          processed_width = detection_result[:image_dimensions][:width]
          processed_height = detection_result[:image_dimensions][:height]
          was_resized = detection_result[:was_resized]

          # Process and categorize objects
          # Use processed dimensions for coordinate conversion (what Google saw)
          processed_objects = process_objects(detected_objects, processed_width, processed_height)

          # If image was resized, we need to scale coordinates back to original size for annotation
          if was_resized
            scale_x = original_width.to_f / processed_width
            scale_y = original_height.to_f / processed_height
            processed_objects = scale_object_coordinates(processed_objects, scale_x, scale_y)
          end

          # Generate summary
          summary = generate_summary(processed_objects)

          # Annotate image with bounding boxes (use original dimensions)
          annotated_image_path = annotate_image(
            temp_image_path,
            original_width,
            original_height,
            processed_objects
          )

          # Generate thumbnails for each object and add thumbnail_url
          processed_objects_with_thumbnails = generate_thumbnails(
            temp_image_path,
            processed_objects,
            request.base_url
          )

          # Save to cache if caching is enabled
          if ::ObjectDetection::ENABLE_CACHING
            detection = ::ObjectDetection.create!(
              image_url: image_url,
              image_hash: ::ObjectDetection.hash_for_url(image_url),
              annotated_image_path: annotated_image_path,
              image_width: original_width,
              image_height: original_height,
              total_objects: processed_objects_with_thumbnails.length,
              categories: summary[:categories],
              objects_data: processed_objects_with_thumbnails
            )

            # Return response
            detection.to_api_response(request.base_url)
          else
            # Return response without saving to cache
            {
              image: {
                original_url: image_url,
                annotated_image_url: annotated_image_path.start_with?("http") ? annotated_image_path : "#{request.base_url}#{annotated_image_path}"
              },
              summary: summary,
              objects: processed_objects_with_thumbnails
            }
          end
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
    end
  end
end
