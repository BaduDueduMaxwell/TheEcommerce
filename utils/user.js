const toPublicUser = (user) => {
  if (!user) {
    return user;
  }

  const value =
    typeof user.toObject === "function" ? user.toObject() : { ...user };
  delete value.password;
  return value;
};

module.exports = { toPublicUser };
