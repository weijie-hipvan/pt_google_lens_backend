# frozen_string_literal: true

require "fileutils"
require "tempfile"

# Service to interact with Google Cloud Vision API
# Uses OBJECT_LOCALIZATION feature to detect objects in images
class GoogleVisionService
  class VisionAPIError < StandardError; end

  # Google Vision API limit: 75 megapixels
  MAX_MEGAPIXELS = 75
  MAX_PIXELS = MAX_MEGAPIXELS * 1_000_000

  def initialize
    @client = initialize_client
  end

  # Detect objects in an image file
  # Returns hash with :objects array and :image_dimensions hash
  def detect_objects(image_path)
    # Resize image if it exceeds Google's limits
    processed_image_path, was_resized = resize_if_needed(image_path)

    begin
      # Get dimensions of the image that will be sent to Google (may be resized)
      processed_image = MiniMagick::Image.open(processed_image_path)
      processed_width = processed_image.width
      processed_height = processed_image.height

      image_content = File.binread(processed_image_path)

      request = {
        image: { content: image_content },
        features: [ { type: :OBJECT_LOCALIZATION, max_results: 50 } ]
      }

      response = @client.batch_annotate_images(requests: [ request ])
      result = response.responses.first

      if result.error
        raise VisionAPIError, "Google Vision API error: #{result.error.message}"
      end

      {
        objects: parse_objects(result.localized_object_annotations),
        image_dimensions: {
          width: processed_width,
          height: processed_height
        },
        was_resized: was_resized
      }
    rescue Google::Cloud::Error => e
      raise VisionAPIError, "Google Vision API error: #{e.message}"
    ensure
      # Clean up temporary resized image if it was created
      if processed_image_path != image_path && File.exist?(processed_image_path)
        FileUtils.rm_f(processed_image_path)
      end
    end
  end

  private

  # Resize image if it exceeds Google Vision API limits (75 megapixels)
  # Returns [path_to_image, was_resized_boolean]
  def resize_if_needed(image_path)
    image = MiniMagick::Image.open(image_path)
    width = image.width
    height = image.height
    total_pixels = width * height

    # Check if image exceeds limit
    if total_pixels > MAX_PIXELS
      # Calculate new dimensions maintaining aspect ratio
      scale_factor = Math.sqrt(MAX_PIXELS.to_f / total_pixels)
      new_width = (width * scale_factor).to_i
      new_height = (height * scale_factor).to_i

      # Create temporary file for resized image
      temp_file = Tempfile.new([ "resized_image", File.extname(image_path) ])
      temp_file.binmode
      temp_file.close

      # Resize image
      image.resize("#{new_width}x#{new_height}")
      image.write(temp_file.path)

      Rails.logger.info "Resized image from #{width}x#{height} (#{(total_pixels / 1_000_000.0).round(2)}MP) to #{new_width}x#{new_height} (#{(new_width * new_height / 1_000_000.0).round(2)}MP)"

      [ temp_file.path, true ]
    else
      # Image is within limits, return original path
      [ image_path, false ]
    end
  rescue MiniMagick::Error => e
    Rails.logger.error "Failed to resize image: #{e.message}"
    # Return original path if resize fails
    [ image_path, false ]
  end

  def initialize_client
    require "google/cloud/vision"

    # Set credentials path if not already set in environment
    unless ENV["GOOGLE_APPLICATION_CREDENTIALS"]
      default_credentials_path = Rails.root.join("config", "credentials", "google-vision-service-account.json").to_s
      if File.exist?(default_credentials_path)
        ENV["GOOGLE_APPLICATION_CREDENTIALS"] = default_credentials_path
      end
    end

    Google::Cloud::Vision.image_annotator
  end

  def parse_objects(annotations)
    annotations.map do |annotation|
      {
        name: annotation.name,
        score: annotation.score,
        bounding_poly: parse_bounding_poly(annotation.bounding_poly)
      }
    end
  end

  def parse_bounding_poly(bounding_poly)
    return nil unless bounding_poly&.normalized_vertices

    vertices = bounding_poly.normalized_vertices
    return nil if vertices.empty?

    # Extract min/max coordinates from normalized vertices
    x_coords = vertices.map(&:x).compact
    y_coords = vertices.map(&:y).compact

    {
      x_min: x_coords.min || 0.0,
      y_min: y_coords.min || 0.0,
      x_max: x_coords.max || 0.0,
      y_max: y_coords.max || 0.0
    }
  end
end
