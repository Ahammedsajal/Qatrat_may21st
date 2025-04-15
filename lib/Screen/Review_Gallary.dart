import 'package:customer/Helper/Session.dart';
import 'package:customer/Model/Order_Model.dart';
import 'package:customer/Model/Section_Model.dart';
import 'package:customer/Screen/Review_Preview.dart';
import 'package:flutter/material.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import 'Product_DetailNew.dart';

class ReviewGallary extends StatefulWidget {
  final Product? productModel;
  final OrderModel? orderModel;
  final List<dynamic>? imageList;
  const ReviewGallary(
      {super.key, this.productModel, this.orderModel, this.imageList,});
  @override
  _ReviewImageState createState() => _ReviewImageState();
}

class _ReviewImageState extends State<ReviewGallary> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(getTranslated(context, 'REVIEW_BY_CUST')!, context),
      body: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          padding: const EdgeInsets.all(20),
          children: List.generate(
            widget.productModel != null
                ? revImgList.length
                : widget.imageList!.length,
            (index) {
              return InkWell(
                child: networkImageCommon(
                    widget.productModel != null
                        ? revImgList[index].img!
                        : widget.imageList![index],
                    double.maxFinite,
                    true,),
                onTap: () {
                  if (widget.productModel != null) {
                    Navigator.push(
                        context,
                        PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ReviewPreview(
                                  index: index,
                                  productModel: widget.productModel,
                                ),),);
                  } else {
                    Navigator.push(
                        context,
                        PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ReviewPreview(
                                  index: index,
                                  imageList: widget.imageList,
                                ),),);
                  }
                },
              );
            },
          ),),
    );
  }
}
