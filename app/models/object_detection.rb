# frozen_string_literal: true

# MongoDB model to cache object detection results
class ObjectDetection
  include Mongoid::Document
  include Mongoid::Timestamps

  # Image identification
  field :image_url, type: String
  field :image_hash, type: String # SHA256 hash of image URL for caching

  # Detection results
  field :annotated_image_path, type: String
  field :image_width, type: Integer
  field :image_height, type: Integer
  field :total_objects, type: Integer, default: 0
  field :categories, type: Hash, default: {} # { "furniture" => 5, "people" => 1 }

  # Full detection data (for detailed responses)
  field :objects_data, type: Array, default: []

  # Indexes
  index({ image_hash: 1 }, unique: true)
  index({ created_at: -1 })
  index({ image_url: 1 })

  # Validations
  validates :image_url, presence: true
  validates :image_hash, presence: true, uniqueness: true

  # Generate hash from image URL for caching
  def self.hash_for_url(url)
    require "digest"
    Digest::SHA256.hexdigest(url.to_s)
  end

  # Find cached result by image URL
  def self.find_by_image_url(url)
    where(image_hash: hash_for_url(url)).first
  end

  # Convert to API response format
  def to_api_response(base_url = "")
    {
      image: {
        original_url: image_url,
        annotated_image_url: annotated_image_path.start_with?("http") ? annotated_image_path : "#{base_url}#{annotated_image_path}"
      },
      summary: {
        total_objects: total_objects,
        categories: categories
      },
      objects: objects_data
    }
  end
end
