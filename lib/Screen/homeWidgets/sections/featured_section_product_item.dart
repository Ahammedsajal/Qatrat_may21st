import 'package:customer/Helper/Color.dart';
import 'package:customer/Model/Section_Model.dart';
import 'package:customer/app/routes.dart';
import 'package:flutter/material.dart';
import '../../../Helper/Session.dart';
import '../../../ui/styles/DesignConfig.dart';

class FeaturedProductItem extends StatelessWidget {
  const FeaturedProductItem({
    super.key,
    required this.price,
    required this.offerPersontage,
    required this.product,
    required this.sectionPosition,
    required this.index,
  });
  final double price;
  final String? offerPersontage;
  final Product product;
  final int sectionPosition;
  final int index;
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.5;
    return Card(
      elevation: 0.0,
      margin: const EdgeInsetsDirectional.only(bottom: 2, end: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    clipBehavior: Clip.none,
                    children: [
                      networkImageCommon(product.image!, width, false,
                          height: double.maxFinite, width: double.maxFinite,),
                      if (product.availability == "0") Container(
                              constraints: const BoxConstraints.expand(),
                              color: Theme.of(context).colorScheme.white70,
                              width: double.maxFinite,
                              padding: const EdgeInsets.all(2),
                              child: Center(
                                child: Text(
                                  getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ) else const SizedBox.shrink(),
                    ],
                  ),),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 10.0, top: 5, end: 5.0,),
              child: Text(
                product.name!,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.lightBlack),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
                padding: const EdgeInsetsDirectional.only(start: 10.0, top: 2),
                child: Text(
                    product.isSalesOn == "1"
                        ? getPriceFormat(
                            context,
                            double.parse(
                                product.prVarientList![0].saleFinalPrice!,),)!
                        : '${getPriceFormat(context, price)!} ',
                    style: TextStyle(
                        fontSize: 11.0,
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,),),),
            Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 10.0, bottom: 8, top: 2,),
                child: offerPersontage != "0.00"
                    ? double.parse(product.prVarientList![0].disPrice!) != 0
                        ? Row(
                            children: <Widget>[
                              Text(
                                double.parse(product
                                            .prVarientList![0].disPrice!,) !=
                                        0
                                    ? getPriceFormat(
                                        context,
                                        double.parse(
                                            product.prVarientList![0].price!,),)!
                                    : "",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        letterSpacing: 0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.6),),
                              ),
                              Flexible(
                                child: Text(
                                    " | "
                                    "-${product.isSalesOn == "1" ? double.parse(product.saleDis!).toStringAsFixed(2) : offerPersontage}%",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primarytheme,
                                            letterSpacing: 0,),),
                              ),
                            ],
                          )
                        : Container(
                            height: 5,
                          )
                    : const SizedBox.shrink(),),
          ],
        ),
        onTap: () {
          final Product model = product;
          print("GOING TO ROUTER");
          Navigator.pushNamed(context, Routers.productDetails, arguments: {
            "secPos": sectionPosition,
            "index": index,
            "list": false,
            "id": model.id!,
          },);
        },
      ),
    );
  }
}
