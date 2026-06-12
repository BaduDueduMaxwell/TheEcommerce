const PRODUCT_FIELDS = [
  "name",
  "description",
  "price",
  "stock",
  "category",
  "imageURL",
];

const escapeRegExp = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const isHttpUrl = (value) => {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
};

const validateProductInput = (input, { partial = false } = {}) => {
  const product = Object.fromEntries(
    Object.entries(input || {}).filter(([key]) => PRODUCT_FIELDS.includes(key))
  );
  const errors = {};

  for (const field of PRODUCT_FIELDS) {
    if (!partial && (product[field] === undefined || product[field] === "")) {
      errors[field] = `${field} is required`;
    }
  }

  if (product.name !== undefined) {
    product.name = String(product.name).trim();
    if (product.name.length < 2 || product.name.length > 100) {
      errors.name = "Name must contain between 2 and 100 characters";
    }
  }

  if (product.description !== undefined) {
    product.description = String(product.description).trim();
    if (
      product.description.length < 10 ||
      product.description.length > 1000
    ) {
      errors.description =
        "Description must contain between 10 and 1000 characters";
    }
  }

  if (product.category !== undefined) {
    product.category = String(product.category).trim();
    if (!product.category || product.category.length > 50) {
      errors.category = "Category must contain between 1 and 50 characters";
    }
  }

  if (product.imageURL !== undefined) {
    product.imageURL = String(product.imageURL).trim();
    if (!isHttpUrl(product.imageURL)) {
      errors.imageURL = "Image URL must be a valid HTTP or HTTPS URL";
    }
  }

  if (product.price !== undefined) {
    product.price = Number(product.price);
    if (!Number.isFinite(product.price) || product.price < 0) {
      errors.price = "Price must be a number greater than or equal to 0";
    }
  }

  if (product.stock !== undefined) {
    product.stock = Number(product.stock);
    if (!Number.isInteger(product.stock) || product.stock < 0) {
      errors.stock = "Stock must be a whole number greater than or equal to 0";
    }
  }

  if (partial && Object.keys(product).length === 0) {
    errors.product = "Provide at least one supported product field";
  }

  return { product, errors };
};

const parseProductQuery = (query = {}) => {
  const page = Math.max(Number.parseInt(query.page, 10) || 1, 1);
  const limit = Math.min(
    Math.max(Number.parseInt(query.limit, 10) || 12, 1),
    50
  );
  const search = String(query.search || "").trim().slice(0, 100);
  const category = String(query.category || "").trim().slice(0, 50);
  const sortOptions = {
    newest: { createdAt: -1 },
    name: { name: 1 },
    price_asc: { price: 1 },
    price_desc: { price: -1 },
    stock_desc: { stock: -1 },
  };
  const sortKey = Object.hasOwn(sortOptions, query.sort)
    ? query.sort
    : "newest";

  return {
    page,
    limit,
    search,
    category,
    sortKey,
    sort: sortOptions[sortKey],
  };
};

module.exports = {
  PRODUCT_FIELDS,
  escapeRegExp,
  parseProductQuery,
  validateProductInput,
};
