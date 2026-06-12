const test = require("node:test");
const assert = require("node:assert/strict");
const {
  escapeRegExp,
  parseProductQuery,
  validateProductInput,
} = require("../utils/product");
const {
  createProductHandlers,
} = require("../controllers/product.controller");

const validProduct = {
  name: "Studio Headphones",
  description: "Comfortable wireless headphones with clear studio sound.",
  price: 950,
  stock: 12,
  category: "Electronics",
  imageURL: "https://example.com/headphones.jpg",
};

const createResponse = () => {
  const response = {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
  };
  return response;
};

test("product validation rejects invalid price, stock, and image URL", () => {
  const { errors } = validateProductInput({
    ...validProduct,
    price: -1,
    stock: 1.5,
    imageURL: "not-a-url",
  });

  assert.equal(errors.price, "Price must be a number greater than or equal to 0");
  assert.match(errors.stock, /whole number/);
  assert.match(errors.imageURL, /valid HTTP/);
});

test("product query parsing bounds pagination and selects supported sorting", () => {
  const query = parseProductQuery({
    page: "-4",
    limit: "500",
    search: "  shoe ",
    category: " Footwear ",
    sort: "price_desc",
  });

  assert.equal(query.page, 1);
  assert.equal(query.limit, 50);
  assert.equal(query.search, "shoe");
  assert.equal(query.category, "Footwear");
  assert.deepEqual(query.sort, { price: -1 });
  assert.equal(escapeRegExp("lamp (sale)"), "lamp \\(sale\\)");
});

test("create product returns a validated product with 201", async () => {
  let received;
  const handlers = createProductHandlers({
    create: async (product) => {
      received = product;
      return { _id: "product-1", ...product };
    },
  });
  const response = createResponse();

  await handlers.addProduct({ body: validProduct }, response);

  assert.equal(response.statusCode, 201);
  assert.equal(response.body._id, "product-1");
  assert.deepEqual(received, validProduct);
});

test("create product returns structured validation errors", async () => {
  const handlers = createProductHandlers({
    create: async () => {
      throw new Error("create should not be called");
    },
  });
  const response = createResponse();

  await handlers.addProduct({ body: { name: "A" } }, response);

  assert.equal(response.statusCode, 400);
  assert.equal(response.body.error.code, "PRODUCT_VALIDATION_FAILED");
  assert.ok(response.body.error.details.description);
});

test("delete product reports missing products consistently", async () => {
  const handlers = createProductHandlers({
    findByIdAndDelete: async () => null,
  });
  const response = createResponse();

  await handlers.deleteProduct(
    { params: { productId: "507f1f77bcf86cd799439011" } },
    response
  );

  assert.equal(response.statusCode, 404);
  assert.equal(response.body.error.code, "PRODUCT_NOT_FOUND");
});
