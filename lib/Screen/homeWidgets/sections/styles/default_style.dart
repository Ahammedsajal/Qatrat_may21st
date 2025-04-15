import 'package:customer/Screen/homeWidgets/sections/blueprint.dart';
import 'package:customer/app/routes.dart';
import 'package:flutter/material.dart';

class DefaultStyleSection extends FeaturedSection {
  @override
  String style = "default";

  @override
  Widget render(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: GridView.builder(
        padding: const EdgeInsetsDirectional.only(top: 5),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two items per row
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8, // Adjusts the height-to-width ratio
        ),
        itemCount: products.length < 4 ? products.length : 4,
        itemBuilder: (context, index) {
          final product = products[index];

          return GestureDetector(
            onTap: () {
              // Navigate to product details
              Navigator.pushNamed(
                context,
                Routers.productDetails,
                arguments: {
                  "secPos": index,
                  "index": index,
                  "list": false,
                  "id": product.id, // Ensure `id` exists in Product model
                },
              );
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Product Image (Handled safely)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: product.image != null
                          ? Image.network(
                              product.image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),

                  // ✅ Product Title & Price
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name ?? "No Name", // Handle null values safely
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.prVarientList != null && product.prVarientList!.isNotEmpty
                              ? "\$${product.prVarientList![0].price ?? 'N/A'}"
                              : "Price Unavailable",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ Placeholder for missing images
  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey.shade600),
      ),
    );
  }
}
