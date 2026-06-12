require("dotenv").config();

const mongoose = require("mongoose");
const Product = require("../models/product.model");

const products = [
  {
    name: "AeroRun Daily Trainers",
    description:
      "Lightweight everyday running shoes with breathable mesh and responsive cushioning.",
    price: 620,
    stock: 24,
    category: "Footwear",
    imageURL:
      "https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "City Leather Sneakers",
    description:
      "Minimal leather sneakers designed for comfortable commutes and smart casual outfits.",
    price: 780,
    stock: 16,
    category: "Footwear",
    imageURL:
      "https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Studio Wireless Headphones",
    description:
      "Over-ear wireless headphones with rich sound, soft memory foam, and all-day battery life.",
    price: 1150,
    stock: 18,
    category: "Electronics",
    imageURL:
      "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Pocket Bluetooth Speaker",
    description:
      "Water-resistant portable speaker with clear audio and twelve hours of playback.",
    price: 430,
    stock: 31,
    category: "Electronics",
    imageURL:
      "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Everyday Canvas Backpack",
    description:
      "Durable canvas backpack with a padded laptop sleeve and organized interior pockets.",
    price: 390,
    stock: 22,
    category: "Bags",
    imageURL:
      "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Structured Work Tote",
    description:
      "Spacious structured tote with secure zip closure and room for a thirteen-inch laptop.",
    price: 560,
    stock: 13,
    category: "Bags",
    imageURL:
      "https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Classic Steel Watch",
    description:
      "Clean stainless-steel watch with a timeless dial and water-resistant construction.",
    price: 890,
    stock: 11,
    category: "Accessories",
    imageURL:
      "https://images.unsplash.com/photo-1524592094714-0f0654e20314?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Polarized City Sunglasses",
    description:
      "Lightweight polarized sunglasses that reduce glare while keeping a modern silhouette.",
    price: 280,
    stock: 29,
    category: "Accessories",
    imageURL:
      "https://images.unsplash.com/photo-1511499767150-a48a237f0083?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Organic Cotton Hoodie",
    description:
      "Midweight organic cotton hoodie with a relaxed fit and soft brushed interior.",
    price: 510,
    stock: 20,
    category: "Apparel",
    imageURL:
      "https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Essential Crew T-Shirt",
    description:
      "Premium cotton crew-neck T-shirt cut for an easy fit and reliable everyday wear.",
    price: 190,
    stock: 42,
    category: "Apparel",
    imageURL:
      "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Ceramic Pour-Over Set",
    description:
      "Hand-finished ceramic dripper and carafe set for a balanced home coffee ritual.",
    price: 340,
    stock: 15,
    category: "Home",
    imageURL:
      "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80",
  },
  {
    name: "Warm Glow Desk Lamp",
    description:
      "Adjustable metal desk lamp with warm LED lighting for focused work and reading.",
    price: 470,
    stock: 17,
    category: "Home",
    imageURL:
      "https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=1200&q=80",
  },
];

const seedProducts = async () => {
  if (!process.env.MONGODB_URI) {
    throw new Error("MONGODB_URI is required");
  }

  await mongoose.connect(process.env.MONGODB_URI);
  const result = await Product.bulkWrite(
    products.map((product) => ({
      updateOne: {
        filter: { name: product.name },
        update: { $set: product },
        upsert: true,
      },
    }))
  );

  console.log(
    `Seed complete: ${result.upsertedCount} inserted, ${result.modifiedCount} updated.`
  );
};

seedProducts()
  .catch((error) => {
    console.error("Product seed failed:", error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
