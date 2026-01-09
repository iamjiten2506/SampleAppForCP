const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Main endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from CI/CD Demo App!',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'production'
  });
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
});

module.exports = app;