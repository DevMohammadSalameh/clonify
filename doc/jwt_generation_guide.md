# JWT Generation for App Store Connect

1. Create a JWT header:
   {
     "alg": "ES256",
     "kid": "<YOUR_KEY_ID>",
     "typ": "JWT"
   }

2. Create a JWT payload:
   {
     "iss": "<YOUR_ISSUER_ID>",
     "iat": <UNIX_TIMESTAMP_CREATION>,
     "exp": <UNIX_TIMESTAMP_EXPIRATION>,
     "aud": "appstoreconnect-v1"
   }

3. Sign the token using your '.p8' private key and ES256 algorithm.

4. Send the token in the Authorization header as:
   Authorization: Bearer <SIGNED_JWT>

See Apple's documentation for more details on generating and signing ES256 tokens.
