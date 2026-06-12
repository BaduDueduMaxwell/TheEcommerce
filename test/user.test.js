const test = require("node:test");
const assert = require("node:assert/strict");

const { toPublicUser } = require("../utils/user");

test("toPublicUser removes password data without mutating input", () => {
  const user = {
    _id: "user-1",
    email: "maxwell@example.com",
    password: "hashed-password",
  };

  const result = toPublicUser(user);

  assert.equal(result.password, undefined);
  assert.equal(user.password, "hashed-password");
  assert.equal(result.email, user.email);
});
