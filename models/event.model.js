const mongoose = require("mongoose");

const eventSchema = new mongoose.Schema(
  {
    eventId: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    properties: { type: mongoose.Schema.Types.Mixed, default: {} },
    occurredAt: { type: Date, required: true },
    platform: { type: String, trim: true },
    appVersion: { type: String, trim: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Event", eventSchema);
