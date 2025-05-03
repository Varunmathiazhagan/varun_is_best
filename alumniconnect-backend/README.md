# AlumniConnect Backend

This folder contains the backend services for the AlumniConnect application.

## Setup

1. Install dependencies:
   ```
   npm install
   ```

2. Start the main server:
   ```
   npm run start
   ```

3. Start the chatbot server:
   ```
   npm run chatbot
   ```

4. Or start both servers concurrently:
   ```
   npm run dev-all
   ```

## Chatbot Service

The chatbot service uses Google's Generative AI (Gemini) to provide intelligent responses to user queries. It runs on port 5000 by default.

### Endpoints:

- `POST /chat`: Send user messages to get AI-generated responses
  - Request body: `{ "message": "your question here" }`
  - Response: `{ "reply": "AI-generated response" }`

## Main API Service

The main API service for AlumniConnect runs on port 3000 by default.

For more details on the main API endpoints, please refer to the API documentation.
