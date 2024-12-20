const Payment = require("../models/payment.model");

// Add or Create payment
const addPayment = async (req, res) => {
  try {
    const payment = await Payment.create(req.body);
    res.status(201).json(payment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Fetch payment status for a specific order
const getAllPayment = async (req, res) => {
  try {
    const payment = await Payment.find({});
    res.status(200).json(payment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Fetch payment status for a specific order
const getSpecificOrderPayment = async (req, res) => {
  try {
    const { id } = req.params;
    const payment = await Payment.findById(id);
    res.status(200).json(payment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  addPayment,
  getAllPayment,
  getSpecificOrderPayment,
};
