const express = require('express');
const router = express.Router();
router.post('/verify', (req, res) => res.json({ status: 'ok', message: 'Auth service running' }));
module.exports = router;
