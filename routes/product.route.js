const express = require("express");
const router = express.Router();
const {
  getProducts,
  getProduct,
  addProduct,
  updateProduct,
  deleteProduct,
  deleteAllProducts,
} = require("../controllers/product.controller");
const {
  authenticateToken,
  authorizeRole,
} = require("../middlewares/auth.middleware");

// Public
router.get("/", getProducts);
router.get("/:productId", getProduct);

// Protected Routes
router.post("/", authenticateToken, authorizeRole("admin"), addProduct);
router.put(
  "/:productId",
  authenticateToken,
  authorizeRole("admin"),
  updateProduct
);
router.delete(
  "/delete-all",
  authenticateToken,
  authorizeRole("admin"),
  deleteAllProducts
);
router.delete(
  "/:productId",
  authenticateToken,
  authorizeRole("admin"),
  deleteProduct
);

module.exports = router;
