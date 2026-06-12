const express = require("express");
const router = express.Router();
const {
  getUserCart,
  addUserCart,
  updateUserCart,
  deleteProductFromCart,
  deleteProductsFromCart,
} = require("../controllers/cart.controller");
const {
  authenticateToken,
  authorizeSelfOrAdmin,
} = require("../middlewares/auth.middleware");

router.get("/:userId", authenticateToken, authorizeSelfOrAdmin(), getUserCart);
router.post(
  "/",
  authenticateToken,
  authorizeSelfOrAdmin({ source: "body" }),
  addUserCart
);
router.put("/:userId", authenticateToken, authorizeSelfOrAdmin(), updateUserCart);
router.delete(
  "/:userId",
  authenticateToken,
  authorizeSelfOrAdmin(),
  deleteProductsFromCart
);
router.delete(
  "/:userId/:productId",
  authenticateToken,
  authorizeSelfOrAdmin(),
  deleteProductFromCart
);

module.exports = router;
