# frozen_string_literal: true

# Service to download images from URLs
# Validates image size and type before downloading
class ImageDownloader
  MAX_IMAGE_SIZE = 10.megabytes # 10MB limit

  class ImageDownloadError < StandardError; end
  class ImageTooLargeError < ImageDownloadError; end
  class InvalidImageURLError < ImageDownloadError; end
  class UnsupportedImageTypeError < ImageDownloadError; end

  def initialize(image_url)
    @image_url = image_url
    @temp_file = nil
  end

  # Downloads image and returns temporary file path
  # Raises errors for invalid URLs, oversized images, or unsupported formats
  def download
    validate_url
    download_image
    validate_size
    validate_format
    @temp_file.path
  rescue Faraday::Error => e
    raise InvalidImageURLError, "Failed to download image: #{e.message}"
  end

  # Cleanup temporary file
  def cleanup
    @temp_file&.close
    @temp_file&.unlink
  end

  private

  def validate_url
    uri = URI.parse(@image_url)
    raise InvalidImageURLError, "Invalid URL scheme" unless %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    raise InvalidImageURLError, "Malformed URL"
  end

  def download_image
    response = Faraday.get(@image_url) do |req|
      req.options.timeout = 30
      req.headers["User-Agent"] = "PT-Google-Lens-Backend/1.0"
    end

    raise InvalidImageURLError, "HTTP #{response.status}" unless response.success?

    # Check Content-Length header if available
    if response.headers["Content-Length"]
      content_length = response.headers["Content-Length"].to_i
      raise ImageTooLargeError, "Image size (#{content_length} bytes) exceeds limit" if content_length > MAX_IMAGE_SIZE
    end

    @temp_file = Tempfile.new(["image", ".tmp"])
    @temp_file.binmode
    @temp_file.write(response.body)
    @temp_file.rewind
  end

  def validate_size
    file_size = @temp_file.size
    raise ImageTooLargeError, "Image size (#{file_size} bytes) exceeds #{MAX_IMAGE_SIZE} bytes limit" if file_size > MAX_IMAGE_SIZE
  end

  def validate_format
    # Use MiniMagick to validate it's actually an image
    image = MiniMagick::Image.open(@temp_file.path)
    raise UnsupportedImageTypeError, "Unsupported image format: #{image.type}" unless %w[JPEG PNG GIF WEBP].include?(image.type)
  rescue MiniMagick::Invalid => e
    raise UnsupportedImageTypeError, "Invalid image file: #{e.message}"
  end
end
