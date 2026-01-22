# Step-by-Step Instructions for Cursor (AI Agent)

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
