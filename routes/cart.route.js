const express = require("express");
const router = express.Router();
const {
  getUserCart,
  addUserCart,
  updateUserCart,
  deleteProductFromCart,
  deleteProductsFromCart,
} = require("../controllers/cart.controller");
const { authenticateToken } = require("../middlewares/auth.middleware");

router.get("/:userId", authenticateToken, getUserCart);
router.post("/", authenticateToken, addUserCart);
router.put("/:userId", authenticateToken, updateUserCart);
router.delete("/:userId", authenticateToken, deleteProductsFromCart);
router.delete("/:userId/:productId", authenticateToken, deleteProductFromCart);

module.exports = router;
