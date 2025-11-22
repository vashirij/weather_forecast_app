Weather Notification Cloud Function

This small Cloud Function provides a secure endpoint the mobile client can call to request FCM sends without exposing server credentials.

Setup
1. Install Firebase CLI and login: https://firebase.google.com/docs/cli
2. In this functions directory run:
   npm install
3. Set a secret for the function:
   firebase functions:config:set weather.secret="your_shared_secret_here"
4. Deploy the function:
   firebase deploy --only functions

Usage
- Endpoint URL (deployed): https://<region>-<project>.cloudfunctions.net/app/send
- Client must include header 'x-weather-secret' with the shared secret.
- Request JSON body:
  {
    "title": "Storm Warning",
    "body": "Severe storms expected in your area",
    "topic": "weather_alerts", // or token: "<device-token>"
    "data": {"type":"storm","severity":"high"}
  }
- The function validates the secret and sends via FCM using the Admin SDK.

Security notes
- Keep the shared secret private.
- For production use consider stricter auth (e.g., App Check, OAuth2, or verifying user identity).
