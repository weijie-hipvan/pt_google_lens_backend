Below is a **high-detail, implementation-ready requirements document** plus a **step-by-step execution plan explicitly written to instruct an AI coding agent (Cursor)** to build the system for you.

This is written as a **technical specification**, not marketing prose, and assumes a backend-engineering audience.

---

# 1. Goal & Scope

Build a **simple HTTP API** that:

* Accepts an **image URL** (photo captured from phone or uploaded elsewhere)
* Uses **Google Cloud Vision API** to detect objects
* **Groups detected objects** into higher-level categories (furniture, people, vehicle, etc.)
* **Returns**:

  1. The original image **annotated with bounding boxes + labels**
  2. A **structured JSON payload** describing each detected object, including:

     * label
     * category
     * confidence score
     * bounding box coordinates (suitable for later cropping thumbnails)

This system is designed to be:

* Stateless
* Easy to extend (taxonomy updates, additional AI models later)
* Frontend-agnostic

---

# 2. High-Level Architecture

```
Client (Web / Mobile)
        |
        | POST /detect-objects
        |
Backend API (Rails / Node / Python)
        |
        |-- Fetch image from URL
        |-- Call Google Vision API
        |-- Post-process results
        |-- Group objects
        |-- Draw bounding boxes
        |
   Response:
   - Annotated image (URL or base64)
   - Structured detection metadata
```

---

# 3. API Design

## 3.1 Endpoint

```
POST /api/v1/object-detection
```

### Request Body (JSON)

```json
{
  "image_url": "https://example.com/uploads/room.jpg"
}
```

### Response Body (JSON)

```json
{
  "image": {
    "original_url": "https://example.com/uploads/room.jpg",
    "annotated_image_url": "https://cdn.example.com/annotated/room_123.png"
  },
  "summary": {
    "total_objects": 7,
    "categories": {
      "furniture": 5,
      "people": 1,
      "electronics": 1
    }
  },
  "objects": [
    {
      "id": "obj_1",
      "label": "Chair",
      "category": "furniture",
      "confidence": 0.92,
      "bounding_box": {
        "x_min": 0.12,
        "y_min": 0.45,
        "x_max": 0.30,
        "y_max": 0.78
      },
      "thumbnail_crop": {
        "x": 320,
        "y": 780,
        "width": 420,
        "height": 610
      }
    }
  ]
}
```

---

# 4. Object Detection Strategy (Google Vision)

## 4.1 Google Vision Features Used

Use **OBJECT_LOCALIZATION** only.

Reason:

* Returns object name
* Confidence score
* Normalized bounding box coordinates

### API Call

```json
{
  "requests": [
    {
      "image": { "source": { "imageUri": "<IMAGE_URL>" } },
      "features": [{ "type": "OBJECT_LOCALIZATION" }]
    }
  ]
}
```

---

# 5. Object Grouping (Critical Requirement)

Google Vision **does not return categories** (furniture, people, etc.).
You must implement **your own taxonomy layer**.

## 5.1 Category Taxonomy (Initial Version)

```yaml
furniture:
  - Chair
  - Table
  - Sofa
  - Couch
  - Bed
  - Desk
  - Cabinet
  - Shelf

people:
  - Person

vehicle:
  - Car
  - Truck
  - Bicycle
  - Motorcycle

electronics:
  - Television
  - Laptop
  - Computer
  - Monitor
  - Phone

appliance:
  - Refrigerator
  - Microwave
  - Oven
  - Washing machine
```

## 5.2 Categorization Rule

```
IF object.name ∈ category list → assign category
ELSE → category = "other"
```

This mapping must be:

* Configurable
* Stored as YAML / JSON
* Loaded at runtime

---

# 6. Bounding Box Normalization & Cropping

## 6.1 Input from Google Vision

Google returns **normalized coordinates** (0 → 1).

Example:

```json
{
  "x": 0.12,
  "y": 0.45
}
```

## 6.2 Convert to Pixel Coordinates

```
pixel_x = normalized_x * image_width
pixel_y = normalized_y * image_height
```

These pixel values are required for:

* Drawing bounding boxes
* Cropping thumbnails later

---

# 7. Annotated Image Generation

## 7.1 Requirements

* Draw:

  * Rectangle bounding box
  * Label text: `"<Label> (92%)"`
* Preserve original image ratio
* Save annotated image to:

  * Local storage OR
  * Object storage (S3 / GCS / CDN)

## 7.2 Output

Return:

* Public URL of annotated image
* Do **not** embed base64 unless explicitly required

---

# 8. Error Handling

| Scenario            | Response              |
| ------------------- | --------------------- |
| Invalid image URL   | 400 Bad Request       |
| Vision API failure  | 502 Bad Gateway       |
| No objects detected | 200 OK + empty list   |
| Image too large     | 413 Payload Too Large |

---

# 9. Security & Cost Control

* Enforce:

  * Max image size (e.g. 10MB)
  * Rate limiting per IP
* Cache results by image hash to reduce Vision API calls
* Strip EXIF metadata before storing images

---

# 10. Step-by-Step Instructions for Cursor (AI Agent)

> **This section is written exactly as you should paste into Cursor.**

---

### Step 1: Project Setup

* Create backend service (Rails / Node / Python FastAPI)
* Add environment variable support
* Configure Google Cloud Vision credentials

---

### Step 2: API Endpoint

* Implement `POST /api/v1/object-detection`
* Validate `image_url`
* Download image temporarily

---

### Step 3: Google Vision Integration

* Call `OBJECT_LOCALIZATION`
* Parse:

  * object name
  * confidence
  * bounding polygon

---

### Step 4: Object Categorization

* Load taxonomy config file
* Map object labels → categories
* Default to `"other"`

---

### Step 5: Coordinate Processing

* Load image dimensions
* Convert normalized bounding boxes → pixel coordinates
* Store both normalized & pixel values

---

### Step 6: Annotated Image Rendering

* Draw bounding boxes + labels
* Save annotated image
* Return public URL

---

### Step 7: API Response Assembly

* Group objects by category
* Return:

  * annotated image URL
  * object metadata list
  * category summary

---

### Step 8: Testing

* Test with:

  * Living room photo
  * Office photo
  * No-object image

---

# 11. Extension Points (Future-Ready)

* Replace Vision API with:

  * Custom YOLO model
  * Furniture-specific detector
* Add:

  * Room classification
  * Dominant furniture detection
  * Thumbnail extraction API

---

## Final Note

This design is:

* Production-grade
* Vendor-lock-in minimized
* Fully compatible with Google Vision free trial

If you want next:

* **Rails-specific implementation**
* **Cursor prompt that generates all code**
* **Database schema for storing detections**

Tell me which one to proceed with.
