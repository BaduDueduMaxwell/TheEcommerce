const jwt = require("jsonwebtoken");
const {
  hasRequiredRole,
  canAccessUserResource,
} = require("../utils/authorization");

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
    if (!hasRequiredRole(req.user.role, requiredRoles)) {
      return res.status(403).json({
        message: "Access denied. You do not have the required permissions.",
      });
    }
    next();
  };
};

const authorizeSelfOrAdmin = ({
  source = "params",
  field = "userId",
} = {}) => {
  return (req, res, next) => {
    const requestedUserId = req[source]?.[field];
    const authenticatedUserId = req.user?.userId;

    if (
      !requestedUserId ||
      !canAccessUserResource({
        authenticatedUserId,
        requestedUserId,
        role: req.user?.role,
      })
    ) {
      return res.status(403).json({
        message: "Access denied. You can only access your own resources.",
      });
    }

    next();
  };
};

module.exports = {
  authenticateToken,
  authorizeRole,
  authorizeSelfOrAdmin,
};
