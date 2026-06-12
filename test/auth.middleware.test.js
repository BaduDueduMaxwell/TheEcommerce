const test = require("node:test");
const assert = require("node:assert/strict");

const {
  hasRequiredRole,
  canAccessUserResource,
} = require("../utils/authorization");

test("authorizeRole accepts either a single role or a list", () => {
  assert.equal(hasRequiredRole("admin", "admin"), true);
  assert.equal(hasRequiredRole("admin", ["admin"]), true);
  assert.equal(hasRequiredRole("user", ["admin"]), false);
});

test("authorizeSelfOrAdmin blocks another user's resource", () => {
  assert.equal(
    canAccessUserResource({
      authenticatedUserId: "user-1",
      requestedUserId: "user-2",
      role: "user",
    }),
    false
  );
});

test("authorizeSelfOrAdmin allows resource owners and admins", () => {
  assert.equal(
    canAccessUserResource({
      authenticatedUserId: "user-1",
      requestedUserId: "user-1",
      role: "user",
    }),
    true
  );
  assert.equal(
    canAccessUserResource({
      authenticatedUserId: "admin-1",
      requestedUserId: "user-2",
      role: "admin",
    }),
    true
  );
});
