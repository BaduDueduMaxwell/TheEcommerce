const Cart = require("../models/cart.model");

const getUserCart = async (req, res) => {
  try {
    const { id } = req.params;

    const cart = await Cart.findById(id);

    if (!cart) {
      return res.status(404).json({ Message: "Cart not found" });
    }
    res.status(200).json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const addUserCart = async (req, res) => {
  try {
    const cart = await Cart.create(req.body);
    res.status(200).json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateUserCart = async (req, res) => {
  try {
    const { id } = req.params;
    const update = req.body;

    const cart = await Cart.findByIdAndUpdate(id, update, {
      new: true,
      runValidators: true,
    });
    res.status(200).json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteUserCart = async (req, res) => {
  try {
    const { id } = req.params;
    const cartToDelete = req.body;

    const cart = await Cart.findByIdAndDelete(id, cartToDelete);
    res.status(200).json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  addUserCart,
  updateUserCart,
  getUserCart,
  deleteUserCart,
};
