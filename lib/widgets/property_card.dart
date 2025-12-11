import 'package:flutter/material.dart';
import '../models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;

  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  final VoidCallback? onTap;

  final bool isCompared;
  final VoidCallback? onCompareToggle;

  const PropertyCard({
    super.key,
    required this.property,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap,
    this.isCompared = false,
    this.onCompareToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.cardColor, 
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                  color: theme.shadowColor.withOpacity(0.15), 
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    property.cardImage,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: theme.colorScheme.surfaceVariant, 
                      child: const Center(child: Text("No Image")),
                    ),
                  ),
                ),

                // TEXT + COMPARE
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.address,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${property.city}, ${property.state}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor, 
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "\$${property.formattedPrice}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${property.beds} beds • ${property.baths} baths • ${property.sqft} sqft",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),

                      // COMPARE BUTTON ROW
                      if (onCompareToggle != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: onCompareToggle,
                            icon: Icon(
                              isCompared
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isCompared
                                  ? theme.colorScheme.primary
                                  : theme.hintColor,
                              size: 20,
                            ),
                            label: Text(
                              isCompared
                                  ? "Selected to compare"
                                  : "Compare",
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ❤️ FAVORITE BUTTON
          Positioned(
            top: 10,
            right: 12,
            child: GestureDetector(
              onTap: onFavoriteToggle,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, 
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: isFavorite ? Colors.red : theme.disabledColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}