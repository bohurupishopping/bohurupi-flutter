import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductCard extends StatelessWidget {
  static const double _kSpacing = 12.0;
  static const double _kSmallSpacing = 8.0;
  static const double _kBorderRadius = 12.0;
  static const double _kIconSize = 16.0;
  static const double _kSmallIconSize = 14.0;
  static const double _kImageSize = 80.0;
  static const double _kSmallImageSize = 60.0;

  final Map<String, dynamic> product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final imageSize = isSmallScreen ? _kSmallImageSize : _kImageSize;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? _kSmallSpacing : _kSpacing),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            if (product['image'] != null && product['image'].toString().isNotEmpty)
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_kBorderRadius / 2),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_kBorderRadius / 2),
                  child: Image.network(
                    product['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Iconsax.image,
                          size: isSmallScreen ? _kSmallIconSize : _kIconSize,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),

            SizedBox(width: isSmallScreen ? _kSmallSpacing : _kSpacing),

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
                          icon: Icon(
                            Iconsax.export,
                            size: isSmallScreen ? _kSmallIconSize : _kIconSize,
                            color: theme.colorScheme.primary,
                          ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(_kBorderRadius / 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.barcode,
                          size: isSmallScreen ? 10 : 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SKU: ${product['sku'] ?? ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          '₹${product['sale_price']?.toString() ?? '0'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Product Attributes
                  Wrap(
                    spacing: isSmallScreen ? 4 : 6,
                    runSpacing: 4,
                    children: [
                      if (product['colour'] != null && 
                          product['colour'].toString().isNotEmpty)
                        _buildAttributeChip(
                          context,
                          label: product['colour'],
                          icon: Iconsax.color_swatch,
                          isSmallScreen: isSmallScreen,
                        ),
                      if (product['size'] != null && 
                          product['size'].toString().isNotEmpty)
                        _buildAttributeChip(
                          context,
                          label: product['size'],
                          icon: Iconsax.ruler,
                          isSmallScreen: isSmallScreen,
                        ),
                      _buildAttributeChip(
                        context,
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
                          .map((category) => _buildCategoryChip(
                            context,
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

  Widget _buildAttributeChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(_kBorderRadius / 2),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 10 : 12,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          SizedBox(width: isSmallScreen ? 2 : 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(_kBorderRadius / 2),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.1),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 