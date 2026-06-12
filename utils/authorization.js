const hasRequiredRole = (userRole, requiredRoles) => {
  const roles = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
  return roles.includes(userRole);
};

const canAccessUserResource = ({
  authenticatedUserId,
  requestedUserId,
  role,
}) => {
  return role === "admin" || authenticatedUserId === requestedUserId;
};

module.exports = { hasRequiredRole, canAccessUserResource };
