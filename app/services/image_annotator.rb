# frozen_string_literal: true

# Service to annotate images with bounding boxes and labels
class ImageAnnotator
  class AnnotationError < StandardError; end

  # Colors for different categories (RGB)
  CATEGORY_COLORS = {
    "furniture" => [255, 0, 0],      # Red
    "people" => [0, 255, 0],         # Green
    "vehicle" => [0, 0, 255],        # Blue
    "electronics" => [255, 165, 0],  # Orange
    "appliance" => [128, 0, 128],    # Purple
    "other" => [128, 128, 128]      # Gray
  }.freeze

  def initialize(image_path, image_width, image_height)
    @image_path = image_path
    @image_width = image_width
    @image_height = image_height
    @image = MiniMagick::Image.open(image_path)
  end

  # Draw bounding boxes and labels on image
  # objects: Array of { label, category, confidence, bounding_box: { x_min, y_min, x_max, y_max } }
  # Returns path to annotated image
  def annotate(objects, output_path)
    return @image.path if objects.empty?

    # Convert normalized coordinates to pixel coordinates
    pixel_objects = objects.map { |obj| convert_to_pixels(obj) }

    # Draw each bounding box and label
    pixel_objects.each do |obj|
      draw_bounding_box(obj)
      draw_label(obj)
    end

    # Save as JPG
    @image.format "jpg"
    @image.write(output_path)
    output_path
  rescue MiniMagick::Error => e
    raise AnnotationError, "Failed to annotate image: #{e.message}"
  end

  private

  def convert_to_pixels(obj)
    bbox = obj[:bounding_box]
    {
      label: obj[:label],
      category: obj[:category],
      confidence: obj[:confidence],
      x_min: (bbox[:x_min] * @image_width).to_i,
      y_min: (bbox[:y_min] * @image_height).to_i,
      x_max: (bbox[:x_max] * @image_width).to_i,
      y_max: (bbox[:y_max] * @image_height).to_i
    }
  end

  def draw_bounding_box(obj)
    color = category_color(obj[:category])
    x_min = obj[:x_min]
    y_min = obj[:y_min]
    x_max = obj[:x_max]
    y_max = obj[:y_max]

    # Draw rectangle using ImageMagick draw command
    @image.combine_options do |c|
      c.stroke "rgb(#{color.join(',')})"
      c.fill "none"
      c.strokewidth 3
      c.draw "rectangle #{x_min},#{y_min} #{x_max},#{y_max}"
    end
  end

  def draw_label(obj)
    color = category_color(obj[:category])
    x_min = obj[:x_min]
    y_min = obj[:y_min]
    label_text = "#{obj[:label]} (#{(obj[:confidence] * 100).to_i}%)"

    # Draw label using ImageMagick annotate
    @image.combine_options do |c|
      # Label text with background
      c.fill "rgb(#{color.join(',')})"
      c.stroke "white"
      c.strokewidth 2
      c.pointsize 14
      c.font "Arial-Bold"
      c.gravity "NorthWest"
      c.annotate "+#{x_min + 3}+#{y_min + 3}", label_text
    end
  end

  def category_color(category)
    CATEGORY_COLORS[category] || CATEGORY_COLORS["other"]
  end
end
