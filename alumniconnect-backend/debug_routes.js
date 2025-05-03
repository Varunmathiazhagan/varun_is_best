const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// Get MongoDB connection status
router.get('/db-status', async (req, res) => {
  try {
    // Check connection state
    const connectionState = mongoose.connection.readyState;
    const stateMap = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting'
    };
    
    // Run a simple command to verify database access
    const dbInfo = await mongoose.connection.db.admin().serverInfo();
    
    res.status(200).json({
      status: 'success',
      connection: {
        state: stateMap[connectionState] || 'unknown',
        readyState: connectionState
      },
      dbInfo: {
        version: dbInfo.version,
        engine: dbInfo.storageEngine?.name || 'unknown'
      }
    });
  } catch (error) {
    console.error('DB Status Error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get database status',
      error: error.message
    });
  }
});

// List all collections
router.get('/collections', async (req, res) => {
  try {
    const collections = await mongoose.connection.db.listCollections().toArray();
    const collectionNames = collections.map(c => c.name);
    
    res.status(200).json({
      status: 'success',
      collections: collectionNames
    });
  } catch (error) {
    console.error('List Collections Error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to list collections',
      error: error.message
    });
  }
});

// Test create event API
router.post('/test-event', async (req, res) => {
  try {
    // Get Event model from mongoose
    const Event = mongoose.model('Event');
    
    // Create a simple test event
    const event = new Event({
      name: 'Test Event ' + new Date().toISOString(),
      startDate: new Date(),
      description: 'This is a test event created via the debug API',
      startTime: '09:00'
    });
    
    // Save to database
    const savedEvent = await event.save();
    
    res.status(200).json({
      status: 'success',
      message: 'Test event created successfully',
      event: savedEvent
    });
  } catch (error) {
    console.error('Test Event Error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to create test event',
      error: error.message
    });
  }
});

module.exports = router;
