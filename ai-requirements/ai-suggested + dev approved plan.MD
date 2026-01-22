## Requirements review summary

### What's already in place
1. Rails API with Grape framework
2. MongoDB/Mongoid configured
3. Environment variables (dotenv-rails)
4. Swagger documentation
5. API structure (`/api/v1/`)

### What needs to be implemented

#### 1. Google Cloud Vision API integration
- Add `google-cloud-vision` gem
- Configure credentials (service account JSON)
- Implement OBJECT_LOCALIZATION feature

#### 2. Object detection endpoint
- `POST /api/v1/object-detection`
- Request: `{ "image_url": "..." }`
- Response: structured JSON with annotated image URL and object metadata

#### 3. Object categorization system
- Create taxonomy config (YAML/JSON)
- Map Google Vision labels → categories (furniture, people, vehicle, etc.)
- Default to "other" for unmapped objects

#### 4. Image processing
- Download image from URL
- Get image dimensions
- Convert normalized coordinates → pixel coordinates
- Draw bounding boxes + labels on image
- Save annotated image (local storage or cloud)

#### 5. Error handling
- Invalid image URL → 400
- Vision API failure → 502
- No objects → 200 with empty list
- Image too large → 413

#### 6. Security & optimization
- Max image size validation (10MB)
- Rate limiting
- Result caching by image hash
- EXIF metadata stripping

### Implementation plan

1. Add required gems:
   - `google-cloud-vision`
   - `rmagick` or `mini_magick` (image processing)
   - `faraday` or `httparty` (download images)
   - `rack-attack` (rate limiting)

2. Create services:
   - `GoogleVisionService` — Vision API calls
   - `ObjectCategorizer` — taxonomy mapping
   - `ImageAnnotator` — bounding box drawing
   - `ImageDownloader` — fetch images

3. Create models (optional, for caching):
   - `ObjectDetection` — store detection results

4. Create API endpoint:
   - `app/controllers/api/v1/object_detection.rb`

5. Create config:
   - `config/taxonomy.yml` — category mappings

### Questions/clarifications

1. Image storage: local filesystem or cloud (S3/GCS)?
  => filesystem
2. Caching: use MongoDB to store detection results?
  => yes
3. Rate limiting: per IP or per API key?
  => no rate limit
4. Image size limit: confirm 10MB?
  => below 10MB
5. Annotated image format: PNG, JPEG, or both?
  => jpg

Should I proceed with implementation? I can start with:
1. Adding required gems
  => yes
2. Creating the service classes
  => yes
3. Implementing the API endpoint
  => yes
4. Setting up the taxonomy configuration
  => yes
