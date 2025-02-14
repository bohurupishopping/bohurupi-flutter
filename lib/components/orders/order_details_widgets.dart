import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:cached_network_image/cached_network_image.dart';

// Cached styles and decorations
@immutable
class _DetailStyles {
  final BoxDecoration cardDecoration;
  final BoxDecoration iconDecoration;
  final BoxDecoration labelDecoration;
  final TextStyle titleStyle;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _DetailStyles({
    required this.cardDecoration,
    required this.iconDecoration,
    required this.labelDecoration,
    required this.titleStyle,
    required this.labelStyle,
    required this.valueStyle,
  });

  factory _DetailStyles.from(ThemeData theme) {
    final primaryOpacity01 = theme.colorScheme.primary.withOpacity(0.1);
    final outlineOpacity01 = theme.colorScheme.outline.withOpacity(0.1);
    final shadowOpacity005 = theme.colorScheme.shadow.withOpacity(0.05);

    return _DetailStyles(
      cardDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineOpacity01),
        boxShadow: [
          BoxShadow(
            color: shadowOpacity005,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      iconDecoration: BoxDecoration(
        color: primaryOpacity01,
        shape: BoxShape.circle,
      ),
      labelDecoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ) ?? const TextStyle(),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ) ?? const TextStyle(),
      valueStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ) ?? const TextStyle(),
    );
  }
}

@immutable
class DetailCard extends StatelessWidget {
  static const EdgeInsets _headerPadding = EdgeInsets.fromLTRB(16, 16, 16, 12);
  static const EdgeInsets _iconPadding = EdgeInsets.all(8);

  const DetailCard({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styles = _DetailStyles.from(theme);

    return Container(
      decoration: styles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: _headerPadding,
            child: Row(
              children: [
                Container(
                  padding: _iconPadding,
                  decoration: styles.iconDecoration,
                  child: FaIcon(
                    icon,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: styles.titleStyle,
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: styles.iconDecoration,
                    child: Text(
                      trailing!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

@immutable
class DetailRow extends StatelessWidget {
  static const EdgeInsets _iconPadding = EdgeInsets.all(8);
  static const EdgeInsets _containerMargin = EdgeInsets.only(bottom: 12);

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isPhone = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styles = _DetailStyles.from(theme);

    return Container(
      margin: _containerMargin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: _iconPadding,
            decoration: styles.labelDecoration,
            child: FaIcon(
              icon,
              size: 14,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: styles.labelStyle,
                ),
                const SizedBox(height: 4),
                if (isPhone)
                  InkWell(
                    onTap: () => url_launcher.launchUrl(Uri.parse('tel:$value')),
                    child: Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: styles.valueStyle,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class StatusBadge extends StatelessWidget {
  static const double _borderRadius = 24.0;
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorOpacity01 = color.withOpacity(0.1);
    final colorOpacity02 = color.withOpacity(0.2);

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: colorOpacity01,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: colorOpacity02),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class CustomActionChip extends StatelessWidget {
  static const double _borderRadius = 8.0;
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  const CustomActionChip({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;
    final chipColorOpacity02 = chipColor.withOpacity(0.2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Container(
          padding: _padding,
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(_borderRadius),
            boxShadow: [
              BoxShadow(
                color: chipColorOpacity02,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                icon,
                size: 14,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class ProductChip extends StatelessWidget {
  static const double _borderRadius = 6.0;
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  const ProductChip({
    super.key,
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryContainerOpacity03 = theme.colorScheme.secondaryContainer.withOpacity(0.3);

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: secondaryContainerOpacity03,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: theme.colorScheme.secondaryContainer,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 12,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class ProductImage extends StatelessWidget {
  static const double _borderRadius = 6.0;

  const ProductImage({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineOpacity01 = theme.colorScheme.outline.withOpacity(0.1);

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(color: outlineOpacity01),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: theme.colorScheme.errorContainer,
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 24,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 