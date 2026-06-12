const Event = require("../models/event.model");

const ingestEvents = async (req, res) => {
  try {
    const events = req.body.events;

    if (!Array.isArray(events) || events.length === 0 || events.length > 100) {
      return res.status(400).json({
        message: "events must contain between 1 and 100 items",
      });
    }

    const invalidEvent = events.some(
      (event) =>
        !event.eventId ||
        !event.name ||
        !event.occurredAt ||
        Number.isNaN(Date.parse(event.occurredAt))
    );

    if (invalidEvent) {
      return res.status(400).json({
        message: "Each event requires eventId, name, and occurredAt",
      });
    }

    const operations = events.map((event) => ({
      updateOne: {
        filter: { eventId: event.eventId },
        update: {
          $setOnInsert: {
            eventId: event.eventId,
            name: event.name,
            userId: req.user.userId,
            properties: event.properties || {},
            occurredAt: new Date(event.occurredAt),
            platform: event.platform,
            appVersion: event.appVersion,
          },
        },
        upsert: true,
      },
    }));

    const result = await Event.bulkWrite(operations, { ordered: false });

    res.status(202).json({
      accepted: events.length,
      inserted: result.upsertedCount,
      duplicates: events.length - result.upsertedCount,
    });
  } catch (error) {
    res.status(500).json({
      message: "Failed to ingest events",
      error: error.message,
    });
  }
};

module.exports = { ingestEvents };
