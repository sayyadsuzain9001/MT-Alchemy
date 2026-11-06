import 'package:flutter/material.dart';

import '../shared/portal_components.dart';
import '../theme.dart';
import '../widgets.dart';
import 'commerce_prototype_store.dart';

final _store = CommercePrototypeStore.instance;

class StorePage extends StatefulWidget {
  const StorePage({super.key});
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String filter = 'All';
  String query = '';

  @override
  Widget build(BuildContext context) => PortalPage(
    title: 'Tools for everyday practice.',
    eyebrow: 'MT Alchemy Store',
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/workshop_group_activity.jpeg',
                fit: BoxFit.cover,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xDD16105B), Color(0x3316105B)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Learning that continues beyond the workshop.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.sizeOf(context).width < 420
                          ? 21
                          : 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: const Text(
                      'Explore practical resources for reflection, communication and team learning.',
                      style: TextStyle(color: Colors.white, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => go(context, '/cart'),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('View cart'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      portalLinks(context),
      const SizedBox(height: 24),
      TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Search products',
        ),
        onChanged: (value) =>
            setState(() => query = value.trim().toLowerCase()),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        children: [
          for (final value in ['All', 'Digital', 'Physical'])
            ChoiceChip(
              label: Text(value),
              selected: filter == value,
              onSelected: (_) => setState(() => filter = value),
            ),
        ],
      ),
      const SizedBox(height: 24),
      AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final products = _store.publishedProducts
              .where(
                (product) =>
                    (filter == 'All' || product.category == filter) &&
                    '${product.name} ${product.description}'
                        .toLowerCase()
                        .contains(query),
              )
              .toList();
          if (products.isEmpty) {
            return const InfoCard(
              child: Text('No products match your search.'),
            );
          }
          return ResponsiveGrid(
            children: [
              for (final product in products) _ProductCard(product: product),
            ],
          );
        },
      ),
      const SizedBox(height: 28),
      const InfoCard(
        color: Color(0xFFFFF8DE),
        child: Text(
          'Product photography uses MT Alchemy workshop imagery.',
          style: TextStyle(height: 1.5),
        ),
      ),
    ],
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final ShopProduct product;
  @override
  Widget build(BuildContext context) => InfoCard(
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductArtwork(product: product, height: 170),
        const SizedBox(height: 16),
        Eyebrow(product.digital ? 'Digital download' : 'Physical product'),
        const SizedBox(height: 8),
        Text(product.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(product.description, maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(
              money(product.price),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: deepBlue,
                fontSize: 18,
              ),
            ),
            if (!product.digital)
              Text(
                '${product.stock} in stock',
                style: const TextStyle(color: Colors.black54),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => go(context, '/product', arguments: product.id),
                child: const Text('View details'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Add ${product.name} to cart',
              onPressed: _store.canAddToCart(product.id)
                  ? () {
                      _store.addToCart(product.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.add_shopping_cart),
            ),
          ],
        ),
      ],
    ),
  );
}

class ProductArtwork extends StatelessWidget {
  const ProductArtwork({super.key, required this.product, this.height = 230});
  final ShopProduct product;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: product.imageBytes != null
          ? Image.memory(
              product.imageBytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _cover(),
            )
          : product.imagePath != null && product.imagePath!.isNotEmpty
          ? Image.asset(
              product.imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _cover(),
            )
          : _cover(),
    ),
  );
  Widget _cover() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [purple, royalBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(product.icon, color: Colors.white, size: 46),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              product.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, this.productId});
  final String? productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final requested = widget.productId == null
        ? null
        : _store.productById(widget.productId!);
    final product = widget.productId == null
        ? (_store.publishedProducts.isEmpty
              ? null
              : _store.publishedProducts.first)
        : requested?.published == true
        ? requested
        : null;
    if (product == null) {
      return const PortalPage(
        title: 'This product is unavailable.',
        eyebrow: 'Product detail',
        children: [
          InfoCard(
            child: Text('The catalogue has no published products right now.'),
          ),
        ],
      );
    }
    final availableToAdd = product.digital
        ? null
        : product.stock - _store.cartQuantityFor(product.id);
    return PortalPage(
      title: product.name,
      eyebrow: product.digital ? 'Digital product' : 'Physical product',
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final visual = ProductArtwork(product: product, height: 360);
            final details = InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    money(product.price),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: deepBlue,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  _DetailLine(
                    label: 'Product type',
                    value: product.digital
                        ? 'Digital download'
                        : 'Physical product',
                  ),
                  _DetailLine(
                    label: 'Availability',
                    value: product.digital
                        ? 'Available after purchase'
                        : product.stock > 0
                        ? 'In stock (${product.stock})'
                        : 'Out of stock',
                  ),
                  if (product.digital)
                    const _DetailLine(
                      label: 'Access',
                      value:
                          'Available from your Digital Product Library after purchase.',
                    ),
                  if (!product.digital)
                    const _DetailLine(
                      label: 'Shipping',
                      value:
                          'Physical delivery; shipping is calculated at checkout.',
                    ),
                  if (!product.digital)
                    _DetailLine(
                      label: 'Shipping requirement',
                      value: 'Physical delivery · RM 10 flat rate',
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Quantity'),
                      IconButton(
                        tooltip: 'Decrease quantity',
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        tooltip: 'Increase quantity',
                        onPressed:
                            product.digital ||
                                quantity < (availableToAdd ?? product.stock)
                            ? () => setState(() => quantity++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed:
                        _store.canAddToCart(product.id) &&
                            (product.digital ||
                                quantity <= (availableToAdd ?? 0))
                        ? () {
                            for (var count = 0; count < quantity; count++) {
                              _store.addToCart(product.id);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to your cart'),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Cart'),
                  ),
                  TextButton(
                    onPressed: () => go(context, '/cart'),
                    child: const Text('Go to cart'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        go(context, '/quote-request', arguments: product.id),
                    icon: const Icon(Icons.request_quote_outlined),
                    label: const Text('Request a business quote'),
                  ),
                ],
              ),
            );
            return box.maxWidth > 760
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: visual),
                      const SizedBox(width: 26),
                      Expanded(child: details),
                    ],
                  )
                : Column(
                    children: [visual, const SizedBox(height: 20), details],
                  );
          },
        ),
        const SectionTitle('You may also like', eyebrow: 'Related products'),
        ResponsiveGrid(
          children: [
            for (final related
                in _store.publishedProducts
                    .where((item) => item.id != product.id)
                    .take(3))
              _ProductCard(product: related),
          ],
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
