# Fastlane Apple API Key Instructions

Your api_key_path should point to a JSON file in the format:
{
  "key_id": "ABC123XYZ",
  "issuer_id": "11223344-5566-7788-9900-aabbccddeeff",
  "key": "-----BEGIN PRIVATE KEY-----\nMIGH...\n-----END PRIVATE KEY-----",
  "in_house": false
}

Set the APPSTORE_API_KEY_PATH environment variable to the path of this JSON file.
