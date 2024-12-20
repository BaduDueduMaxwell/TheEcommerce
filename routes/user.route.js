const express = require("express");
const router = express.Router();
const {
  getUsers,
  getUser,
  addUser,
  loginUser,
  updateUser,
  deleteUser,
} = require("../controllers/user.controller");
const {
  authenticateToken,
  authorizeRole,
} = require("../middlewares/auth.middleware");

// Public Routes
router.post("/signup", addUser);
router.post("/login", loginUser);

// Protected Routes (Require Authentication)
router.get("/", authenticateToken, authorizeRole("admin"), getUsers);
router.get("/:userId", authenticateToken, getUser);
router.put("/:userId", authenticateToken, updateUser);
router.delete(
  "/:userId",
  authenticateToken,
  authorizeRole(["admin"]),
  deleteUser
);

module.exports = router;
