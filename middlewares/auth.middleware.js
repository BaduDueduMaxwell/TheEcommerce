const jwt = require("jsonwebtoken");

const authenticateToken = (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];

  if (!token) {
    return res
      .status(401)
      .json({ message: "Access denied. No token provided." });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    console.error("Token verification error:", error.message);
    res.status(403).json({ message: "Invalid or expired token" });
  }
};

const authorizeRole = (requiredRoles) => {
  return (req, res, next) => {
    if (!requiredRoles.includes(req.user.role)) {
      return res.status(403).json({
        message: "Access denied. You do not have the required permissions.",
      });
    }
    next();
  };
};

module.exports = { authenticateToken, authorizeRole };
