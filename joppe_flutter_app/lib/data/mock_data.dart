import '../models/product.dart';

final List<Product> mockProducts = [
  const Product(
    id: '1',
    name: 'Wireless Headphones',
    description: 'High-quality wireless headphones with noise cancellation.',
    price: 199.99,
    imageUrl: 'https://picsum.photos/seed/headphones/400/400',
  ),
  const Product(
    id: '2',
    name: 'Smart Watch',
    description: 'Track your fitness and stay connected.',
    price: 249.50,
    imageUrl: 'https://picsum.photos/seed/watch/400/400',
  ),
  const Product(
    id: '3',
    name: 'Mechanical Keyboard',
    description: 'RGB mechanical keyboard with tactile switches.',
    price: 129.00,
    imageUrl: 'https://picsum.photos/seed/keyboard/400/400',
  ),
  const Product(
    id: '4',
    name: 'Gaming Mouse',
    description: 'Ergonomic gaming mouse with adjustable DPI.',
    price: 59.99,
    imageUrl: 'https://picsum.photos/seed/mouse/400/400',
  ),
];
