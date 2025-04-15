import 'package:customer/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../Helper/Color.dart';
import '../../Helper/String.dart';
import '../../Model/Section_Model.dart';
import '../styles/DesignConfig.dart';

Widget productItemView(
    int index, List<Product> productList, BuildContext context, String from,) {
  if (index < productList.length) {
    String? offPer;
    double price = double.parse(productList[index].prVarientList![0].disPrice!);
    if (price == 0) {
      price = double.parse(productList[index].prVarientList![0].price!);
    } else {
      final double off =
          double.parse(productList[index].prVarientList![0].price!) - price;
      offPer = ((off * 100) /
              double.parse(productList[index].prVarientList![0].price!))
          .toStringAsFixed(2);
    }
    final double width = deviceWidth! * 0.45;
    return SizedBox(
        height: 255,
        width: width,
        child: Card(
          elevation: 0.2,
          margin: const EdgeInsetsDirectional.only(bottom: 5, end: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                          padding: const EdgeInsetsDirectional.only(top: 8.0),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(5),),
                            child: Hero(
                                tag: "$from$index${productList[index].id}0",
                                child: networkImageCommon(
                                    productList[index].image!,
                                    double.maxFinite,
                                    false,
                                    height: double.maxFinite,
                                    width: double.maxFinite,),),
                          ),),
                      if (offPer != null) Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: colors.red,
                                    borderRadius: BorderRadius.circular(10),),
                                margin: const EdgeInsets.all(5),
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(
                                    "$offPer%",
                                    style: const TextStyle(
                                        color: colors.whiteTemp,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,),
                                  ),
                                ),
                              ),
                            ) else const SizedBox.shrink(),
                      const Divider(
                        height: 1,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 5.0,
                    top: 5,
                  ),
                  child: Row(
                    children: [
                      RatingBarIndicator(
                        rating: double.parse(productList[index].rating!),
                        itemBuilder: (context, index) => const Icon(
                          Icons.star_rate_rounded,
                          color: Colors.amber,
                        ),
                        unratedColor: Colors.grey.withOpacity(0.5),
                        itemSize: 12.0,
                      ),
                      Text(
                        " (${productList[index].noOfRating!})",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 5.0, top: 5, bottom: 5,),
                  child: Text(
                    productList[index].name!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                    padding: const EdgeInsetsDirectional.only(start: 5.0),
                    child: Row(
                      children: [
                        Text('${getPriceFormat(context, price)!} ',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.bold,),),
                        Text(
                          double.parse(productList[index]
                                      .prVarientList![0]
                                      .disPrice!,) !=
                                  0
                              ? getPriceFormat(
                                  context,
                                  double.parse(productList[index]
                                      .prVarientList![0]
                                      .price!,),)!
                              : "",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall!
                              .copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  letterSpacing: 0,),
                        ),
                      ],
                    ),),
              ],
            ),
            onTap: () {
              final Product model = productList[index];
              currentHero = from;
              Navigator.pushNamed(context, Routers.productDetails, arguments: {
                "id": model.id!,
                "secPos": 0,
                "index": index,
                "list": true,
              },);
            },
          ),
        ),);
  } else {
    return const SizedBox.shrink();
  }
}
