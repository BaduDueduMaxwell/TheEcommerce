const User = require("../models/user.model");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { toPublicUser } = require("../utils/user");

// Fetch all users
const getUsers = async (req, res) => {
  try {
    const users = await User.find({});
    res.status(200).json(users.map(toPublicUser));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Fetch user by id
const getUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    res.status(200).json(toPublicUser(user));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Add User (signup)
const addUser = async (req, res) => {
  try {
    const { username, name, email, password } = req.body;

    if (!username || !name || !email || !password) {
      return res.status(400).json({
        message: "username, name, email, and password are required",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      username,
      name,
      email: normalizedEmail,
      password: hashedPassword,
      role: "user",
    });

    res.status(201).json({
      message: "User created successfully",
      user: toPublicUser(user),
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// User login
const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({
      email: email?.trim().toLowerCase(),
    }).select("+password");
    if (!user) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        userId: user._id,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || "1H" }
    );

    res.status(200).json({
      message: "Login successful",
      token,
      user: toPublicUser(user),
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update User by id
const updateUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const allowedFields = ["username", "name", "email"];
    const updates = Object.fromEntries(
      Object.entries(req.body).filter(([key]) => allowedFields.includes(key))
    );

    if (updates.email) {
      updates.email = updates.email.trim().toLowerCase();
    }

    const updatedUser = await User.findByIdAndUpdate(userId, updates, {
      new: true,
      runValidators: true,
    });

    if (!updatedUser) {
      return res.status(404).json({ message: "User not found" });
    }
    res.status(200).json(toPublicUser(updatedUser));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// delete User by id
const deleteUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByIdAndDelete(userId);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({ message: "User deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getUsers,
  getUser,
  addUser,
  loginUser,
  updateUser,
  deleteUser,
};
