# frozen_string_literal: true

module API
  module V1
    module Helpers
      module ObjectDetectionHelpers
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

        def scale_object_coordinates(objects, scale_x, scale_y)
          objects.map do |obj|
            # Scale bounding box coordinates
            bbox = obj[:bounding_box]
            scaled_bbox = {
              x_min: bbox[:x_min] * scale_x,
              y_min: bbox[:y_min] * scale_y,
              x_max: bbox[:x_max] * scale_x,
              y_max: bbox[:y_max] * scale_y
            }
            
            # Scale thumbnail crop coordinates
            crop = obj[:thumbnail_crop]
            scaled_crop = {
              x: (crop[:x] * scale_x).to_i,
              y: (crop[:y] * scale_y).to_i,
              width: (crop[:width] * scale_x).to_i,
              height: (crop[:height] * scale_y).to_i
            }
            
            obj.merge(
              bounding_box: scaled_bbox,
              thumbnail_crop: scaled_crop
            )
          end
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
end
