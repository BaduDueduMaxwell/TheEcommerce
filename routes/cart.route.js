const express = require("express");
const router = express.Router();
const {
  getUserCart,
  addUserCart,
  updateUserCart,
  deleteUserCart,
} = require("../controllers/cart.controller");
const { authenticateToken } = require("../middlewares/auth.middleware");

router.get("/", authenticateToken, getUserCart);
router.post("/", authenticateToken, addUserCart);
router.put("/:id", authenticateToken, updateUserCart);
router.delete("/:id", authenticateToken, deleteUserCart);

module.exports = router;
