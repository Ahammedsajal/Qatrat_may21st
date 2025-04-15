import 'package:customer/Helper/Color.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Provider/HomeProvider.dart';
import 'package:customer/Model/Section_Model.dart';
import 'package:customer/app/routes.dart';
import 'package:customer/Helper/Session.dart'; // Assumes this file defines & populates `catList`
import 'package:customer/ui/styles/DesignConfig.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer/Provider/CategoryProvider.dart';
import '../Screen/HomePage.dart';

class AllCategory extends StatefulWidget {
  const AllCategory({super.key});
  @override
  AllCategoryState createState() => AllCategoryState();
}

class AllCategoryState extends State<AllCategory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslated(context, 'allCategories') ?? "All Categories"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, _) {
          if (homeProvider.catLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primarytheme,
              ),
            );
          }
          // Assume your API populates catList with your categories
          final List<Product> categories = catList;
          if (categories.isEmpty) {
            return Center(
              child: Text(
                getTranslated(context, 'noCategories') ?? "No categories available",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two columns for better use of space
                childAspectRatio: 0.9,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                return _buildCategoryCard(categories[index]);
              },
            ),
          );
        },
      ),
    );
  }

  /// Builds an attractive category card with a gradient background and Hero animation.
  Widget _buildCategoryCard(Product category) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routers.productListScreen,
          arguments: {
            "name": category.name,
            "id": category.id,
            "tag": false,
            "fromSeller": false,
          },
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background gradient for modern styling.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Category image and name.
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: category.id!,
                  child: ClipOval(
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.white,
                      child: networkImageCommon(
                        category.image!,
                        50,
                        width: 80,
                        height: 80,
                        false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    capitalize(category.name!.toLowerCase()),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
