const mongoose = require("mongoose");

const ProductSchema = mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Pleease enter product name"],
    },
    description: {
      type: String,
      required: [true, "Please enter product description"],
    },
    stock: {
      type: Number,
      required: true,
      default: 0,
    },
    imageURL: {
      type: String,
      required: false,
    },
    category: {
      type: String,
      required: false,
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

const Product = mongoose.model("Product", ProductSchema);

module.exports = Product;
