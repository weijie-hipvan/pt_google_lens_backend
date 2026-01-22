# Google Cloud Vision API Setup Guide

This guide will walk you through setting up Google Cloud Vision API credentials for the Object Detection API.

---

## Prerequisites

- A Google account (Gmail account works)
- Access to Google Cloud Console

---

## Step 1: Create a Google Cloud Project

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create a New Project**
   - Click on the project dropdown at the top (next to "Google Cloud")
   - Click "New Project"
   - Enter project name: `pt-google-lens-backend` (or any name you prefer)
   - Click "Create"
   - Wait for the project to be created (usually takes a few seconds)

3. **Select Your Project**
   - Make sure your new project is selected in the project dropdown

---

## Step 2: Enable Google Cloud Vision API

1. **Navigate to APIs & Services**
   - In the left sidebar, click "APIs & Services" → "Library"
   - Or visit: https://console.cloud.google.com/apis/library

2. **Search for Vision API**
   - In the search bar, type: "Cloud Vision API"
   - Click on "Cloud Vision API" from the results

3. **Enable the API**
   - Click the "Enable" button
   - Wait for the API to be enabled (usually takes 10-30 seconds)

---

## Step 3: Create a Service Account

1. **Navigate to Service Accounts**
   - In the left sidebar, go to "APIs & Services" → "Credentials"
   - Or visit: https://console.cloud.google.com/apis/credentials

2. **Create Service Account**
   - Click "Create Credentials" at the top
   - Select "Service account" from the dropdown

3. **Fill in Service Account Details**
   - **Service account name**: `vision-api-service` (or any name)
   - **Service account ID**: Will auto-populate (you can change it)
   - **Description**: "Service account for Vision API object detection"
   - Click "Create and Continue"

4. **Grant Role (Optional but Recommended)**
   - In "Grant this service account access to project":
   - Select role: "Cloud Vision API User" (or "Editor" for broader access)
   - Click "Continue"

5. **Skip User Access (Optional)**
   - You can skip "Grant users access to this service account"
   - Click "Done"

---

## Step 4: Create and Download Service Account Key

1. **Find Your Service Account**
   - You should see your service account in the list
   - Click on the service account email (e.g., `vision-api-service@your-project.iam.gserviceaccount.com`)

2. **Create Key**
   - Go to the "Keys" tab
   - Click "Add Key" → "Create new key"

3. **Select Key Type**
   - Choose "JSON" format
   - Click "Create"

4. **Download the JSON File**
   - The JSON file will automatically download to your computer
   - **IMPORTANT**: Save this file securely! It contains credentials that allow access to your Google Cloud project.
   - The file will be named something like: `your-project-abc123def456.json`

---

## Step 5: Configure Your Rails Application

### Option 1: Environment Variable (Recommended for Development)

1. **Move the JSON file to your project**
   ```bash
   # Create a credentials directory (optional, for organization)
   mkdir -p config/credentials
   
   # Move the downloaded JSON file
   mv ~/Downloads/your-project-abc123def456.json config/credentials/google-vision-service-account.json
   ```

2. **Add to .env file**
   ```bash
   # Add this line to your .env file
   echo "GOOGLE_APPLICATION_CREDENTIALS=config/credentials/google-vision-service-account.json" >> .env
   ```

3. **Update .gitignore** (if not already there)
   ```bash
   # Make sure credentials are not committed
   echo "config/credentials/*.json" >> .gitignore
   ```

### Option 2: Absolute Path

1. **Set environment variable directly**
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=/full/path/to/your-project-abc123def456.json
   ```

2. **Or add to your shell profile** (`~/.zshrc` or `~/.bashrc`)
   ```bash
   echo 'export GOOGLE_APPLICATION_CREDENTIALS="/full/path/to/your-project-abc123def456.json"' >> ~/.zshrc
   source ~/.zshrc
   ```

### Option 3: JSON Content in Environment Variable

If you prefer to store the JSON content directly in an environment variable:

1. **Get JSON content**
   ```bash
   cat your-project-abc123def456.json
   ```

2. **Add to .env file**
   ```bash
   # Add the entire JSON as a single line (escape quotes properly)
   GOOGLE_APPLICATION_CREDENTIALS_JSON='{"type":"service_account","project_id":"your-project",...}'
   ```

   Then update `app/services/google_vision_service.rb` to use this:
   ```ruby
   def initialize_client
     require "google/cloud/vision"
     if ENV['GOOGLE_APPLICATION_CREDENTIALS_JSON']
       credentials = JSON.parse(ENV['GOOGLE_APPLICATION_CREDENTIALS_JSON'])
       Google::Cloud::Vision.image_annotator(credentials: credentials)
     else
       Google::Cloud::Vision.image_annotator
     end
   end
   ```

---

## Step 6: Verify Setup

1. **Restart your Rails server**
   ```bash
   # Stop the server (Ctrl+C) and restart
   rails server
   ```

2. **Test the API**
   ```bash
   curl -X POST \
     --header 'Content-Type: application/json' \
     -d '{"image_url":"http://localhost:3000/uploads/your-image.jpg"}' \
     'http://localhost:3000/api/v1/object_detection'
   ```

3. **Check for errors**
   - If you see credentials errors, verify the path is correct
   - If you see API errors, check that Vision API is enabled
   - If you see billing errors, you may need to set up billing (see below)

---

## Step 7: Set Up Billing (Required for Production)

**Note**: Google Cloud Vision API has a free tier, but you still need to add a billing account.

1. **Navigate to Billing**
   - Go to: https://console.cloud.google.com/billing
   - Or: Left sidebar → "Billing"

2. **Link Billing Account**
   - Click "Link a billing account"
   - Create a new billing account or link an existing one
   - Add a payment method (credit card)

3. **Free Tier Limits**
   - First 1,000 requests/month: **FREE**
   - After that: $1.50 per 1,000 requests
   - See: https://cloud.google.com/vision/pricing

---

## Troubleshooting

### Error: "Your credentials were not found"

**Solution:**
- Verify the path in `GOOGLE_APPLICATION_CREDENTIALS` is correct
- Check that the file exists: `ls -la $GOOGLE_APPLICATION_CREDENTIALS`
- Make sure the path is absolute or relative to the Rails root

### Error: "Permission denied"

**Solution:**
- Check that the service account has the "Cloud Vision API User" role
- Verify the JSON file is readable: `chmod 600 your-service-account.json`

### Error: "API not enabled"

**Solution:**
- Go to APIs & Services → Library
- Search for "Cloud Vision API"
- Make sure it's enabled for your project

### Error: "Billing not enabled"

**Solution:**
- Set up billing account (see Step 7)
- Even with free tier, billing account is required

### Error: "Invalid JSON"

**Solution:**
- Verify the JSON file is not corrupted
- Check that it's a valid JSON: `cat your-service-account.json | jq .`
- Make sure you downloaded the complete file

---

## Security Best Practices

1. **Never commit credentials to Git**
   - Add `*.json` to `.gitignore`
   - Add `config/credentials/` to `.gitignore`

2. **Use environment variables**
   - Don't hardcode paths in code
   - Use `.env` file (and add to `.gitignore`)

3. **Restrict service account permissions**
   - Only grant "Cloud Vision API User" role
   - Don't use "Owner" or "Editor" unless necessary

4. **Rotate keys regularly**
   - Delete old keys from Google Cloud Console
   - Generate new keys periodically

5. **Use different credentials for production**
   - Create separate service accounts for dev/staging/prod
   - Use different projects if possible

---

## Service Account JSON File Structure

Your downloaded JSON file will look like this:

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "vision-api-service@your-project.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

**DO NOT** share this file publicly or commit it to version control!

---

## Quick Reference Commands

```bash
# Check if credentials are set
echo $GOOGLE_APPLICATION_CREDENTIALS

# Verify file exists and is readable
ls -la $GOOGLE_APPLICATION_CREDENTIALS

# Test JSON file is valid
cat $GOOGLE_APPLICATION_CREDENTIALS | jq .

# Set credentials (temporary, for current session)
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# Add to .env file (permanent)
echo "GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json" >> .env
```

---

## Additional Resources

- **Google Cloud Vision API Documentation**: https://cloud.google.com/vision/docs
- **Service Accounts Guide**: https://cloud.google.com/iam/docs/service-accounts
- **Pricing Information**: https://cloud.google.com/vision/pricing
- **Free Tier Details**: https://cloud.google.com/free/docs/gcp-free-tier

---

## Summary Checklist

- [ ] Created Google Cloud project
- [ ] Enabled Cloud Vision API
- [ ] Created service account
- [ ] Generated and downloaded JSON key
- [ ] Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable
- [ ] Added credentials to `.gitignore`
- [ ] Restarted Rails server
- [ ] Tested API endpoint
- [ ] Set up billing account (if needed)

---

**Last Updated**: 2026-01-22
