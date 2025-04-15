import 'package:customer/Screen/homeWidgets/sections/blueprint.dart';
import 'package:customer/Screen/homeWidgets/sections/styles/style_1.dart';
import 'package:flutter/material.dart';

class StyleFourSection extends FeaturedSection {
  @override
  String style = "style_4";
  @override
  Widget render(BuildContext context) {
    final Orientation orient = MediaQuery.of(context).orientation;
    final double height = MediaQuery.of(context).size.height;
    return Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
                child: SizedBox(
                    height: orient == Orientation.portrait
                        ? height * 0.25
                        : height * 0.5,
                    child: products.length == 1 || products.length > 1
                        ? productItem(
                            index, 0, false, products[0], 1, products.length,)
                        : const SizedBox.shrink(),),),
            SizedBox(
              height:
                  orient == Orientation.portrait ? height * 0.2 : height * 0.5,
              child: Row(
                children: [
                  Flexible(
                      child: products.length == 2 || products.length > 2
                          ? productItem(
                              index, 1, true, products[1], 1, products.length,)
                          : const SizedBox.shrink(),),
                  Flexible(
                      child: products.length == 3 || products.length > 3
                          ? productItem(
                              index, 2, false, products[2], 1, products.length,)
                          : const SizedBox.shrink(),),
                ],
              ),
            ),
          ],
        ),);
  }
}
