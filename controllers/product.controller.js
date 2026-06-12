const mongoose = require("mongoose");
const Product = require("../models/product.model");
const {
  escapeRegExp,
  parseProductQuery,
  validateProductInput,
} = require("../utils/product");

const sendError = (res, status, code, message, details) =>
  res.status(status).json({
    error: {
      code,
      message,
      ...(details ? { details } : {}),
    },
  });

const handleProductError = (res, error) => {
  if (error.name === "ValidationError") {
    const details = Object.fromEntries(
      Object.entries(error.errors).map(([field, value]) => [
        field,
        value.message,
      ])
    );
    return sendError(
      res,
      400,
      "PRODUCT_VALIDATION_FAILED",
      "Product validation failed",
      details
    );
  }

  console.error("Product request failed:", error);
  return sendError(
    res,
    500,
    "PRODUCT_REQUEST_FAILED",
    "The product request could not be completed"
  );
};

const createProductHandlers = (ProductModel = Product) => {
  const getProducts = async (req, res) => {
    try {
      const { page, limit, search, category, sortKey, sort } =
        parseProductQuery(req.query);
      const escapedSearch = escapeRegExp(search);
      const escapedCategory = escapeRegExp(category);
      const filter = {
        ...(search
          ? {
              $or: [
                { name: { $regex: escapedSearch, $options: "i" } },
                { description: { $regex: escapedSearch, $options: "i" } },
                { category: { $regex: escapedSearch, $options: "i" } },
              ],
            }
          : {}),
        ...(category
          ? { category: { $regex: `^${escapedCategory}$`, $options: "i" } }
          : {}),
      };

      const [items, total, categories] = await Promise.all([
        ProductModel.find(filter)
          .sort(sort)
          .skip((page - 1) * limit)
          .limit(limit)
          .lean(),
        ProductModel.countDocuments(filter),
        ProductModel.distinct("category"),
      ]);

      res.status(200).json({
        items,
        page,
        limit,
        total,
        totalPages: Math.max(Math.ceil(total / limit), 1),
        categories: categories.filter(Boolean).sort(),
        sort: sortKey,
      });
    } catch (error) {
      handleProductError(res, error);
    }
  };

  const getProduct = async (req, res) => {
    try {
      const { productId } = req.params;
      if (!mongoose.Types.ObjectId.isValid(productId)) {
        return sendError(
          res,
          400,
          "INVALID_PRODUCT_ID",
          "Product ID is invalid"
        );
      }

      const product = await ProductModel.findById(productId);
      if (!product) {
        return sendError(
          res,
          404,
          "PRODUCT_NOT_FOUND",
          "Product not found"
        );
      }

      return res.status(200).json(product);
    } catch (error) {
      return handleProductError(res, error);
    }
  };

  const addProduct = async (req, res) => {
    try {
      const { product, errors } = validateProductInput(req.body);
      if (Object.keys(errors).length > 0) {
        return sendError(
          res,
          400,
          "PRODUCT_VALIDATION_FAILED",
          "Product validation failed",
          errors
        );
      }

      const created = await ProductModel.create(product);
      return res.status(201).json(created);
    } catch (error) {
      return handleProductError(res, error);
    }
  };

  const updateProduct = async (req, res) => {
    try {
      const { productId } = req.params;
      if (!mongoose.Types.ObjectId.isValid(productId)) {
        return sendError(
          res,
          400,
          "INVALID_PRODUCT_ID",
          "Product ID is invalid"
        );
      }

      const { product, errors } = validateProductInput(req.body, {
        partial: true,
      });
      if (Object.keys(errors).length > 0) {
        return sendError(
          res,
          400,
          "PRODUCT_VALIDATION_FAILED",
          "Product validation failed",
          errors
        );
      }

      const updated = await ProductModel.findByIdAndUpdate(productId, product, {
        new: true,
        runValidators: true,
      });
      if (!updated) {
        return sendError(
          res,
          404,
          "PRODUCT_NOT_FOUND",
          "Product not found"
        );
      }

      return res.status(200).json(updated);
    } catch (error) {
      return handleProductError(res, error);
    }
  };

  const deleteProduct = async (req, res) => {
    try {
      const { productId } = req.params;
      if (!mongoose.Types.ObjectId.isValid(productId)) {
        return sendError(
          res,
          400,
          "INVALID_PRODUCT_ID",
          "Product ID is invalid"
        );
      }

      const deleted = await ProductModel.findByIdAndDelete(productId);
      if (!deleted) {
        return sendError(
          res,
          404,
          "PRODUCT_NOT_FOUND",
          "Product not found"
        );
      }

      return res.status(200).json({
        message: "Product deleted successfully",
        productId,
      });
    } catch (error) {
      return handleProductError(res, error);
    }
  };

  return { addProduct, deleteProduct, getProduct, getProducts, updateProduct };
};

const handlers = createProductHandlers();

module.exports = {
  ...handlers,
  createProductHandlers,
  handleProductError,
  sendError,
};
