const mongoose = require("mongoose");

const ProductSchema = mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Please enter product name"],
      trim: true,
      minlength: [2, "Product name must contain at least 2 characters"],
      maxlength: [100, "Product name cannot exceed 100 characters"],
    },
    description: {
      type: String,
      required: [true, "Please enter product description"],
      trim: true,
      minlength: [10, "Product description must contain at least 10 characters"],
      maxlength: [1000, "Product description cannot exceed 1000 characters"],
    },
    stock: {
      type: Number,
      required: true,
      default: 0,
      min: [0, "Stock must be greater than or equal to 0"],
      validate: {
        validator: Number.isInteger,
        message: "Stock must be a whole number",
      },
    },
    imageURL: {
      type: String,
      required: [true, "Please enter a product image URL"],
      trim: true,
    },
    category: {
      type: String,
      required: [true, "Please enter a product category"],
      trim: true,
      maxlength: [50, "Category cannot exceed 50 characters"],
    },
    price: {
      type: Number,
      required: [true, "Please enter product price"],
      min: [0, "Price must be greater than or equal to 0"],
    },
  },
  {
    timestamps: true,
  }
);

ProductSchema.index({ name: "text", description: "text", category: "text" });
ProductSchema.index({ category: 1, createdAt: -1 });

const Product = mongoose.model("Product", ProductSchema);

module.exports = Product;
