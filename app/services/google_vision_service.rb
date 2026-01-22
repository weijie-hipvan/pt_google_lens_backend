# frozen_string_literal: true

# Service to interact with Google Cloud Vision API
# Uses OBJECT_LOCALIZATION feature to detect objects in images
class GoogleVisionService
  class VisionAPIError < StandardError; end

  def initialize
    @client = initialize_client
  end

  # Detect objects in an image file
  # Returns array of detected objects with bounding boxes
  def detect_objects(image_path)
    response = @client.annotate_image(
      image: { content: File.binread(image_path) },
      features: [{ type: :OBJECT_LOCALIZATION }]
    )

    parse_objects(response.localized_object_annotations)
  rescue Google::Cloud::Error => e
    raise VisionAPIError, "Google Vision API error: #{e.message}"
  end

  private

  def initialize_client
    require "google/cloud/vision"
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
