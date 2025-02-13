import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            if (product['image'] != null && product['image'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['image'],
                  width: isSmallScreen ? 60 : 80,
                  height: isSmallScreen ? 60 : 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: isSmallScreen ? 60 : 80,
                      height: isSmallScreen ? 60 : 80,
                      color: theme.colorScheme.surfaceVariant,
                      child: const Icon(Iconsax.image),
                    );
                  },
                ),
              ),

            SizedBox(width: isSmallScreen ? 8 : 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Link
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product['details'] ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product['product_page_url'] != null && 
                          product['product_page_url'].toString().isNotEmpty)
                        IconButton(
                          onPressed: () async {
                            final url = Uri.parse(product['product_page_url']);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          icon: const Icon(Iconsax.export, size: 16),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // SKU and Price
                  Wrap(
                    spacing: 8,
                    children: [
                      Text(
                        'SKU: ${product['sku'] ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '₹${product['sale_price']?.toString() ?? '0'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Product Attributes
                  Wrap(
                    spacing: isSmallScreen ? 4 : 8,
                    runSpacing: 4,
                    children: [
                      if (product['colour'] != null && 
                          product['colour'].toString().isNotEmpty)
                        _AttributeChip(
                          label: product['colour'],
                          icon: Iconsax.color_swatch,
                          isSmallScreen: isSmallScreen,
                        ),
                      if (product['size'] != null && 
                          product['size'].toString().isNotEmpty)
                        _AttributeChip(
                          label: product['size'],
                          icon: Iconsax.ruler,
                          isSmallScreen: isSmallScreen,
                        ),
                      _AttributeChip(
                        label: 'Qty: ${product['qty']?.toString() ?? '1'}',
                        icon: Iconsax.box,
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),

                  if (product['product_category'] != null && 
                      product['product_category'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (product['product_category'] as String)
                          .split('|')
                          .map((category) => _CategoryChip(
                            label: category.trim(),
                            isSmallScreen: isSmallScreen,
                          ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSmallScreen;

  const _AttributeChip({
    required this.label,
    required this.icon,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 12 : 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: isSmallScreen ? 2 : 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isSmallScreen ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSmallScreen;

  const _CategoryChip({
    required this.label,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontSize: isSmallScreen ? 10 : 12,
        ),
      ),
    );
  }
} 