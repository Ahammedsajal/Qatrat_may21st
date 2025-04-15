import 'dart:async';
import 'dart:io';
import 'package:customer/Helper/Color.dart';
import 'package:customer/Helper/Constant.dart';
import 'package:customer/Helper/Session.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Model/Section_Model.dart';
import 'package:customer/Provider/order_provider.dart';
import 'package:customer/Screen/write_review.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../Model/User.dart';
import '../Provider/UserProvider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import 'HomePage.dart';
import 'Product_Preview.dart';
import 'Review_Gallary.dart';
import 'Review_Preview.dart';

class ReviewList extends StatefulWidget {
  final String? id;
  final Product? model;
  const ReviewList(this.id, this.model, {super.key});
  @override
  State<StatefulWidget> createState() {
    return StateRate();
  }
}

class StateRate extends State<ReviewList> {
  bool _isNetworkAvail = true;
  bool _isLoading = true;
  List<User> reviewList = [];
  List<imgModel> revImgList = [];
  int offset = 0;
  int total = 0;
  bool isLoadingmore = true;
  ScrollController controller = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<User> tempList = [];
  bool isPhotoVisible = true;
  String star1 = "0";
  String star2 = "0";
  String star3 = "0";
  String star4 = "0";
  String star5 = "0";
  String averageRating = "0";
  String? userComment = "";
  String? userRating = "0.0";
  @override
  void initState() {
    for (final element in reviewList) {
      if (element.userId == context.read<UserProvider>().userId) {
        userComment = element.comment;
        userRating = element.rating;
      }
    }
    getReview();
    controller.addListener(_scrollListener);
    Future.delayed(Duration.zero, () {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchOrderDetails(context.read<UserProvider>().userId, "delivered");
    });
    super.initState();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      print("loadingmore--->$isLoadingmore****$offset");
      if (mounted) {
        setState(() {
          isLoadingmore = true;
          getReview();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid ? false : true,
      child: Scaffold(
          key: _scaffoldKey,
          appBar: getAppBar(
              getTranslated(context, 'customer_REVIEW_LBL')!, context,),
          body: _review(),
          floatingActionButton: widget.model!.isPurchased == "true"
              ? FloatingActionButton.extended(
                  backgroundColor: Theme.of(context).colorScheme.primarytheme,
                  icon: Icon(
                    Icons.create,
                    size: 20,
                    color: Theme.of(context).colorScheme.white,
                  ),
                  label: userRating != "" && userComment != ""
                      ? Text(
                          getTranslated(context, "UPDATE_REVIEW_LBL")!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.white,
                              fontSize: 14,),
                        )
                      : Text(
                          getTranslated(context, "WRITE_REVIEW_LBL")!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.white,
                              fontSize: 14,),
                        ),
                  onPressed: () {
                    openBottomSheet(context, widget.id, userComment,
                        double.parse(userRating!),);
                  },
                )
              : const SizedBox.shrink(),),
    );
  }

  Future<void> openBottomSheet(BuildContext context, var productID,
      var userReview, double userRating,) async {
    await showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0),),),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Write_Review(
              _scaffoldKey.currentContext!, widget.id!, userReview, userRating,);
        },).then((value) {
      getReview();
    });
  }

  Widget _review() {
    return _isLoading
        ? reviewShimmer()
        : SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          children: [
                            Text(
                              averageRating,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 30,),
                            ),
                            Text("$total ${getTranslated(context, "RATINGS")!}"),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              getRatingBarIndicator(5.0, 5),
                              getRatingBarIndicator(4.0, 4),
                              getRatingBarIndicator(3.0, 3),
                              getRatingBarIndicator(2.0, 2),
                              getRatingBarIndicator(1.0, 1),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              getRatingIndicator(int.parse(star5)),
                              getRatingIndicator(int.parse(star4)),
                              getRatingIndicator(int.parse(star3)),
                              getRatingIndicator(int.parse(star2)),
                              getRatingIndicator(int.parse(star1)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            getTotalStarRating(star5),
                            getTotalStarRating(star4),
                            getTotalStarRating(star3),
                            getTotalStarRating(star2),
                            getTotalStarRating(star1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (revImgList.isNotEmpty) Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Card(
                          elevation: 0.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  getTranslated(context, "REVIEW_BY_CUST")!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,),
                                ),
                              ),
                              const Divider(),
                              _reviewImg(),
                            ],
                          ),
                        ),
                      ) else const SizedBox.shrink(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "$total ${getTranslated(context, "REVIEW_LBL")}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24,),
                          ),
                        ],
                      ),
                      if (revImgList.isNotEmpty) Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      isPhotoVisible = !isPhotoVisible;
                                    });
                                  },
                                  child: Container(
                                    height: 20.0,
                                    width: 20.0,
                                    decoration: BoxDecoration(
                                        color: isPhotoVisible
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primarytheme
                                            : Theme.of(context)
                                                .colorScheme
                                                .white,
                                        borderRadius:
                                            BorderRadius.circular(3.0),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primarytheme,
                                        ),),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: isPhotoVisible
                                          ? Icon(
                                              Icons.check,
                                              size: 15.0,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .white,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "${getTranslated(context, "WITH_PHOTO")}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,),
                                ),
                              ],
                            ) else const SizedBox.shrink(),
                    ],
                  ),
                ),
                ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    itemCount: (offset < total)
                        ? reviewList.length + 1
                        : reviewList.length,
                    itemBuilder: (context, index) {
                      print(
                          "index&reviewlist-->$index--->${reviewList.length}--->$isLoadingmore",);
                      if (index == reviewList.length && isLoadingmore) {
                        return Center(
                            child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primarytheme,
                        ),);
                      } else {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Card(
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reviewList[index].username!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          RatingBarIndicator(
                                            rating: double.parse(
                                                reviewList[index].rating!,),
                                            itemBuilder: (context, index) =>
                                                const Icon(
                                              Icons.star,
                                              color: colors.yellow,
                                            ),
                                            itemSize: 12.0,
                                          ),
                                          const Spacer(),
                                          Text(
                                            reviewList[index].date!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack2,
                                                fontSize: 11,),
                                          ),
                                        ],
                                      ),
                                      if (reviewList[index].comment != "" &&
                                              reviewList[index]
                                                  .comment!
                                                  .isNotEmpty) Text(
                                              reviewList[index].comment ?? '',
                                              textAlign: TextAlign.left,
                                            ) else const SizedBox.shrink(),
                                      if (isPhotoVisible) reviewImage(index) else const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25.0),
                                  child: networkImageCommon(
                                      reviewList[index].userProfile!, 36, false,
                                      height: 36, width: 36,),),
                            ),
                          ],
                        );
                      }
                    },),
              ],
            ),
          );
  }

  Widget reviewShimmer() {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * .22,
                width: double.infinity,
                color: Theme.of(context).colorScheme.white,
              ),
              Column(
                children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                    .map((index) => Padding(
                          padding: const EdgeInsetsDirectional.only(
                              bottom: 8.0, top: 25, start: 20, end: 20,),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 80.0,
                                      height: 18.0,
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 3.0),
                                    ),
                                    Container(
                                      width: 130.0,
                                      height: 8.0,
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 3.0),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: 8.0,
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 3.0),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: 100.0,
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),)
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _reviewImg() {
    return revImgList.isNotEmpty
        ? SizedBox(
            height: 100,
            child: ListView.builder(
              itemCount: revImgList.length > 5 ? 5 : revImgList.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: InkWell(
                    onTap: () async {
                      if (index == 4) {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) =>
                                    ReviewGallary(productModel: widget.model),),);
                      } else {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                                pageBuilder: (_, __, ___) => ReviewPreview(
                                      index: index,
                                      productModel: widget.model,
                                    ),),);
                      }
                    },
                    child: Stack(
                      children: [
                        networkImageCommon(revImgList[index].img!, 80, false,
                            height: 100, width: 80,),
                        if (index == 4) Container(
                                height: 100.0,
                                width: 80.0,
                                color: colors.black54,
                                child: Center(
                                    child: Text(
                                  "+${revImgList.length - 5}",
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      fontWeight: FontWeight.bold,),
                                ),),
                              ) else const SizedBox.shrink(),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : const SizedBox.shrink();
  }

  reviewImage(int i) {
    return SizedBox(
      height: reviewList[i].imgList!.isNotEmpty ? 100 : 0,
      child: ListView.builder(
        itemCount: reviewList[i].imgList!.length,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsetsDirectional.only(end: 10, bottom: 5.0, top: 5),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ProductPreview(
                        pos: index,
                        secPos: 0,
                        index: 0,
                        id: "$index${reviewList[i].id}",
                        imgList: reviewList[i].imgList,
                        list: true,
                        from: false,
                      ),
                    ),);
              },
              child: Hero(
                tag: '$index${reviewList[i].id}',
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: networkImageCommon(
                        reviewList[i].imgList![index], 100, false,
                        height: 100, width: 100,),),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> getReview() async {
    print("offset****$offset");
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          PRODUCT_ID: widget.id,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };
        apiBaseHelper.postAPICall(getRatingApi, parameter).then((getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
            star1 = getdata["star_1"];
            star2 = getdata["star_2"];
            star3 = getdata["star_3"];
            star4 = getdata["star_4"];
            star5 = getdata["star_5"];
            averageRating = getdata["product_rating"];
            total = int.parse(getdata["total"]);
            print(
                "totlereviewlist-->$offset ---> $total****${offset < total}",);
            if (offset < total) {
              final data = getdata["data"];
              final List<User> tempList =
                  (data as List).map((data) => User.forReview(data)).toList();
              reviewList.addAll(tempList);
              print("reviewlist length****${reviewList.length}");
              offset = offset + perPage;
              print("offset add****$offset");
              setState(() {});
            }
          } else {
            if (msg != "No ratings found !") setSnackbar(msg!, context);
            isLoadingmore = false;
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  getRatingBarIndicator(var ratingStar, var totalStars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: RatingBarIndicator(
        textDirection: TextDirection.rtl,
        rating: ratingStar,
        itemBuilder: (context, index) => const Icon(
          Icons.star_rate_rounded,
          color: colors.yellow,
        ),
        itemCount: totalStars,
        itemSize: 20.0,
        unratedColor: Colors.transparent,
      ),
    );
  }

  getRatingIndicator(var totalStar) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Stack(
        children: [
          Container(
            height: 10,
            width: MediaQuery.of(context).size.width / 3,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.0),
                border: Border.all(
                  width: 0.5,
                  color: Theme.of(context).colorScheme.primarytheme,
                ),),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              color: Theme.of(context).colorScheme.primarytheme,
            ),
            width: (totalStar / reviewList.length) *
                MediaQuery.of(context).size.width /
                3,
            height: 10,
          ),
        ],
      ),
    );
  }

  getTotalStarRating(var totalStar) {
    return SizedBox(
        width: 20,
        height: 20,
        child: Text(
          totalStar,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),);
  }
}
