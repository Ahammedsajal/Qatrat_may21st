import 'dart:async';
import 'dart:developer';
import 'dart:io';
import '../settings.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:customer/Helper/SqliteData.dart';
import 'package:customer/Provider/CartProvider.dart';
import 'package:customer/Provider/FavoriteProvider.dart';
import 'package:customer/Provider/HomeProvider.dart';
import 'package:customer/Provider/ProductDetailProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/Screen/ListItemCompare.dart';
import 'package:customer/Screen/ReviewList.dart';
import 'package:customer/Screen/cart/Cart.dart';
import 'package:customer/main.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import 'package:customer/Helper/String.dart' hide currencySymbol;
import '../Model/Faqs_Model.dart';
import '../Model/Section_Model.dart';
import '../Model/User.dart';
import '../Provider/FlashSaleProvider.dart';
import '../Provider/SettingProvider.dart';
import '../app/routes.dart';
import '../cubits/fetch_featured_sections_cubit.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/ProductListView.dart';
import '../ui/widgets/SimBtn.dart';
import '../ui/widgets/setTitleWidget.dart';
import '../utils/blured_router.dart';
import 'CompareList.dart';
import 'HomePage.dart';
import 'MultipleTimer.dart';
import 'Product_Preview.dart';
import 'Review_Gallary.dart';
import 'Review_Preview.dart';
import '../app/curreny_converter.dart';

class ProductDetail extends StatefulWidget {
  final int? secPos;
  final int? index;
  final bool? list;
  final String id;
  final int? saleIndex;
  static route(RouteSettings settings) {
    final Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return ProductDetail(
          id: arguments?['id'],
          index: arguments?['index'],
          secPos: arguments?['secPos'],
          list: arguments?['list'],
          saleIndex: arguments?['saleIndex'],
        );
      },
    );
  }

  const ProductDetail({
    super.key,
    this.secPos,
    this.index,
    this.list,
    this.saleIndex,
    required this.id,
  });
  @override
  State<StatefulWidget> createState() => StateItem();
}

List<User> reviewList = [];
List<imgModel> revImgList = [];
int offset = 0;
int total = 0;
List<FaqsModel> faqsProductList = [];
int faqsOffset = 0;
int faqsTotal = 0;

class StateItem extends State<ProductDetail> with TickerProviderStateMixin {
  bool whatsappShareLoading = false;
  int _curSlider = 0;
  final _pageController = PageController();
  final List<int?> _selectedIndex = [];
  ChoiceChip? choiceChip;
  ChoiceChip? tagChip;
  int _oldSelVarient = 0;
  bool _isLoading = true;
  bool _isFaqsLoading = true;
  String star1 = "0";
  String star2 = "0";
  String star3 = "0";
  String star4 = "0";
  String star5 = "0";
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  int notificationoffset = 0;
  late int totalProduct = 0;
  bool notificationisloadmore = true;
  bool notificationisgettingdata = false;
  bool notificationisnodata = false;
  List<Product> productList = [];
  List<Product> productList1 = [];
  bool seeView = false;
  late ShortDynamicLink shortenedLink;
  String? shareLink;
  late String curPin;
  late double growStepWidth;
  late double beginWidth;
  late double endWidth = 0.0;
  TextEditingController qtyController = TextEditingController();
  List<String?> sliderList = [];
  int? varSelected;
  List<Product> compareList = [];
  bool isBottom = false;
  DatabaseHelper db = DatabaseHelper();
  bool qtyChange = false;
  bool? available;
  bool? outOfStock;
  int? selectIndex = 0;
  final edtFaqs = TextEditingController();
  final GlobalKey<FormState> faqsKey = GlobalKey<FormState>();
  List<String> proIds1 = [];
  List<Product> mostFavProList = [];
  Product? productData;
  String deliveryDate = '';
  String codDeliveryCharges = '';
  String prePaymentDeliveryCharges = '';
  String deliveryMsg = '';
  bool isLoadedAll = false;
  late StreamController streamController;
  Future allApiAndFun() async {
    await getProduct1();
    if (mounted) {
      final Product model = productData!;
      print("model varient1****${model.selVarient!}");
      _oldSelVarient = model.selVarient!;
      sliderList.clear();
      sliderList.insert(0, model.image);
      addImage().then((value) {
        if (model.videType != "" &&
            model.video!.isNotEmpty &&
            model.video != "") {
          sliderList.insert(1, "youtube");
        }
      });
      revImgList.clear();
      if (model.reviewList!.isNotEmpty)
        for (int i = 0; i < model.reviewList![0].productRating!.length; i++) {
          for (int j = 0;
              j < model.reviewList![0].productRating![i].imgList!.length;
              j++) {
            final imgModel m = imgModel.fromJson(
                i, model.reviewList![0].productRating![i].imgList![j],);
            revImgList.add(m);
          }
        }
      reviewList.clear();
      offset = 0;
      total = 0;
      await getReview();
      await getDeliverable(productData!);
      notificationoffset = 0;
      await getProduct();
      faqsProductList.clear();
      faqsOffset = 0;
      faqsTotal = 0;
      await getProductFaqs();
      checkProId();
      await getProFavIds();
      compareList = context.read<ProductDetailProvider>().compareList;
      _selectedIndex.clear();
      if (model.stockType == '0' || model.stockType == '1') {
        if (model.availability == '1') {
          available = true;
          outOfStock = false;
          _oldSelVarient = model.selVarient!;
        } else {
          available = false;
          outOfStock = true;
        }
      } else if (model.stockType == '') {
        available = true;
        outOfStock = false;
        _oldSelVarient = model.selVarient!;
      } else if (model.stockType == '2') {
        if (model.prVarientList![model.selVarient!].availability == '1') {
          available = true;
          outOfStock = false;
          _oldSelVarient = model.selVarient!;
        } else {
          available = false;
          outOfStock = true;
        }
      }
      final List<String> selList = model
          .prVarientList![model.selVarient!].attribute_value_ids!
          .split(',');
      for (int i = 0; i < model.attributeList!.length; i++) {
        final List<String> sinList = model.attributeList![i].id!.split(',');
        for (int j = 0; j < sinList.length; j++) {
          if (selList.contains(sinList[j])) {
            _selectedIndex.insert(i, j);
          }
        }
        if (_selectedIndex.length == i) _selectedIndex.insert(i, null);
      }
      setState(() {
        isLoadedAll = true;
      });
    }
  }

  String? pincodeOrCityName;
  String? slectedCityId;
  @override
  void initState() {
    super.initState();
    setupChannel();
    print("userreviewlist-->${reviewList.length}");
    getProductDetails();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this,);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ),);
  }

  getProFavIds() async {
    proIds1 = (await db.getMostFav())!;
    getMostFavPro();
  }

  @override
  void dispose() {
    streamController.close();
    buttonController!.dispose();
    edtFaqs.dispose();
    super.dispose();
  }

  checkProId() {
    db.addMostFav(productData!.id!);
  }

  Future<void> addImage() async {
    final Product model = productData!;
    if (model.otherImage!.isNotEmpty) {
      sliderList.addAll(model.otherImage!);
    }
    for (int i = 0; i < model.prVarientList!.length; i++) {
      for (int j = 0; j < model.prVarientList![i].images!.length; j++) {
        sliderList.add(model.prVarientList![i].images![j]);
      }
    }
  }

  Future<String> generateShortDynamicLinkOfProduct(Product data) async {
    return generateShortDynamicLink(data);
  }

  Future<void> createDynamicLink(Product data) async {
    final String shortenedLink = await generateShortDynamicLinkOfProduct(data);
    Share.share(shortenedLink,
        sharePositionOrigin: Rect.fromLTWH(
            0,
            0,
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height / 2,),);
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      return;
    }
  }

  Future<void> getMostFavPro() async {
    if (proIds1.isNotEmpty) {
      final Product model = productData!;
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          final parameter = {"product_ids": proIds1.join(',')};
          apiBaseHelper.postAPICall(getProductApi, parameter).then(
              (getdata) async {
            final bool error = getdata["error"];
            if (!error) {
              final data = getdata["data"];
              final List<Product> tempList =
                  (data as List).map((data) => Product.fromJson(data)).toList();
              mostFavProList.clear();
              final extPro = tempList.firstWhereOrNull((cp) => cp.id == model.id);
              if (extPro == null) {
                mostFavProList.addAll(tempList);
              } else {
                tempList.removeWhere((element) => element.id == model.id);
                mostFavProList.addAll(tempList);
              }
            }
            if (mounted) {
              setState(() {
                context.read<HomeProvider>().setMostLikeLoading(false);
              });
            }
          }, onError: (error) {
            if (mounted) setSnackbar(error.toString(), context);
          },);
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          context.read<HomeProvider>().setMostLikeLoading(false);
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
            context.read<HomeProvider>().setMostLikeLoading(false);
          });
        }
      }
    } else {
      context.read<CartProvider>().setCartlist([]);
      setState(() {
        context.read<HomeProvider>().setMostLikeLoading(false);
      });
    }
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        noIntImage(),
        noIntText(context),
        noIntDec(context),
        AppBtn(
          title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
          btnAnim: buttonSqueezeanimation,
          btnCntrl: buttonController,
          onBtnSelected: () async {
            _playAnimation();
            Future.delayed(const Duration(seconds: 2)).then((_) async {
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                        builder: (BuildContext context) => super.widget,),);
              } else {
                await buttonController!.reverse();
                if (mounted) setState(() {});
              }
            });
          },
        ),
      ],),
    );
  }

  _mostFav() {
    return mostFavProList.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  setHeadTitle(
                      getTranslated(context, 'YOU_ARE_LOOKING_FOR_LBL')!,
                      context,),
                  Container(
                    height: 230,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: mostFavProList.length,
                      itemBuilder: (context, index) {
                        return productItemView(
                            index, mostFavProList, context, detail1Hero,);
                      },
                    ),
                  ),
                ],),)
        : const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      bottom: Platform.isAndroid ? false : true,
      child: Scaffold(
        backgroundColor: isBottom
            ? Colors.transparent.withOpacity(0.5)
            : Theme.of(context).canvasColor,
        body: _isNetworkAvail
            ? Stack(
                children: <Widget>[
                  _showContent(),
                  Selector<CartProvider, bool>(
                    builder: (context, data, child) {
                      return showCircularProgress(context, data,
                          Theme.of(context).colorScheme.primarytheme,);
                    },
                    selector: (_, provider) => provider.isProgress,
                  ),
                ],
              )
            : noInternet(context),
      ),
    );
  }

  List<T> map<T>(List list, Function handler) {
    final List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }
    return result;
  }

  Widget _slider(Product data) {
    final Product model = data;
    final double height = MediaQuery.of(context).size.height * .43;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ProductPreview(
                pos: _curSlider,
                secPos: widget.secPos,
                index: widget.index,
                id: model.id,
                imgList: sliderList,
                list: widget.list,
                video: model.video,
                videoType: model.videType,
                from: true,
              ),
            ),);
      },
      child: Stack(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(top: statusBarHeight + kToolbarHeight),
            child: PageView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: sliderList.length,
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _curSlider = index;
                });
              },
              itemBuilder: (BuildContext context, int i) {
                return sliderList[i] != "youtube"
                    ? networkImageCommon(sliderList[i]!, height, true)
                    : playIcon(data);
              },
            ),
          ),
          Positioned(
            bottom: 30,
            height: 20,
            width: deviceWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: map<Widget>(
                sliderList,
                (index, url) {
                  return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: _curSlider == index ? 30.0 : 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 4.0,),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primarytheme,),
                        borderRadius: BorderRadius.circular(20.0),
                        color: _curSlider == index
                            ? Theme.of(context).colorScheme.primarytheme
                            : Colors.transparent,
                      ),);
                },
              ),
            ),
          ),
          indicatorImage(data),
        ],
      ),
    );
  }

  Widget shareIcn(Product data) {
    return InkWell(
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.share,
              size: 25.0,
              color: Theme.of(context).colorScheme.primarytheme,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6.0),
              child: Text(
                getTranslated(context, 'SHARE_APP')!,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.fontColor),
              ),
            ),
          ],),
      onTap: () {
        createDynamicLink(data);
      },
    );
  }

  Widget compareIcn(Product data) {
    return InkWell(
        onTap: () {
          if (compareList.isNotEmpty) {
            if (compareList[0].categoryId == data.categoryId) {
              compareSheet(data);
            } else {
              catCompareDailog(data);
            }
          } else {
            compareSheet(data);
          }
        },
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.compare,
                size: 25.0,
                color: Theme.of(context).colorScheme.primarytheme,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 6.0),
                child: Text(
                  getTranslated(context, 'COMPARE_PRO')!,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: Theme.of(context).colorScheme.fontColor),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],),);
  }

  

  void loadMoreComPro() {
    setState(() {
      context.read<ProductDetailProvider>().setProNotiLoading(true);
      if (context.read<ProductDetailProvider>().offset <
          context.read<ProductDetailProvider>().total) getProduct1();
    });
  }

  void compareSheet(Product data) {
    final Product model = data;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25),),),
      builder: (builder) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: 365,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      height: 300,
                      padding: const EdgeInsetsDirectional.only(
                          top: 20.0, start: 10.0, end: 10.0,),
                      child: Selector<ProductDetailProvider, List<Product>>(
                        builder: (context, data, child) {
                          return data.isNotEmpty
                              ? ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemCount: data.length,
                                  itemBuilder: (context, index) {
                                    return ListItemCom(
                                      productList: data[index],
                                      isSelected: (bool value) {
                                        setState(() {
                                          if (value) {
                                            final extPro = compareList
                                                .firstWhereOrNull((cp) =>
                                                    cp.id == data[index].id,);
                                            if (extPro == null) {
                                              context
                                                  .read<ProductDetailProvider>()
                                                  .addCompareList(data[index]);
                                            }
                                          } else {
                                            compareList.removeWhere((item) =>
                                                item.id == data[index].id,);
                                          }
                                        });
                                      },
                                      key: Key(data[index].id.toString()),
                                      index: index,
                                      len: data.length,
                                      secPos: widget.secPos,
                                    );
                                  },
                                )
                              : shimmerCompare();
                        },
                        selector: (_, productDetailPro) =>
                            productDetailPro.productList,
                      ),),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        top: 10.0, bottom: 10.0,),
                    child: SimBtn(
                      width: 0.33,
                      height: 35,
                      title: getTranslated(context, 'COMPARE_LBL'),
                      onBtnSelected: () async {
                        final extPro = compareList
                            .firstWhereOrNull((cp) => cp.id == model.id);
                        if (extPro == null) {
                          context
                              .read<ProductDetailProvider>()
                              .addComFirstIndex(model);
                        } else {
                          compareList
                              .removeWhere((item) => item.id == model.id);
                          await context
                              .read<ProductDetailProvider>()
                              .addComFirstIndex(model);
                        }
                        setState(() {});
                        if (compareList.length > 1) {
                          await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (BuildContext context) =>
                                      const CompareList(),),);
                        } else {
                          setSnackbar(
                              getTranslated(
                                  context, 'PLS_SEL_ONE_MORE_PRO_LBL',)!,
                              context,);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  catCompareDailog(Product data) async {
    await dialogAnimate(context,
        StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),),
          content: Text(
            getTranslated(context, 'COMPARETEXTDIG')!,
            style: Theme.of(this.context)
                .textTheme
                .titleMedium!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          ),
          actions: <Widget>[
            TextButton(
                child: Text(
                  getTranslated(context, 'OPENLIST')!,
                  style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,),
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (BuildContext context) =>
                              const CompareList(),),);
                },),
            TextButton(
                child: Text(
                  getTranslated(context, 'CLEARLIST')!,
                  style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,),
                ),
                onPressed: () async {
                  context.read<ProductDetailProvider>().removeCompareList();
                  Navigator.of(context).pop(false);
                  await getProduct1().whenComplete(() {
                    compareSheet(data);
                  });
                },),
          ],
        );
      },);
    },),);
  }

  Widget favImg(Product data) {
    final Product model = data;
    return Selector<FavoriteProvider, List<String?>>(
      builder: (context, data, child) {
        return InkWell(
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: model.isFavLoading!
                        ? const SizedBox(
                            height: 25,
                            width: 25,
                          )
                        : Icon(
                            !data.contains(model.id)
                                ? Icons.favorite_border
                                : Icons.favorite,
                            key: ValueKey<bool>(data.contains(model.id)),
                            size: 25,
                            color: Theme.of(context).colorScheme.primarytheme,
                          ),),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6.0),
                  child: Text(
                    getTranslated(context, 'FAVORITE')!,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,),
                  ),
                ),
              ],),
          onTap: () {
            if (context.read<UserProvider>().userId != "") {
              !data.contains(model.id)
                  ? _setFav(-1, model)
                  : _removeFav(-1, model);
            } else {
              if (!data.contains(model.id)) {
                model.isFavLoading = true;
                model.isFav = "1";
                context.read<FavoriteProvider>().addFavItem(model);
                db.addAndRemoveFav(model.id!, true);
                model.isFavLoading = false;
              } else {
                model.isFavLoading = true;
                model.isFav = "0";
                context
                    .read<FavoriteProvider>()
                    .removeFavItem(model.prVarientList![0].id!);
                db.addAndRemoveFav(model.id!, false);
                model.isFavLoading = false;
              }
              setState(() {});
            }
          },
        );
      },
      selector: (_, provider) => provider.favIdList,
    );
  }

  indicatorImage(Product data) {
    final String? indicator = data.indicator;
    return Positioned.fill(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
          alignment: Alignment.bottomLeft,
          child: indicator == "1"
              ? SvgPicture.asset("assets/images/vag.svg")
              : indicator == "2"
                  ? SvgPicture.asset("assets/images/nonvag.svg")
                  : const SizedBox(),),
    ),);
  }

  _rate(Product data) {
    return data.noOfRating! != "0"
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RatingBarIndicator(
                  rating: double.parse(data.rating!),
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemSize: 12.0,
                ),
                Text(
                  " ${data.rating!}",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack,),
                ),
                Text(
                  " | ${data.noOfRating!} ${getTranslated(context, 'RATINGS')}",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack,),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget _inclusiveTaxText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        "(${getTranslated(context, 'EXCLU_TAX')})",
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).colorScheme.lightBlack2, fontSize: 12,),
      ),
    );
  }

  _price(int pos, bool from, Product data) {
  final Product model = data;
  // Calculate the base price (using discount price if available)
  double price = double.parse(model.prVarientList![pos].disPrice!);
  if (price == 0) {
    price = double.parse(model.prVarientList![pos].price!);
  }
  
  // Wrap the entire price row in a Consumer for FlashSaleProvider,
  // then nest a Consumer for CurrencyProvider for the price text.
  return Consumer<FlashSaleProvider>(
    builder: (context, flashSaleProvider, child) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Price Text using Currency Conversion:
            Consumer<CurrencyProvider>(
              builder: (context, currencyProvider, child) {
                // Determine which price to use:
                double finalPrice;
                if (widget.saleIndex != null) {
                  // For flash sale case:
                  if (flashSaleProvider.saleList[widget.saleIndex!].status == "1") {
                    finalPrice = double.parse(model.prVarientList![pos].saleFinalPrice!);
                  } else {
                    finalPrice = price;
                  }
                } else {
                  // Regular case:
                  if (model.isSalesOn == "1") {
                    finalPrice = double.parse(model.prVarientList![pos].saleFinalPrice!);
                  } else {
                    finalPrice = price;
                  }
                }
                // Convert the determined price using the selected currency.
                double convertedPrice = currencyProvider.convertPrice(finalPrice);
                return Text(
                  "${currencySymbol(currencyProvider.selectedCurrency)} ${convertedPrice.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,
                      ),
                );
              },
            ),
            // Cart Controls (unchanged)
            if (from)
              Selector<CartProvider, List<SectionModel>>(
                builder: (context, data, child) {
                  if (!qtyChange) {
                    final SectionModel? tempId = data.firstWhereOrNull((cp) =>
                        cp.id == model.id &&
                        cp.varientId == model.prVarientList![0].id!);
                    if (tempId != null) {
                      qtyController.text = tempId.qty!;
                    } else {
                      final String qty = model.prVarientList![model.selVarient!].cartCount!;
                      qtyController.text = (qty == "0")
                          ? model.minOrderQuntity.toString()
                          : qty;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(start: 3.0, bottom: 5, top: 3),
                    child: model.availability == "0"
                        ? const SizedBox()
                        : Row(
                            children: <Widget>[
                              InkWell(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.remove,
                                      size: 15,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  if (context.read<CartProvider>().isProgress == false &&
                                      (int.parse(qtyController.text)) > 1) {
                                    addAndRemoveQty(
                                      qtyController.text,
                                      2,
                                      model.itemsCounter!.length * int.parse(model.qtyStepSize!),
                                      int.parse(model.qtyStepSize!),
                                      model,
                                    );
                                  }
                                },
                              ),
                              Container(
                                width: 37,
                                height: 20,
                                color: Colors.transparent,
                                child: Stack(
                                  children: [
                                    TextField(
                                      textAlign: TextAlign.center,
                                      readOnly: true,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.fontColor),
                                      controller: qtyController,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: '',
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 1,
                                      ),
                                      onSelected: (String value) {
                                        if (context.read<CartProvider>().isProgress == false) {
                                          addAndRemoveQty(
                                            value,
                                            3,
                                            model.itemsCounter!.length * int.parse(model.qtyStepSize!),
                                            int.parse(model.qtyStepSize!),
                                            model,
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return model.itemsCounter!.map<PopupMenuItem<String>>((String value) {
                                          return PopupMenuItem(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.add,
                                      size: 15,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  print("counter*****${model.itemsCounter!.length}*******${model.qtyStepSize}");
                                  if (context.read<CartProvider>().isProgress == false) {
                                    addAndRemoveQty(
                                      qtyController.text,
                                      1,
                                      model.itemsCounter!.length * int.parse(model.qtyStepSize!),
                                      int.parse(model.qtyStepSize!),
                                      model,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                  );
                },
                selector: (_, provider) => provider.cartList,
              )
            else
              const SizedBox(),
          ],
        ),
      );
    },
  );
}


  _offPrice(pos, Product data) {
    final Product model = data;
    final double price = double.parse(model.prVarientList![pos].disPrice!);
    if (price != 0) {
      double off = double.parse(model.prVarientList![pos].price!) -
              double.parse(model.prVarientList![pos].disPrice!)
          ;
      off = off * 100 / double.parse(model.prVarientList![pos].price!);
      if (off != 0.00) {
        return Consumer<FlashSaleProvider>(
            builder: (context, dataModel, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (off != 0.00) _inclusiveTaxText(),
                Row(
                  children: <Widget>[
                    Text(
                      '${getPriceFormat(context, double.parse(model.prVarientList![pos].price!))!} ',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          decoration: TextDecoration.lineThrough,
                          letterSpacing: 0,
                          color: Theme.of(context)
                              .colorScheme
                              .fontColor
                              .withOpacity(0.7),),
                    ),
                    Text(
                        widget.saleIndex != null
                            ? dataModel.saleList[widget.saleIndex!].status ==
                                    "1"
                                ? "| ${model.saleDis!}% ${getTranslated(context, 'OFF_LBL')}"
                                : "| ${off.toStringAsFixed(2)}% ${getTranslated(context, 'OFF_LBL')}"
                            : model.isSalesOn == "1"
                                ? "| ${model.saleDis!}% ${getTranslated(context, 'OFF_LBL')}"
                                : "| ${off.toStringAsFixed(2)}% ${getTranslated(context, 'OFF_LBL')}",
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: Theme.of(context).colorScheme.primarytheme,
                            letterSpacing: 0,),),
                  ],
                ),
              ],
            ),
          );
        },);
      } else {
        return const SizedBox();
      }
    } else {
      return const SizedBox();
    }
  }

  Widget _title(Product data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Text(
          getTranslated(context, data.name!) ?? data.name!,

        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: Theme.of(context).colorScheme.lightBlack),
      ),
    );
  }

  _desc(Product data) {
    print("data description*****${data.desc!}");
    return data.desc!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: HtmlWidget(
               getTranslated(context, data.desc!) ?? data.desc!,
              onTapUrl: (String? url) async {
                if (await canLaunchUrl(Uri.parse(url!))) {
                  await launchUrl(Uri.parse(url));
                  return true;
                } else {
                  throw 'Could not launch $url';
                }
              },
              onErrorBuilder: (context, element, error) =>
                  Text('$element error: $error'),
              onLoadingBuilder: (context, element, loadingProgress) =>
                  showCircularProgress(
                      context, true, Theme.of(context).primaryColor,),
              textStyle:
                  TextStyle(color: Theme.of(context).colorScheme.fontColor),
            ),
          )
        : const SizedBox();
  }

  _getVarient(Product data) {
    final Product model = data;
    return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: Card(
          elevation: 0,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: model.attributeList!.length,
            itemBuilder: (context, index) {
              final List<Widget?> chips = [];
              final List<String> att = model.attributeList![index].value!.split(',');
              final List<String> attId = model.attributeList![index].id!.split(',');
              final List<String> attSType =
                  model.attributeList![index].sType!.split(',');
              final List<String> attSValue =
                  model.attributeList![index].sValue!.split(',');
              int? varSelected;
              final List<String> wholeAtt = model.attrIds!.split(',');
              for (int i = 0; i < att.length; i++) {
                Widget itemLabel;
                if (attSType[i] == '1') {
                  final String clr = attSValue[i].substring(1);
                  final String color = '0xff$clr';
                  itemLabel = Container(
                    width: 25,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Color(int.parse(color)),),
                  );
                } else if (attSType[i] == '2') {
                  itemLabel = ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(attSValue[i],
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) =>
                              erroWidget(context, 80),),);
                } else {
                  itemLabel = Text(att[i],
                      style: TextStyle(
                          color: _selectedIndex[index] == i
                              ? Theme.of(context).colorScheme.white
                              : Theme.of(context).colorScheme.fontColor,),);
                }
                if (_selectedIndex[index] != null &&
                    wholeAtt.contains(attId[i])) {
                  choiceChip = ChoiceChip(
                    selected: _selectedIndex.length > index
                        ? _selectedIndex[index] == i
                        : false,
                    label: itemLabel,
                    selectedColor: Theme.of(context).colorScheme.primarytheme,
                    backgroundColor: Theme.of(context).colorScheme.white,
                    labelPadding: const EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(attSType[i] == '1' ? 100 : 10),
                      side: BorderSide(
                          color: _selectedIndex[index] == i
                              ? Theme.of(context).colorScheme.primarytheme
                              : colors.black12,
                          width: 1.5,),
                    ),
                    onSelected: (bool selected) async {
                      if (att.length != 1) {
                        if (mounted) {
                          setState(() {
                            model.selVarient = _oldSelVarient;
                            available = false;
                            _selectedIndex[index] = i;
                            final List<int> selectedId = [];
                            final List<bool> check = [];
                            for (int i = 0;
                                i < model.attributeList!.length;
                                i++) {
                              final List<String> attId =
                                  model.attributeList![i].id!.split(',');
                              if (_selectedIndex[i] != null) {
                                selectedId
                                    .add(int.parse(attId[_selectedIndex[i]!]));
                              }
                            }
                            check.clear();
                            late List<String> sinId;
                            findMatch:
                            for (int i = 0;
                                i < model.prVarientList!.length;
                                i++) {
                              sinId = model
                                  .prVarientList![i].attribute_value_ids!
                                  .split(',');
                              for (int j = 0; j < selectedId.length; j++) {
                                if (sinId.contains(selectedId[j].toString())) {
                                  check.add(true);
                                  if (selectedId.length == sinId.length &&
                                      check.length == selectedId.length) {
                                    varSelected = i;
                                    selectIndex = i;
                                    break findMatch;
                                  }
                                } else {
                                  check.clear();
                                  selectIndex = null;
                                  break;
                                }
                              }
                            }
                            if (selectedId.length == sinId.length &&
                                check.length == selectedId.length) {
                              if (model.stockType == '0' ||
                                  model.stockType == '1') {
                                if (model.availability == '1') {
                                  available = true;
                                  outOfStock = false;
                                  _oldSelVarient = varSelected!;
                                } else {
                                  available = false;
                                  outOfStock = true;
                                }
                              } else if (model.stockType == '') {
                                available = true;
                                outOfStock = false;
                                _oldSelVarient = varSelected!;
                              } else if (model.stockType == '2') {
                                if (model.prVarientList![varSelected!]
                                        .availability ==
                                    '1') {
                                  available = true;
                                  outOfStock = false;
                                  _oldSelVarient = varSelected!;
                                } else {
                                  available = false;
                                  outOfStock = true;
                                }
                              }
                            } else {
                              available = false;
                              outOfStock = false;
                            }
                            if (model.prVarientList![_oldSelVarient].images!
                                .isNotEmpty) {
                              int oldVarTotal = 0;
                              if (_oldSelVarient > 0) {
                                for (int i = 0; i < _oldSelVarient; i++) {
                                  oldVarTotal = oldVarTotal +
                                      model.prVarientList![i].images!.length;
                                }
                              }
                              final int p =
                                  model.otherImage!.length + 1 + oldVarTotal;
                              _pageController.jumpToPage(p);
                            }
                          });
                        } else {}
                      }
                      if (available!) {
                        if (context.read<UserProvider>().userId != "") {
                          if (model.prVarientList![_oldSelVarient].cartCount! !=
                              "0") {
                            qtyController.text =
                                model.prVarientList![_oldSelVarient].cartCount!;
                            qtyChange = true;
                          } else {
                            qtyController.text =
                                model.minOrderQuntity.toString();
                            qtyChange = true;
                          }
                        } else {
                          final String qty = (await db.checkCartItemExists(model.id!,
                              model.prVarientList![_oldSelVarient].id!,))!;
                          if (qty == "0") {
                            qtyController.text =
                                model.minOrderQuntity.toString();
                            qtyChange = true;
                          } else {
                            model.prVarientList![_oldSelVarient].cartCount =
                                qty;
                            qtyController.text = qty;
                            qtyChange = true;
                          }
                        }
                      }
                    },
                  );
                  chips.add(choiceChip);
                }
              }

              return chips.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "${model.attributeList![index].name!} ",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold,),
                          ),
                          Wrap(
                            children: chips.map<Widget>((Widget? chip) {
                              return Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: chip,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox();
            },
          ),
        ),);
  }

  void _pincodeCheck(Product data) {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25),),),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,),
              child: ListView(shrinkWrap: true, children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 30,),
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,),
                      child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(Icons.close),
                                ),
                              ),
                              TextFormField(
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.words,
                                validator: (val) => validatePincode(val!,
                                    getTranslated(context, 'PIN_REQUIRED'),),
                                onSaved: (String? value) {
                                  if (value != null) curPin = value;
                                },
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,),
                                decoration: InputDecoration(
                                  isDense: false,
                                  prefixIcon: const Icon(Icons.location_on),
                                  hintText:
                                      getTranslated(context, 'PINCODEHINT_LBL'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SimBtn(
                                    width: 1.0,
                                    height: 35,
                                    title: getTranslated(context, 'APPLY'),
                                    onBtnSelected: () async {
                                      if (validateAndSave()) {
                                        if (IS_SHIPROCKET_ON == "1") {
                                          log("Calling SHip Rocket");
                                          validatePinFromShipRocket(
                                              curPin, true, data,);
                                        } else {
                                          log("Calling normal pin");
                                          validatePin(curPin, false, data);
                                        }
                                      }
                                    },),
                              ),
                            ],
                          ),),
                    ),),
              ],),
            );
          },);
        },);
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  addAndRemoveQty(
      String qty, int from, int totalLen, int itemCounter, Product data,) {
    final Product model1 = data;
    print("totallen****$totalLen");
    if (context.read<UserProvider>().userId != "") {
      if (from == 1) {
        if (int.parse(qty) >= totalLen) {
          qtyController.text = totalLen.toString();
          setSnackbar("${getTranslated(context, 'MAXQTY')!}  $qty", context);
        } else {
          qtyController.text = (int.parse(qty) + itemCounter).toString();
          qtyChange = true;
        }
      } else if (from == 2) {
        if (int.parse(qty) <= model1.minOrderQuntity!) {
          qtyController.text = itemCounter.toString();
          qtyChange = true;
        } else {
          qtyController.text = (int.parse(qty) - itemCounter).toString();
          qtyChange = true;
        }
      } else {
        qtyController.text = qty;
        qtyChange = true;
      }
      if (context.read<CartProvider>().cartList.any((element) =>
          element.varientId == data.prVarientList![_oldSelVarient].id,)) {
        setSnackbar(
            "${getTranslated(context, "CANT_INCREASE_QNT_AFTER_ADD_IN_CART")}",
            context,);
        qtyController.text = qty;
        qtyChange = false;
      }
      context.read<CartProvider>().setProgress(false);
      setState(() {});
    } else {
      if (from == 1) {
        if (int.parse(qty) >= totalLen) {
          qtyController.text = totalLen.toString();
          setSnackbar("${getTranslated(context, 'MAXQTY')!}  $qty", context);
        } else {
          qtyController.text = (int.parse(qty) + itemCounter).toString();
          qtyChange = true;
        }
      } else if (from == 2) {
        if (int.parse(qty) <= model1.minOrderQuntity!) {
          qtyController.text = itemCounter.toString();
          qtyChange = true;
        } else {
          qtyController.text = (int.parse(qty) - itemCounter).toString();
          qtyChange = true;
        }
      } else {
        qtyController.text = qty;
        qtyChange = true;
      }
      if (context.read<CartProvider>().cartList.any((element) =>
          element.varientId == data.prVarientList![_oldSelVarient].id,)) {
        setSnackbar(
            "${getTranslated(context, "CANT_INCREASE_QNT_AFTER_ADD_IN_CART")}",
            context,);
        qtyController.text = qty;
        qtyChange = false;
      }
      context.read<CartProvider>().setProgress(false);
      setState(() {});
    }
  }

  Future<void> addToCart(
      String qty, bool intent, bool from, Product product,) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        final Product model1 = product;
        setState(() {
          qtyChange = true;
        });
        if (context.read<UserProvider>().userId != "") {
          try {
            if (mounted) {
              setState(() {
                context.read<CartProvider>().setProgress(true);
              });
            }
            if (int.parse(qty) < model1.minOrderQuntity!) {
              qty = model1.minOrderQuntity.toString();
              setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
            }
            final parameter = {
              USER_ID: context.read<UserProvider>().userId,
              PRODUCT_VARIENT_ID: model1.prVarientList![_oldSelVarient].id,
              QTY: qty,
            };
            apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
              final bool error = getdata["error"];
              final String? msg = getdata["message"];
              if (!error) {
                final data = getdata["data"];
                model1.prVarientList![_oldSelVarient].cartCount =
                    qty;
                if (from) {
                  context.read<UserProvider>().setCartCount(data['cart_count']);
                  final cart = getdata["cart"];
                  List<SectionModel> cartList = [];
                  cartList = (cart as List)
                      .map((cart) => SectionModel.fromCart(cart))
                      .toList();
                  context.read<CartProvider>().setCartlist(cartList);
                  if (intent) {
                    cartTotalClear();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const Cart(
                          fromBottom: false,
                        ),
                      ),
                    );
                  } else {
                    setSnackbar(getTranslated(context, 'PRO_ADD_TO_CART_LBL')!,
                        context,);
                  }
                }
              } else {
                setSnackbar(msg!, context);
              }
              if (mounted) {
                setState(() {
                  context.read<CartProvider>().setProgress(false);
                });
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            },);
          } on TimeoutException catch (_) {
            setSnackbar(getTranslated(context, 'somethingMSg')!, context);
            if (mounted) {
              setState(() {
                context.read<CartProvider>().setProgress(false);
              });
            }
          }
        } else {
          final int cartCount = await db.getTotalCartCount(context);
          if (int.parse(MAX_ITEMS!) > cartCount) {
            final bool add = await db.insertCart(
                model1.id!,
                model1.prVarientList![_oldSelVarient].id!,
                qty,
                model1.productType!,
                context,);
            if (add) {
              final List<Product> prList = [];
              prList.add(model1);
              context.read<CartProvider>().addCartItem(SectionModel(
                    qty: qty,
                    productList: prList,
                    varientId: model1.prVarientList![_oldSelVarient].id,
                    id: model1.id,
                  ),);
              Future.delayed(const Duration(milliseconds: 100)).then((_) async {
                if (from && intent) {
                  cartTotalClear();
                  await Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const Cart(
                        fromBottom: false,
                      ),
                    ),
                  );
                } else {
                  setSnackbar(
                      getTranslated(context, 'PRO_ADD_TO_CART_LBL')!, context,);
                }
              });
            }
          } else {
            setSnackbar(
                "In Cart maximum ${int.parse(MAX_ITEMS!)} product allowed",
                context,);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> getReview() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          final parameter = {
            PRODUCT_ID: productData!.id,
            LIMIT: perPage.toString(),
            OFFSET: offset.toString(),
          };
          apiBaseHelper.postAPICall(getRatingApi, parameter).then((getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (!error) {
              total = int.parse(getdata["total"]);
              star1 = getdata["star_1"];
              star2 = getdata["star_2"];
              star3 = getdata["star_3"];
              star4 = getdata["star_4"];
              star5 = getdata["star_5"];
              final data = getdata["data"];
              reviewList =
                  (data as List).map((data) => User.forReview(data)).toList();
              print("offset12****$offset***$total******${reviewList.length}");
            } else {
              if (msg != "No ratings found !") setSnackbar(msg!, context);
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
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  _setFav(int index, Product data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (mounted) {
            setState(() {
              index == -1
                  ? data.isFavLoading = true
                  : productList[index].isFavLoading = true;
            });
          }
          final parameter = {
            USER_ID: context.read<UserProvider>().userId,
            PRODUCT_ID: data.id,
          };
          apiBaseHelper.postAPICall(setFavoriteApi, parameter).then((getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (!error) {
              index == -1 ? data.isFav = "1" : productList[index].isFav = "1";
              context.read<FavoriteProvider>().addFavItem(data);
            } else {
              setSnackbar(msg!, context);
            }
            if (mounted) {
              setState(() {
                index == -1
                    ? data.isFavLoading = false
                    : productList[index].isFavLoading = false;
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          },);
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  _removeFav(int index, Product data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (mounted) {
            setState(() {
              index == -1
                  ? data.isFavLoading = true
                  : productList[index].isFavLoading = true;
            });
          }
          final parameter = {
            USER_ID: context.read<UserProvider>().userId,
            PRODUCT_ID: data.id,
          };
          apiBaseHelper.postAPICall(removeFavApi, parameter).then((getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (!error) {
              index == -1 ? data.isFav = "0" : productList[index].isFav = "0";
              context
                  .read<FavoriteProvider>()
                  .removeFavItem(data.prVarientList![0].id!);
            } else {
              setSnackbar(msg!, context);
            }
            if (mounted) {
              setState(() {
                index == -1
                    ? data.isFavLoading = false
                    : productList[index].isFavLoading = false;
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          },);
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  _showContent() {
    try {
      if (productData != null && isLoadedAll) {
        final Product data = productData!;
        return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Expanded(
              child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * .43,
                  pinned: true,
                  backgroundColor: Theme.of(context).colorScheme.white,
                  stretch: true,
                  leading: Builder(builder: (BuildContext context) {
                    return Container(
                      margin: const EdgeInsets.all(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => Navigator.of(context).pop(),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Theme.of(context).colorScheme.primarytheme,
                          ),
                        ),
                      ),
                    );
                  },),
                  actions: [
                    IconButton(
                        icon: SvgPicture.asset(
                          "${imagePath}search.svg",
                          height: 20,
                          colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.primarytheme,
                              BlendMode.srcIn,),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, Routers.searchScreen);
                        },),
                    IconButton(
                        icon: SvgPicture.asset(
                          "${imagePath}desel_fav.svg",
                          height: 20,
                          colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.primarytheme,
                              BlendMode.srcIn,),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, Routers.favoriteScreen);
                        },),
                    Selector<UserProvider, String>(
                      builder: (context, data, child) {
                        return IconButton(
                          icon: Stack(
                            children: [
                              Center(
                                  child: SvgPicture.asset(
                                "${imagePath}appbarCart.svg",
                                colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.primarytheme,
                                    BlendMode.srcIn,),
                              ),),
                              if (data != "" && data.isNotEmpty && data != "0") Positioned(
                                      bottom: 20,
                                      right: 0,
                                      child: Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primarytheme,),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: Text(
                                                data,
                                                style: TextStyle(
                                                    fontSize: 7,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .white,),
                                              ),
                                            ),
                                          ),),
                                    ) else const SizedBox(),
                            ],
                          ),
                          onPressed: () {
                            cartTotalClear();
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const Cart(
                                  fromBottom: false,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      selector: (_, homeProvider) => homeProvider.curCartCount,
                    ),
                  ],
                  title: Text(
                    getTranslated(context, data.name!) ?? data.name!,
                    maxLines: 1,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primarytheme,
                        fontWeight: FontWeight.normal,),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _slider(data),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        showBtn(data),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              elevation: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _title(data),
                                  _rate(data),
                                  _price(_oldSelVarient, true, data),
                                  _offPrice(_oldSelVarient, data),
                                  _brandName(data),
                                  _shortDesc(data),
                                ],
                              ),
                            ),
                            _getVarient(data),
                            _specification(data),
                            _speciExtraBtnDetails(data),
                            _flashSaleWidget(data),
                            _deliverPincode(data),
                          ],
                        ),
                        if (reviewList.isNotEmpty) Card(
                                elevation: 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _reviewTitle(data),
                                    _reviewStar(data),
                                    _reviewImg(data),
                                    _review(),
                                  ],
                                ),
                              ) else const SizedBox(),
                        faqsQuesAndAns(data),
                        if (productList.isNotEmpty) Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  getTranslated(context, 'MORE_PRODUCT')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,),
                                ),
                              ) else const SizedBox(),
                        if (productList.isNotEmpty) Container(
                                height: 230,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: NotificationListener<ScrollNotification>(
                                    onNotification:
                                        (ScrollNotification scrollInfo) {
                                      if (scrollInfo.metrics.pixels ==
                                          scrollInfo.metrics.maxScrollExtent) {
                                        getProduct();
                                      }
                                      return true;
                                    },
                                    child: ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemCount:
                                          (notificationoffset < totalProduct)
                                              ? productList.length + 1
                                              : productList.length,
                                      itemBuilder: (context, index) {
                                        return (index == productList.length &&
                                                !notificationisloadmore)
                                            ? simmerSingle()
                                            : productItemView(
                                                index,
                                                productList,
                                                context,
                                                detailHero,);
                                      },
                                    ),),) else Container(
                                height: 0,
                              ),
                        _mostFav(),
                      ],
                    ),
                  ]),
                ),
              ],),),
          if (data.attributeList!.isEmpty) data.availability != "0"
                  ? Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.white,
                        boxShadow: [
                          BoxShadow(
                              color: Theme.of(context).colorScheme.black26,
                              blurRadius: 10,),
                        ],
                      ),
                      child: Consumer<CartProvider>(
                        builder: (context, value, child) =>
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          if (value.cartList.any((element) =>
                              element.varientId ==
                              data.prVarientList![_oldSelVarient].id,)) ...[
                            Expanded(
                                child: SimBtn(
                              width: 10,
                              height: 55,
                              title: getTranslated(context, 'VIEWINCART'),
                              onBtnSelected: () => Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) =>
                                          const Cart(fromBottom: false),),),
                            ),),
                          ] else ...[
                            Expanded(
                                child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                              ),
                              child: InkWell(
                                onTap: !context.read<CartProvider>().isProgress
                                    ? () {
                                        String qty;
                                        qty = qtyController.text;
                                        addToCart(qty, false, true, data);
                                      }
                                    : () {},
                                child: Center(
                                    child: Text(
                                  getTranslated(context, 'ADD_CART')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primarytheme,),
                                ),),
                              ),
                            ),),
                            Expanded(
                                child: SimBtn(
                                    width: 0.8,
                                    height: 55,
                                    title: getTranslated(context, 'BUYNOW'),
                                    onBtnSelected: !context
                                            .read<CartProvider>()
                                            .isProgress
                                        ? () async {
                                            String qty;
                                            qty = qtyController.text;
                                            addToCart(qty, true, true, data);
                                          }
                                        : () {},),),
                          ],
                        ],),
                      ),)
                  : Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.white,
                        boxShadow: [
                          BoxShadow(
                              color: Theme.of(context).colorScheme.black26,
                              blurRadius: 10,),
                        ],
                      ),
                      child: Center(
                          child: Text(
                        getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.red,),
                      ),),
                    ) else available!
                  ? Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.white,
                        boxShadow: [
                          BoxShadow(
                              color: Theme.of(context).colorScheme.black26,
                              blurRadius: 10,),
                        ],
                      ),
                      child: Consumer<CartProvider>(
                          builder: (context, value, child) =>
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                if (value.cartList.any((element) =>
                                    element.varientId ==
                                    data.prVarientList![_oldSelVarient]
                                        .id,)) ...[
                                  Expanded(
                                      child: SimBtn(
                                          width: 10,
                                          height: 55,
                                          title: getTranslated(
                                              context, 'VIEWINCART',),
                                          onBtnSelected: () => Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                  builder: (context) =>
                                                      const Cart(
                                                          fromBottom: false,),),),),),
                                ] else ...[
                                  Expanded(
                                      child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    ),
                                    child: InkWell(
                                      onTap: !context
                                              .read<CartProvider>()
                                              .isProgress
                                          ? () {
                                              String qty;
                                              qty = qtyController.text;
                                              addToCart(qty, false, true, data);
                                            }
                                          : () {},
                                      child: Center(
                                          child: Text(
                                        getTranslated(context, 'ADD_CART')!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge!
                                            .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primarytheme,),
                                      ),),
                                    ),
                                  ),),
                                  Expanded(
                                      child: SimBtn(
                                          width: 0.8,
                                          height: 55,
                                          title:
                                              getTranslated(context, 'BUYNOW'),
                                          onBtnSelected: !context
                                                  .read<CartProvider>()
                                                  .isProgress
                                              ? () async {
                                                  String qty;
                                                  qty = qtyController.text;
                                                  addToCart(
                                                      qty, true, true, data,);
                                                }
                                              : () {},),),
                                ],
                              ],),),
                    )
                  : available == false || outOfStock == true
                      ? outOfStock == true
                          ? Container(
                              height: 55,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Theme.of(context).colorScheme.black26,
                                      blurRadius: 10,),
                                ],
                              ),
                              child: Center(
                                  child: Text(
                                getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,),
                              ),),
                            )
                          : Container(
                              height: 55,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Theme.of(context).colorScheme.black26,
                                      blurRadius: 10,),
                                ],
                              ),
                              child: Center(
                                  child: Text(
                                getTranslated(context, 'VAR_NT_AVAIL_LBL')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,),
                              ),),
                            )
                      : const SizedBox(),
        ],);
      } else {
        return detailshimmer();
      }
    } catch (e) {
      return Container();
    }
  }

  postQues(Product data) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(getTranslated(context, 'HAVE_DOUBTS_REG_THIS_PRO_LBL')!,
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.fontColor,),),
          Padding(
              padding: const EdgeInsetsDirectional.only(top: 10, bottom: 5),
              child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    openPostQueBottomSheet(data);
                  },
                  child: Container(
                      width: double.maxFinite,
                      height: 38.5,
                      alignment: FractionalOffset.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .lightBlack
                                .withOpacity(0.4),),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)),
                      ),
                      child: Text(getTranslated(context, 'POST_YR_QUE_LBL')!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.bold,
                              ),),),),),
        ],
      ),
    );
  }

  void openPostQueBottomSheet(Product data) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0),),),
        isScrollControlled: true,
        context: context,
        backgroundColor: Theme.of(context).colorScheme.white,
        builder: (BuildContext context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,),
                child: Form(
                  key: faqsKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      bottomSheetHandle(context),
                      Padding(
                          padding: const EdgeInsets.only(top: 30.0, bottom: 20),
                          child: Text(
                            getTranslated(context, 'WRITE_QUE_LBL')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor,),
                          ),),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(top: 10.0),
                          child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 20, end: 20,),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.25,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightWhite,),
                                    child: TextFormField(
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 14.0,),
                                      onChanged: (value) {},
                                      onSaved: (String? val) {},
                                      maxLines: null,
                                      validator: (val) {
                                        if (val!.isEmpty) {
                                          return getTranslated(
                                              context, 'PLS_PRO_MORE_DET_LBL',);
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: getTranslated(
                                            context, 'TYPE_YR_QUE_LBL',),
                                        contentPadding:
                                            const EdgeInsetsDirectional.all(
                                                25.0,),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .lightWhite,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            borderSide: const BorderSide(
                                                width: 0.0,
                                                style: BorderStyle.none,),),
                                      ),
                                      keyboardType: TextInputType.multiline,
                                      controller: edtFaqs,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.all(20),
                                  child: SimBtn(
                                    title: getTranslated(context, 'SUBMIT_LBL'),
                                    height: 45,
                                    width: deviceWidth,
                                    onBtnSelected: !context
                                            .read<CartProvider>()
                                            .isProgress
                                        ? () {
                                            final form = faqsKey.currentState!;
                                            form.save();
                                            if (form.validate()) {
                                              FocusScope.of(context).unfocus();
                                              context
                                                  .read<CartProvider>()
                                                  .setProgress(true);
                                              setFaqsQue(data);
                                            }
                                          }
                                        : () {},
                                  ),
                                ),
                              ],),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },);
  }

  faqsQuesAndAns(Product data) {
    return Card(
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _faqsQue(),
          if (context.read<UserProvider>().userId != "") postQues(data) else const SizedBox(),
          if (faqsProductList.isNotEmpty) _allQuesBtn(data),
        ],
      ),
    );
  }

  _allQuesBtn(Product data) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, bottom: 10, right: 5),
      child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, Routers.faqProductScreen,
                arguments: {"id": data.id},);
          },
          child: Row(
            children: [
              Text(
                getTranslated(context, 'ALL_QUE_LBL')!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold,),
              ),
              const Spacer(),
              Icon(
                Icons.keyboard_arrow_right,
                color: Theme.of(context).colorScheme.primarytheme,
              ),
            ],
          ),),
    );
  }

  showBtn(Product data) {
  return Padding(
    padding: const EdgeInsetsDirectional.only(top: 5.0),
    child: Card(
      elevation: 0,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsetsDirectional.only(
            start: 5, end: 5, top: 5.0, bottom: 5.0,),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          runSpacing: 10,
          children: [
            favImg(data),
            shareIcn(data),
            compareIcn(data),
          ],
        ),
      ),
    ),
  );
}


  simmerSingle() {
    return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.simmerBase,
          highlightColor: Theme.of(context).colorScheme.simmerHigh,
          child: Container(
            width: deviceWidth! * 0.45,
            height: 250,
            color: Theme.of(context).colorScheme.white,
          ),
        ),);
  }

  shimmerCompare() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.gray,
      highlightColor: Theme.of(context).colorScheme.gray,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, __) => Padding(
            padding: const EdgeInsetsDirectional.only(start: 8.0),
            child: Container(
              width: deviceWidth! * 0.45,
              height: 255,
              color: Theme.of(context).colorScheme.white,
            ),),
        itemCount: 10,
      ),
    );
  }

  _madeIn(Product data) {
    final String? madeIn = data.madein;
    return madeIn != "" && madeIn!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              trailing: Text(madeIn),
              dense: true,
              title: Text(
                getTranslated(context, 'MADE_IN')!,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          )
        : const SizedBox();
  }

  Widget _faqsQue() {
    return _isFaqsLoading
        ? const Center(child: CircularProgressIndicator())
        : faqsProductList.isNotEmpty
            ? Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 20, end: 20, top: 12, bottom: 10,),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(getTranslated(context, 'QUE_ANS_LBL')!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  fontWeight: FontWeight.bold,),),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            itemCount: faqsProductList.length >= 5
                                ? 5
                                : faqsProductList.length,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(),
                            itemBuilder: (context, index) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${getTranslated(context, 'Q_LBL')}: ${faqsProductList[index].question!}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontSize: 12.5,),
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "${getTranslated(context, 'A_LBL')}: ${faqsProductList[index].answer!}",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .lightBlack,
                                            fontSize: 11,),
                                      ),),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      faqsProductList[index].uname!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack2,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack
                                              .withOpacity(0.8),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  start: 3.0,),
                                          child: Text(
                                            faqsProductList[index].ansBy!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack
                                                    .withOpacity(0.5),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },),
                      ),
                    ],),
              )
            : const SizedBox();
  }

  Widget _review() {
    print("_reviewlist--->${reviewList.length}");
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            itemCount: reviewList.length >= 2 ? 2 : reviewList.length,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
            itemBuilder: (context, index) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reviewList[index].username!,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                      const Spacer(),
                      Text(
                        reviewList[index].date!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack,
                            fontSize: 11,),
                      ),
                    ],
                  ),
                  RatingBarIndicator(
                    rating: double.parse(reviewList[index].rating!),
                    itemBuilder: (context, index) => Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.primarytheme,
                    ),
                    itemSize: 12.0,
                  ),
                  if (reviewList[index].comment != "" &&
                          reviewList[index].comment!.isNotEmpty) Text(
                          reviewList[index].comment ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ) else const SizedBox(),
                  reviewImage(index),
                ],
              );
            },);
  }

  Future<void> getProductFaqs() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          final parameter = {
            PRODUCT_ID: productData!.id,
            LIMIT: perPage.toString(),
            OFFSET: faqsOffset.toString(),
          };
          apiBaseHelper.postAPICall(getProductFaqsApi, parameter).then(
              (getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (!error) {
              faqsTotal = int.parse(getdata["total"]);
              if (faqsOffset < faqsTotal) {
                final data = getdata["data"];
                faqsProductList = (data as List)
                    .map((data) => FaqsModel.fromJson(data))
                    .toList();
                faqsOffset = faqsOffset + perPage;
              }
            } else {
              if (msg == "FAQs does not exist") {}
            }
            if (mounted) {
              setState(() {
                _isFaqsLoading = false;
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          },);
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              _isFaqsLoading = false;
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
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future getProduct() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (notificationisloadmore) {
            if (mounted) {
              setState(() {
                notificationisloadmore = false;
                notificationisgettingdata = true;
                if (notificationoffset == 0) {
                  productList = [];
                }
              });
            }
            final parameter = {
              CATID: productData!.categoryId,
              LIMIT: perPage.toString(),
              OFFSET: notificationoffset.toString(),
              ID: productData!.id,
              IS_SIMILAR: "1",
            };
            if (context.read<UserProvider>().userId != "") {
              parameter[USER_ID] = context.read<UserProvider>().userId;
            }
            apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
              final bool error = getdata["error"];
              notificationisgettingdata = false;
              if (notificationoffset == 0) notificationisnodata = error;
              if (!error) {
                totalProduct = int.parse(getdata["total"]);
                if (mounted) {
                  Future.delayed(
                      Duration.zero,
                      () => setState(() {
                            final List mainlist = getdata['data'];
                            if (mainlist.isNotEmpty) {
                              final List<Product> items = [];
                              final List<Product> allitems = [];
                              items.addAll(mainlist
                                  .map((data) => Product.fromJson(data))
                                  .toList(),);
                              allitems.addAll(items);
                              for (final Product item in items) {
                                productList
                                    .where((i) => i.id == item.id)
                                    .map((obj) {
                                  allitems.remove(item);
                                  return obj;
                                }).toList();
                              }
                              productList.addAll(allitems);
                              notificationisloadmore = true;
                              notificationoffset = notificationoffset + perPage;
                            } else {
                              notificationisloadmore = false;
                            }
                          }),);
                }
              } else {
                notificationisloadmore = false;
                if (mounted) if (mounted) setState(() {});
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            },);
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              notificationisloadmore = false;
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
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> getProductDetails() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {"product_ids": widget.id, ISDETAILEDDATA: '1'};
        print("details parameter: $parameter");
        if (context.read<UserProvider>().userId != "") {
          parameter[USER_ID] = context.read<UserProvider>().userId;
        }
        apiBaseHelper.postAPICall(getProductApi, parameter).then(
            (getdata) async {
          final bool error = getdata["error"];
          if (!error) {
            final List mainlist = getdata['data'];
            if (mainlist.isNotEmpty) {
              final List<Product> items = [];
              items.addAll(
                  mainlist.map((data) => Product.fromJson(data)).toList(),);
              setState(() {
                productData = items[0];
                _isLoading = false;
              });
              log(productData.toString(), name: "Whole product log");
              allApiAndFun();
              setState(() {
                isLoadedAll = true;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                context.read<ProductDetailProvider>().setProNotiLoading(false);
              });
            }
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(() {
            context.read<ProductDetailProvider>().setProNotiLoading(false);
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

  Future<void> getProduct1() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          CATID: productData!.categoryId,
          ID: productData!.id,
          IS_SIMILAR: "1",
        };
        if (navigatorKey.currentContext!.read<UserProvider>().userId != "") {
          parameter[USER_ID] =
              navigatorKey.currentContext!.read<UserProvider>().userId;
        }
        apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
          final bool error = getdata["error"];
          if (!error) {
            navigatorKey.currentContext!
                .read<ProductDetailProvider>()
                .setProTotal(int.parse(getdata["total"]));
            final List mainlist = getdata['data'];
            if (mainlist.isNotEmpty) {
              final List<Product> items = [];
              final List<Product> allitems = [];
              productList1 = [];
              items.addAll(
                  mainlist.map((data) => Product.fromJson(data)).toList(),);
              allitems.addAll(items);
              for (final Product item in items) {
                productList1.where((i) => i.id == item.id).map((obj) {
                  allitems.remove(item);
                  return obj;
                }).toList();
              }
              productList1.addAll(allitems);
              navigatorKey.currentContext!
                  .read<ProductDetailProvider>()
                  .setProductList(productList1);
              navigatorKey.currentContext!
                  .read<ProductDetailProvider>()
                  .setProOffset(navigatorKey.currentContext!
                          .read<ProductDetailProvider>()
                          .offset +
                      perPage,);
            }
          } else {
            if (mounted) {
              setState(() {
                navigatorKey.currentContext!
                    .read<ProductDetailProvider>()
                    .setProNotiLoading(false);
              });
            }
          }
        }, onError: (error) {
          setSnackbar(error.toString(), navigatorKey.currentContext!);
        },);
      } on TimeoutException catch (_) {
        setSnackbar(
            getTranslated(navigatorKey.currentContext!, 'somethingMSg')!,
            navigatorKey.currentContext!,);
        if (mounted) {
          setState(() {
            navigatorKey.currentContext!
                .read<ProductDetailProvider>()
                .setProNotiLoading(false);
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

  _specification(Product data) {
    final Product model = data;
    return model.desc!.isNotEmpty ||
            model.attributeList!.isNotEmpty ||
            model.madein != "" && model.madein!.isNotEmpty
        ? Card(
            elevation: 0,
            child: InkWell(
              child: Column(children: [
                ListTile(
                  dense: true,
                  title: Text(
                    getTranslated(context, 'SPECIFICATION')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack,),
                  ),
                  trailing: InkWell(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        !seeView ? Icons.add : Icons.remove,
                        size: 10,
                        color: Theme.of(context).colorScheme.primarytheme,
                      ),
                      Padding(
                          padding: const EdgeInsetsDirectional.only(start: 2.0),
                          child: Text(
                              !seeView
                                  ? getTranslated(context, 'MORE_LBL')!
                                  : getTranslated(context, 'LESS_LBL')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primarytheme,),),),
                    ],),
                    onTap: () {
                      setState(() {
                        seeView = !seeView;
                      });
                    },
                  ),
                ),
                if (!seeView) SizedBox(
                        height: 70,
                        width: deviceWidth! - 10,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _desc(data),
                                if (model.desc!.isNotEmpty) const Divider(
                                        height: 3.0,
                                      ) else const SizedBox(),
                                _attr(data),
                                if (model.madein != "" && model.madein!.isNotEmpty) const Divider() else const SizedBox(),
                                _madeIn(data),
                              ],),
                        ),) else Padding(
                        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _desc(data),
                              if (model.desc!.isNotEmpty) const Divider(
                                      height: 3.0,
                                    ) else const SizedBox(),
                              _attr(data),
                              if (model.madein != "" && model.madein!.isNotEmpty) const Divider() else const SizedBox(),
                              _madeIn(data),
                            ],),
                      ),
              ],),
            ),
          )
        : const SizedBox();
  }

  void setupChannel() {
    streamController = StreamController<int>.broadcast();
  }

  _flashSaleWidget(Product data) {
    final Product model = data;
    print("is flash sale on ${model.isSalesOn}");
    return widget.saleIndex != null
        ? Consumer<FlashSaleProvider>(builder: (context, dataModel, child) {
            return dataModel.saleList[widget.saleIndex!].status == "1" ||
                    dataModel.saleList[widget.saleIndex!].status == "2"
                ? MultipleTimer(
                    startDateModel:
                        dataModel.saleList[widget.saleIndex!].startDate!,
                    endDateModel:
                        dataModel.saleList[widget.saleIndex!].endDate!,
                    serverDateModel:
                        dataModel.saleList[widget.saleIndex!].serverTime!,
                    id: dataModel.saleList[widget.saleIndex!].id!,
                    newtimeDiff:
                        dataModel.saleList[widget.saleIndex!].timeDiff!,
                    from: 2,
                  )
                : const SizedBox();
          },)
        : model.isSalesOn == "1" || model.isSalesOn == "2"
            ? Builder(builder: (context) {
                return MultipleTimer(
                  startDateModel: model.saleStartDate!,
                  endDateModel: model.saleEndDate!,
                  serverDateModel: model.serverTime!,
                  id: "0",
                  newtimeDiff: model.timeDiff!,
                  from: 2,
                  inDetails: true,
                );
              },)
            : const SizedBox();
  }

  _deliverPincode(Product data) {
    if (data.productType != 'digital_product') {
      String pin = context.read<UserProvider>().curPincode;
      if (isCityWiseDelivery!) {
        pin = "";
      }
      print("delievery date****$deliveryDate");
      return Card(
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                _pincodeCheck(data);
              },
              child: ListTile(
                dense: true,
                title: Text(
                  getTranslated(context, 'DELIVERTO')!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack,),
                ),
                trailing: Icon(
                  Icons.keyboard_arrow_right,
                  color: Theme.of(context).colorScheme.primarytheme,
                ),
              ),
            ),
            if (deliveryMsg != '')
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                ),
                child: Text(deliveryMsg,
                    style: const TextStyle(color: Colors.red, fontSize: 12),),
              ),
            if (deliveryDate != '') const Divider(),
            if (deliveryDate != '')
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                child: Row(
                  children: [
                    Text("${getTranslated(context, 'DELIVERY_DAY_LBL')}: ",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2,
                        ),),
                    Text(
                      deliveryDate,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (codDeliveryCharges != '')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 5.0,),
                    child: Row(
                      children: [
                        Text("${getTranslated(context, 'COD_CHARGE_LBL')}: ",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2,
                            ),),
                        Text(
                            "${getPriceFormat(context, double.parse(codDeliveryCharges))}",),
                        const SizedBox(width: 25),
                      ],
                    ),
                  ),
                if (prePaymentDeliveryCharges != '')
                  Row(
                    children: [
                      Text('${getTranslated(context, 'ONLINE_PAY_LBL')}: ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack2,
                          ),),
                      Text(
                          '${getPriceFormat(context, double.parse(prePaymentDeliveryCharges))}',),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  _speciExtraBtnDetails(Product data) {
    final Product model = data;
    String? cod = model.codAllowed;
    if (cod == "1") {
      cod = "Cash On Delivery";
    } else {
      cod = "No-Cash On Delivery";
    }
    String? cancleable = model.isCancelable;
    if (cancleable == "1") {
      cancleable = "Cancellable Till ${model.cancleTill!}";
    } else {
      cancleable = "No Cancellable";
    }
    String? returnable = model.isReturnable;
    if (returnable == "1") {
      returnable = "${RETURN_DAYS!} Days Returnable";
    } else {
      returnable = "No Returnable";
    }
    final String? gaurantee = model.gurantee;
    final String? warranty = model.warranty;
    return Card(
        elevation: 0,
        child: Container(
            height: 100,
            padding: const EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
            width: deviceWidth,
            child: Row(
              children: [
                if (model.codAllowed == "1") Expanded(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(bottom: 5.0),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: SvgPicture.asset(
                                  'assets/images/cod.svg',
                                  height: 45.0,
                                  width: 45.0,
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                      Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7),
                                      BlendMode.srcIn,),
                                ),),
                          ),
                          Container(
                            alignment: Alignment.center,
                            width: 72,
                            child: Text(
                              cod,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),) else Container(
                        width: 0,
                      ),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 7.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(bottom: 5.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: SvgPicture.asset(
                                  model.isCancelable == "1"
                                      ? "assets/images/cancelable.svg"
                                      : "assets/images/notcancelable.svg",
                                  height: 45.0,
                                  width: 45.0,
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                      Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7),
                                      BlendMode.srcIn,),
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: 72,
                              child: Text(
                                cancleable,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),),),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 7.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(bottom: 5.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: SvgPicture.asset(
                                  model.isReturnable == "1"
                                      ? "assets/images/returnable.svg"
                                      : "assets/images/notreturnable.svg",
                                  height: 45.0,
                                  width: 45.0,
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                      Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7),
                                      BlendMode.srcIn,),
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: 72,
                              child: Text(
                                returnable,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),),),
                if (gaurantee != "" && gaurantee!.isNotEmpty) Expanded(
                        child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 7.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      bottom: 5.0,),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: SvgPicture.asset(
                                      "assets/images/guarantee.svg",
                                      height: 45.0,
                                      width: 45.0,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                          Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.7),
                                          BlendMode.srcIn,),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: 72,
                                  child: Text(
                                    "$gaurantee ${getTranslated(context, 'GUARANTY_LBL')}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),),) else Container(
                        width: 0,
                      ),
                if (warranty != "" && warranty!.isNotEmpty) Expanded(
                        child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 7.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      bottom: 5.0,),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: SvgPicture.asset(
                                      "assets/images/warranty.svg",
                                      height: 45.0,
                                      width: 45.0,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                          Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.7),
                                          BlendMode.srcIn,),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: 72,
                                  child: Text(
                                    "$warranty ${getTranslated(context, 'WARRENTY')}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),),) else Container(
                        width: 0,
                      ),
              ],
            ),),);
  }

  _reviewTitle(Product data) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
        child: Row(
          children: [
            Text(
              getTranslated(context, 'CUSTOMER_REVIEW_LBL')!,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.lightBlack,
                  fontWeight: FontWeight.bold,),
            ),
            const Spacer(),
            InkWell(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  getTranslated(context, 'VIEW_ALL')!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primarytheme,),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => ReviewList(data.id, data),),
                );
              },
            ),
          ],
        ),);
  }

  reviewImage(int i) {
    return SizedBox(
      height: reviewList[i].imgList!.isNotEmpty ? 50 : 0,
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
                        secPos: widget.secPos,
                        index: widget.index,
                        id: '$index${reviewList[i].id}',
                        imgList: reviewList[i].imgList,
                        list: true,
                        from: false,
                      ),
                    ),);
              },
              child: Hero(
                tag: "$index${reviewList[i].id}${widget.secPos}",
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: networkImageCommon(
                        reviewList[i].imgList![index], 50, false,
                        height: 50, width: 50,),),
              ),
            ),
          );
        },
      ),
    );
  }

  _shortDesc(Product data) {
    final Product model = data;
    return model.shortDescription != null &&
            model.shortDescription != "" &&
            model.shortDescription!.isNotEmpty
        ? Padding(
            padding: const EdgeInsetsDirectional.only(
                start: 8, end: 8, top: 8, bottom: 5,),
            child: Text(
              getTranslated(context, model.shortDescription!) ?? model.shortDescription!,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          )
        : const SizedBox();
  }

  _brandName(Product data) {
    final Product model = data;
    return model.brand != ""
        ? Padding(
            padding: const EdgeInsetsDirectional.only(
                start: 8, end: 8, top: 8, bottom: 5,),
            child: Row(
              children: [
                Text(
                  "${getTranslated(context, 'BRAND_LBL')!} : ",
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  model.brand!,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  _attr(Product data) {
    final Product model = data;
    return model.attributeList!.isNotEmpty
        ? ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: model.attributeList!.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: EdgeInsetsDirectional.only(
                    start: 25.0,
                    top: 10.0,
                    bottom: model.madein != "" && model.madein!.isNotEmpty
                        ? 0.0
                        : 7.0,),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        model.attributeList![i].name!,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.7),),
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 5.0),
                            child: Text(
                              model.attributeList![i].value!,
                              textAlign: TextAlign.start,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,),
                            ),),),
                  ],
                ),
              );
            },
          )
        : const SizedBox();
  }

  Future<String> generateShortDynamicLink(Product data) async {
    return "https://${AppSettings.shareNavigationWebUrl}/products/details/${productData!.slug}";
  }

  playIcon(Product data) {
    final Product model = data;
    return Align(
        child: (model.videType != "" &&
                model.video!.isNotEmpty &&
                model.video != "")
            ? Icon(
                Icons.play_circle_fill_outlined,
                color: Theme.of(context).colorScheme.primarytheme,
                size: 35,
              )
            : const SizedBox(),);
  }

  _reviewImg(Product data) {
    final Product model = data;
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
                                    ReviewGallary(productModel: model),),);
                      } else {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                                pageBuilder: (_, __, ___) => ReviewPreview(
                                      index: index,
                                      productModel: model,
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
                              ) else const SizedBox(),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : const SizedBox();
  }

  Future<void> validatePinFromShipRocket(
      String pin, bool wantsToPop, Product data,) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          context.read<CartProvider>().setProgress(true);
          final parameter = {
            DEL_PINCODE: pin,
            PRODUCT_VARIENT_ID: data.prVarientList![_oldSelVarient].id,
          };
          apiBaseHelper
              .postAPICall(checkShipRocketChargesOnProduct, parameter)
              .then((getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (error) {
              context.read<UserProvider>().setPincode(pin);
              curPin = '';
              deliveryDate = '';
              codDeliveryCharges = '';
              prePaymentDeliveryCharges = '';
              log("Issue is $msg");
              setSnackbar(msg!, context);
            } else {
              if (getdata['data'] != null) {
                deliveryMsg = msg!;
                deliveryDate = getdata['data']['estimate_date'] ?? '';
                codDeliveryCharges =
                    getdata['data']['delivery_charge_with_cod'].toString();
                prePaymentDeliveryCharges =
                    getdata['data']['delivery_charge_without_cod'].toString();
              } else {
                deliveryDate = '';
                codDeliveryCharges = '';
                prePaymentDeliveryCharges = '';
                deliveryMsg = msg!;
              }
              context.read<UserProvider>().setPincode(pin);
              setState(() {});
            }
            context.read<CartProvider>().setProgress(false);
            if (wantsToPop) {
              Navigator.pop(context);
            }
          }, onError: (error, stack) {
            context.read<CartProvider>().setProgress(false);
            log("Issue is $stack");
            setSnackbar(error.toString(), context);
          },);
        } on TimeoutException catch (_) {
          context.read<CartProvider>().setProgress(false);
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      log("Issue is $e");
      setSnackbar(e.message, context);
    }
  }

  Future<void> validatePin(String pinOrCity, bool first, Product data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          final parameter = {
            if (!isCityWiseDelivery!) ZIPCODE: pinOrCity,
            if (isCityWiseDelivery!) "city": pinOrCity,
            PRODUCT_ID: data.id,
          };
          apiBaseHelper.postAPICall(checkDeliverableApi, parameter).then(
              (getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (error) {
              curPin = '';
              deliveryMsg = msg ?? "";
              setState(() {});
              setSnackbar(msg!, context);
            } else {
              if (pinOrCity != context.read<UserProvider>().curPincode) {
                context.read<HomeProvider>().setSecLoading(true);
                getSection();
              }
              setState(() {});
              deliveryMsg = msg!;
              context.read<UserProvider>().setPincode(pinOrCity);
            }
            if (!first) {
              Navigator.pop(context);
              setSnackbar(msg, context);
            }
          }, onError: (error, st) {
            setSnackbar(error.toString(), context);
          },);
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {});
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      log("Issue is $e");
      setSnackbar(e.message, context);
    }
  }

  void getSection() {
    final List<SectionModel> featuredSections =
        context.read<FetchFeaturedSectionsCubit>().getFeaturedSections();
    final UserProvider userProvider = context.read<UserProvider>();
    final HomeProvider homeProvider = context.read<HomeProvider>();
    final Map<String, String> parameters = {
      PRODUCT_LIMIT: "6",
      PRODUCT_OFFSET: "0",
      if (userProvider.userId.isNotEmpty) USER_ID: userProvider.userId,
      if (pincodeOrCityName != null || pincodeOrCityName.toString().isNotEmpty)
        if (isCityWiseDelivery == false) ZIPCODE: userProvider.curPincode,
      if (isCityWiseDelivery!) "city": pincodeOrCityName!,
    };
    apiBaseHelper.postAPICall(getSectionApi, parameters).then((getData) {
      final bool error = getData["error"];
      final String? msg = getData["message"];
      featuredSections.clear();
      if (!error) {
        final data = getData["data"];
        featuredSections
            .addAll((data as List).map((data) => SectionModel.fromJson(data)));
      } else {
        if (userProvider.curPincode.isNotEmpty) userProvider.setPincode('');
        setSnackbar(msg!, context);
      }
      homeProvider.setSecLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      homeProvider.setSecLoading(false);
    },).catchError((e) {
      if (e is FormatException) {
        setSnackbar(e.message, context);
      }
    });
  }

  Future<void> getDeliverable(Product data) async {
    final String pin = context.read<UserProvider>().curPincode;
    if (pin != '') {
      if (IS_SHIPROCKET_ON == "1") {
        validatePinFromShipRocket(pin, false, data);
      } else if (isCityWiseDelivery!) {
        validatePin(pin, true, data);
      }
    }
  }

  _reviewStar(Product data) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(
                data.rating ?? "",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
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

  getTotalStarRating(var totalStar) {
    return SizedBox(
        width: 20,
        height: 20,
        child: Text(
          totalStar,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),);
  }

  Widget detailshimmer() {
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
                height: MediaQuery.of(context).size.height * .47,
                width: double.infinity,
                color: Theme.of(context).colorScheme.white,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 35,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 9.0),
                  child: simmerSingle(),),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> setFaqsQue(Product data) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          USER_ID: context.read<UserProvider>().userId,
          PRODUCT_ID: data.id,
          QUESTION: edtFaqs.text.trim(),
        };
        apiBaseHelper.postAPICall(setProductFaqsApi, parameter).then((getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          Navigator.pop(context);
          if (!error) {
            setSnackbar(msg!, context);
            edtFaqs.clear();
          } else {
            setSnackbar(msg!, context);
          }
          context.read<CartProvider>().setProgress(false);
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }
}

class AnimatedProgressBar extends AnimatedWidget {
  final Animation<double> animation;
  const AnimatedProgressBar({super.key, required this.animation})
      : super(listenable: animation);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5.0,
      width: animation.value,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.black),
    );
  }
}
