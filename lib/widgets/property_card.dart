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
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.25),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// IMAGE
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    property.cardImage,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 190,
                      color: theme.colorScheme.surfaceVariant,
                      child: const Center(
                        child: Text(
                          "No Image Available",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),

                /// CONTENT
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ADDRESS
                      Text(
                        property.address,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${property.city}, ${property.state}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// PRICE (FULL WIDTH – DOMINANT)
                      Text(
                        "\$${property.formattedPrice}",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// STATS
                      Text(
                        "${property.beds} beds • ${property.baths} baths • ${property.sqft} sqft",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),

                      const SizedBox(height: 10),

                      /// AGENT + COMPARE ROW
                      Row(
                        children: [
                          /// AGENT INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Listed by",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (property.agentNames.isNotEmpty)
                                  Text(
                                    property.agentNames.first,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (property.brokerage.isNotEmpty)
                                  Text(
                                    property.brokerage,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),

                          /// COMPARE
                          if (onCompareToggle != null)
                            TextButton.icon(
                              onPressed: onCompareToggle,
                              icon: Icon(
                                isCompared
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isCompared
                                    ? theme.colorScheme.primary
                                    : theme.hintColor,
                              ),
                              label: Text(
                                isCompared ? "Compared" : "Compare",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// FAVORITE BUTTON
          Positioned(
            top: 12,
            right: 14,
            child: GestureDetector(
              onTap: onFavoriteToggle,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.25),
                    ),
                  ],
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