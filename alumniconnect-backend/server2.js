const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware setup
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// Google Generative AI Setup
const API_KEY = 'AIzaSyC5evONEf7yvprota23Mqm0lt014jVg5sA';
const genAI = new GoogleGenerativeAI(API_KEY);

// System prompt for context
const SYSTEM_PROMPT = `You are an AI assistant for AlumniConnect, a platform that connects alumni from educational institutions. 
Help users with questions about finding mentors, job opportunities, networking, and other alumni-related activities.

The platform has these main features:
1. Alumni Directory: Search and connect with alumni based on industry, location, graduation year, etc.
2. Mentorship Program: Connect students with alumni mentors for career guidance.
3. Job Board: Browse job and internship opportunities posted by alumni and companies.
4. Events Calendar: View and register for alumni networking events, webinars, and reunions.
5. Discussion Forum: Participate in conversations on various topics.
6. Profile Management: Update personal and professional information.

When answering questions:
- Be concise, friendly, and helpful in your responses.
- Direct users to the appropriate section of the app for their needs.
- Provide actionable next steps when possible.
- If you don't know an answer, suggest where they might find the information.`;

// Root endpoint
app.get('/', (req, res) => {
  res.send('AlumniConnect Chatbot Server is running!');
});

// Chatbot Endpoint
app.post('/chat', async (req, res) => {
  const userMessage = req.body.message;
  if (userMessage) {
    try {
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
      
      // Create a chat session with system prompt
      const chat = model.startChat({
        history: [
          { role: "user", parts: [{ text: "Who are you?" }] },
          { role: "model", parts: [{ text: SYSTEM_PROMPT }] },
        ],
      });
      
      // Send user message and get response
      const result = await chat.sendMessage(userMessage);
      const reply = result.response.text();
      res.json({ reply });
    } catch (error) {
      console.error("Error:", error);
      res.status(500).json({ error: "An error occurred while processing your request." });
    }
  } else {
    res.status(400).json({ error: "No message provided." });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Chatbot Server is running on port ${PORT}`);
});
