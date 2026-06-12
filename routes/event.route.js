const express = require("express");
const { ingestEvents } = require("../controllers/event.controller");
const { authenticateToken } = require("../middlewares/auth.middleware");

const router = express.Router();

router.post("/", authenticateToken, ingestEvents);

module.exports = router;
