```markdown
# TheEcommerce

API for TheEcommerce App

## Table of Contents
- [Project Overview](#project-overview)
- [Installation](#installation)
- [Usage](#usage)
- [Routes](#routes)
- [Contributing](#contributing)
- [License](#license)

## Project Overview

TheEcommerce API provides backend functionalities for an e-commerce application. It includes user authentication, product management, cart management, order processing, and payment handling.

## Installation

To install and run the project locally, follow these steps:

1. Clone the repository
   ```bash
   git clone https://github.com/BaduDueduMaxwell/TheEcommerce.git
   cd TheEcommerce
   ```
2. Install dependencies
   ```bash
   npm install
   ```

## Usage

To start the server, run:
```bash
npm run serve
```

For development, use:
```bash
npm run dev
```

## Routes

### Products
- `GET /api/products`: Retrieve all products
- `GET /api/products/:productId`: Retrieve a single product
- `POST /api/products`: Add a new product (admin only)
- `PUT /api/products/:productId`: Update a product (admin only)
- `DELETE /api/products/:productId`: Delete a product (admin only)
- `DELETE /api/products/delete-all`: Delete all products (admin only)

### Users
- `POST /api/users/signup`: Sign up a new user
- `POST /api/users/login`: Log in a user
- `GET /api/users`: Retrieve all users (admin only)
- `GET /api/users/:userId`: Retrieve a single user
- `PUT /api/users/:userId`: Update a user
- `DELETE /api/users/:userId`: Delete a user (admin only)

### Cart
- `GET /api/cart/:userId`: Retrieve a user's cart
- `POST /api/cart`: Add to a user's cart
- `PUT /api/cart/:userId`: Update a user's cart
- `DELETE /api/cart/:userId`: Delete all items from a user's cart
- `DELETE /api/cart/:userId/:productId`: Delete a specific product from a user's cart

### Orders
- `GET /api/orders/my-orders/:userId`: Retrieve user's orders
- `POST /api/orders/place-order`: Place a new order
- `GET /api/orders`: Retrieve all orders (admin only)
- `PUT /api/orders/:orderId/status`: Update order status (admin only)
- `DELETE /api/orders/:orderId`: Delete an order

### Payments
- `POST /api/payment`: Initialize payment
- `GET /api/payment/verify/:reference`: Verify payment
- `POST /api/payment/webhook`: Handle payment webhook

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the ISC License.
```

You can now [create the README.md file](https://github.com/BaduDueduMaxwell/TheEcommerce/new/master?filename=README.md) and paste this content into it.
