import 'dart:async';
import 'package:collection/src/iterable_extensions.dart';
import 'package:customer/Helper/Session.dart';
import 'package:customer/Helper/SqliteData.dart';
import 'package:customer/Provider/CartProvider.dart';
import 'package:customer/Provider/FavoriteProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/Screen/MultipleTimer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../Helper/Color.dart';
import '../Helper/String.dart';
import '../Model/FlashSaleModel.dart';
import '../Model/Section_Model.dart';
import '../Provider/FlashSaleProvider.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import '../ui/widgets/AppBtn.dart';
import 'HomePage.dart';

class FlashProductList extends StatefulWidget {
  final int index;
  const FlashProductList({
    super.key,
    required this.index,
  });
  @override
  State<StatefulWidget> createState() => StateFlashList();
}

class StateFlashList extends State<FlashProductList>
    with TickerProviderStateMixin {
  final bool _isLoading = true;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  late List<String> attsubList;
  late List<String> attListId;
  bool _isProgress = false;
  final List<TextEditingController> _controller = [];
  late UserProvider userProvider;
  ChoiceChip? choiceChip;
  DatabaseHelper db = DatabaseHelper();
  AnimationController? _animationController;
  AnimationController? _animationController1;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200),);
    _animationController1 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200),);
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

  @override
  void dispose() {
    buttonController!.dispose();
    _animationController1!.dispose();
    _animationController!.dispose();
    for (int i = 0; i < _controller.length; i++) {
      _controller[i].dispose();
    }
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      return;

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

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: getAppBar(
          context.read<FlashSaleProvider>().saleList[widget.index].title!,
          context,),
      body: _isNetworkAvail
          ? Consumer<FlashSaleProvider>(builder: (context, data, child) {
              final FlashSaleModel model = data.saleList[widget.index];
              return Column(
                children: [
                  if (model.status == "1" || model.status == "2")
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 10.0),
                      child: SizedBox(
                        height: 45,
                        child: MultipleTimer(
                          startDateModel: model.startDate!,
                          endDateModel: model.endDate!,
                          serverDateModel: model.serverTime!,
                          id: model.id!,
                          newtimeDiff: model.timeDiff!,
                          from: 1,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        GridView.count(
                            padding: const EdgeInsetsDirectional.only(
                              top: 5,
                            ),
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: List.generate(
                              model.products!.product!.length,
                              (index) {
                                return productItem(index, model);
                              },
                            ),),
                        showCircularProgress(context, _isProgress,
                            Theme.of(context).colorScheme.primarytheme,),
                      ],
                    ),
                  ),
                ],
              );
            },)
          : noInternet(context),
    );
  }

  Future<void> addToCart(
      int index, String qty, int from, FlashSaleModel data,) async {
    try {
      final Product model = data.products!.product![index];
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (context.read<UserProvider>().userId != "") {
          try {
            if (mounted) {
              setState(() {
                _isProgress = true;
              });
            }
            if (int.parse(qty) < model.minOrderQuntity!) {
              qty = model.minOrderQuntity.toString();
              setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
            }
            final parameter = {
              USER_ID: context.read<UserProvider>().userId,
              PRODUCT_VARIENT_ID: model.prVarientList![model.selVarient!].id,
              QTY: qty,
            };
            apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
              final bool error = getdata["error"];
              final String? msg = getdata["message"];
              if (!error) {
                final data = getdata["data"];
                final String? qty = data['total_quantity'];
                userProvider.setCartCount(data['cart_count']);
                model.prVarientList![model.selVarient!].cartCount =
                    qty.toString();
                final cart = getdata["cart"];
                final List<SectionModel> cartList = (cart as List)
                    .map((cart) => SectionModel.fromCart(cart))
                    .toList();
                context.read<CartProvider>().setCartlist(cartList);
              } else {
                setSnackbar(msg!, context);
              }
              if (mounted) {
                setState(() {
                  _isProgress = false;
                });
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            },);
          } on TimeoutException catch (_) {
            setSnackbar(getTranslated(context, 'somethingMSg')!, context);
            if (mounted) {
              setState(() {
                _isProgress = false;
              });
            }
          }
        } else {
          setState(() {
            _isProgress = true;
          });
          if (from == 1) {
            final int cartCount = await db.getTotalCartCount(context);
            if (int.parse(MAX_ITEMS!) > cartCount) {
              final bool add = await db.insertCart(
                  model.id!,
                  model.prVarientList![model.selVarient!].id!,
                  qty,
                  model.productType!,
                  context,);
              if (add) {
                final List<Product> prList = [];
                prList.add(model);
                context.read<CartProvider>().addCartItem(SectionModel(
                      qty: qty,
                      productList: prList,
                      varientId: model.prVarientList![model.selVarient!].id,
                      id: model.id,
                    ),);
              }
            } else {
              setSnackbar(
                  "In Cart maximum ${int.parse(MAX_ITEMS!)} product allowed",
                  context,);
            }
          } else {
            if (int.parse(qty) > int.parse(model.itemsCounter!.last)) {
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${model.itemsCounter!.last}",
                  context,);
            } else {
              context.read<CartProvider>().updateCartItem(
                  model.id,
                  qty,
                  model.selVarient!,
                  model.prVarientList![model.selVarient!].id!,);
              db.updateCart(
                  model.id!, model.prVarientList![model.selVarient!].id!, qty,);
            }
          }
          setState(() {
            _isProgress = false;
          });
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

  removeFromCart(int index, FlashSaleModel data) async {
    try {
      final Product model = data.products!.product![index];
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (context.read<UserProvider>().userId != "") {
          try {
            if (mounted) {
              setState(() {
                _isProgress = true;
              });
            }
            int qty;
            qty = int.parse(_controller[index].text) -
                int.parse(model.qtyStepSize!);
            if (qty < model.minOrderQuntity!) {
              qty = 0;
            }
            final parameter = {
              PRODUCT_VARIENT_ID: model.prVarientList![model.selVarient!].id,
              USER_ID: context.read<UserProvider>().userId,
              QTY: qty.toString(),
            };
            apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
              final bool error = getdata["error"];
              final String? msg = getdata["message"];
              if (!error) {
                final data = getdata["data"];
                final String? qty = data['total_quantity'];
                userProvider.setCartCount(data['cart_count']);
                model.prVarientList![model.selVarient!].cartCount =
                    qty.toString();
                final cart = getdata["cart"];
                final List<SectionModel> cartList = (cart as List)
                    .map((cart) => SectionModel.fromCart(cart))
                    .toList();
                context.read<CartProvider>().setCartlist(cartList);
              } else {
                setSnackbar(msg!, context);
              }
              if (mounted) {
                setState(() {
                  _isProgress = false;
                });
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            },);
          } on TimeoutException catch (_) {
            setSnackbar(getTranslated(context, 'somethingMSg')!, context);
            if (mounted) {
              setState(() {
                _isProgress = false;
              });
            }
          }
        } else {
          setState(() {
            _isProgress = true;
          });
          int qty;
          qty = int.parse(_controller[index].text) -
              int.parse(model.qtyStepSize!);
          if (qty < model.minOrderQuntity!) {
            qty = 0;
            context
                .read<CartProvider>()
                .removeCartItem(model.prVarientList![model.selVarient!].id!);
            db.removeCart(model.prVarientList![model.selVarient!].id!,
                model.id!, context,);
          } else {
            context.read<CartProvider>().updateCartItem(
                model.id,
                qty.toString(),
                model.selVarient!,
                model.prVarientList![model.selVarient!].id!,);
            db.updateCart(model.id!,
                model.prVarientList![model.selVarient!].id!, qty.toString(),);
          }
          setState(() {
            _isProgress = false;
          });
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

  productItem(int index, FlashSaleModel dataModel) {
    if (index < dataModel.products!.product!.length) {
      final Product model = dataModel.products!.product![index];
      final double width = deviceWidth! * 0.5 - 20;
      double price =
          double.parse(model.prVarientList![model.selVarient!].disPrice!);
      List att = [];
      List val = [];
      if (model.prVarientList![model.selVarient!].attr_name != null) {
        att = model.prVarientList![model.selVarient!].attr_name!.split(',');
        val = model.prVarientList![model.selVarient!].varient_value!.split(',');
      }
      if (_controller.length < index + 1) {
        _controller.add(TextEditingController());
      }
      if (price == 0) {
        price = double.parse(model.prVarientList![model.selVarient!].price!);
      }
      double off = 0;
      if (model.prVarientList![model.selVarient!].disPrice! != "0") {
        off = double.parse(model.prVarientList![model.selVarient!].price!) -
                double.parse(model.prVarientList![model.selVarient!].disPrice!)
            ;
        off = off *
            100 /
            double.parse(model.prVarientList![model.selVarient!].price!);
      }
      return Consumer<CartProvider>(
        builder: (context, data, child) {
          final SectionModel? tempId = data.cartList.firstWhereOrNull((cp) =>
              cp.id == model.id &&
              cp.varientId == model.prVarientList![model.selVarient!].id!,);
          if (tempId != null) {
            _controller[index].text = tempId.qty!;
          } else {
            _controller[index].text = "0";
          }
          return Card(
            elevation: 0,
            child: InkWell(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                      child: Stack(
                    alignment: Alignment.bottomRight,
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag:
                            "$saleSecHero$index${dataModel.products!.product![index].id}${widget.index}",
                        child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(5),),
                            child: networkImageCommon(
                                model.image!, width, false,
                                height: double.maxFinite,
                                width: double.maxFinite,),),
                      ),
                      if (model.availability == "0") Container(
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
                      if (off != 0) Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: colors.red,
                                ),
                                margin: const EdgeInsets.all(5),
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(
                                    dataModel.status == "1"
                                        ? "${model.saleDis}%"
                                        : "${off.toStringAsFixed(2)}%",
                                    style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,),
                                  ),
                                ),
                              ),
                            ) else const SizedBox.shrink(),
                      const Divider(
                        height: 1,
                      ),
                      Positioned(
                        right: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cartBtnList)
                              _controller[index].text == "0"
                                  ? InkWell(
                                      onTap: () {
                                        if (_isProgress == false) {
                                          addToCart(
                                              index,
                                              (int.parse(_controller[index]
                                                          .text,) +
                                                      int.parse(
                                                          model.qtyStepSize!,))
                                                  .toString(),
                                              1,
                                              dataModel,);
                                        }
                                      },
                                      child: Card(
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 3.0, bottom: 5, top: 3,),
                                      child: model.availability == "0"
                                          ? const SizedBox.shrink()
                                          : cartBtnList
                                              ? Row(
                                                  children: <Widget>[
                                                    InkWell(
                                                      child: Card(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                        ),
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  8.0,),
                                                          child: Icon(
                                                            Icons.remove,
                                                            size: 15,
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        if (_isProgress ==
                                                                false &&
                                                            (int.parse(_controller[
                                                                        index]
                                                                    .text,)) >
                                                                0) {
                                                          removeFromCart(
                                                              index, dataModel,);
                                                        }
                                                      },
                                                    ),
                                                    Container(
                                                      width: 37,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          TextField(
                                                            textAlign: TextAlign
                                                                .center,
                                                            readOnly: true,
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Theme.of(
                                                                        context,)
                                                                    .colorScheme
                                                                    .fontColor,),
                                                            controller:
                                                                _controller[
                                                                    index],
                                                            decoration:
                                                                const InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                            ),
                                                          ),
                                                          PopupMenuButton<
                                                              String>(
                                                            tooltip: '',
                                                            icon: const Icon(
                                                              Icons
                                                                  .arrow_drop_down,
                                                              size: 1,
                                                            ),
                                                            onSelected:
                                                                (String value) {
                                                              if (_isProgress ==
                                                                  false) {
                                                                addToCart(
                                                                    index,
                                                                    value,
                                                                    2,
                                                                    dataModel,);
                                                              }
                                                            },
                                                            itemBuilder:
                                                                (BuildContext
                                                                    context,) {
                                                              return model
                                                                  .itemsCounter!
                                                                  .map<
                                                                      PopupMenuItem<
                                                                          String>>((String
                                                                      value,) {
                                                                return PopupMenuItem(
                                                                    value:
                                                                        value,
                                                                    child: Text(
                                                                        value,
                                                                        style: TextStyle(
                                                                            color:
                                                                                Theme.of(context).colorScheme.fontColor,),),);
                                                              }).toList();
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    InkWell(
                                                      child: Card(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                        ),
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  8.0,),
                                                          child: Icon(
                                                            Icons.add,
                                                            size: 15,
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        if (_isProgress ==
                                                            false) {
                                                          addToCart(
                                                              index,
                                                              (int.parse(_controller[
                                                                              index]
                                                                          .text,) +
                                                                      int.parse(
                                                                          model
                                                                              .qtyStepSize!,))
                                                                  .toString(),
                                                              2,
                                                              dataModel,);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox.shrink(),
                                    ),
                            Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: model.isFavLoading!
                                    ? Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SizedBox(
                                            height: 15,
                                            width: 15,
                                            child: CircularProgressIndicator(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primarytheme,
                                              strokeWidth: 0.7,
                                            ),),
                                      )
                                    : Selector<FavoriteProvider, List<String?>>(
                                        builder: (context, data, child) {
                                          return InkWell(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Icon(
                                                !data.contains(model.id)
                                                    ? Icons.favorite_border
                                                    : Icons.favorite,
                                                size: 15,
                                              ),
                                            ),
                                            onTap: () {
                                              if (context
                                                      .read<UserProvider>()
                                                      .userId !=
                                                  "") {
                                                !data.contains(model.id)
                                                    ? _setFav(index, dataModel)
                                                    : _removeFav(
                                                        index, dataModel,);
                                              } else {
                                                if (!data.contains(model.id)) {
                                                  model.isFavLoading = true;
                                                  model.isFav = "1";
                                                  context
                                                      .read<FavoriteProvider>()
                                                      .addFavItem(model);
                                                  db.addAndRemoveFav(
                                                      model.id!, true,);
                                                  model.isFavLoading = false;
                                                } else {
                                                  model.isFavLoading = true;
                                                  model.isFav = "0";
                                                  context
                                                      .read<FavoriteProvider>()
                                                      .removeFavItem(model
                                                          .prVarientList![0]
                                                          .id!,);
                                                  db.addAndRemoveFav(
                                                      model.id!, false,);
                                                  model.isFavLoading = false;
                                                }
                                                setState(() {});
                                              }
                                            },
                                          );
                                        },
                                        selector: (_, provider) =>
                                            provider.favIdList,
                                      ),),
                          ],
                        ),
                      ),
                    ],
                  ),),
                  if (model.noOfRating! != "0") Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Row(
                            children: [
                              RatingBarIndicator(
                                rating: double.parse(model.rating!),
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star_rate_rounded,
                                  color: Colors.amber,
                                ),
                                unratedColor: Colors.grey.withOpacity(0.5),
                                itemSize: 12.0,
                              ),
                              Text(
                                " (${model.noOfRating!})",
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),) else const SizedBox.shrink(),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Row(
                        children: [
                          Text(
                              dataModel.status == "1"
                                  ? getPriceFormat(
                                      context,
                                      double.parse(model
                                          .prVarientList![model.selVarient!]
                                          .saleFinalPrice!,),)!
                                  : '${getPriceFormat(context, price)!} ',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  fontWeight: FontWeight.bold,),),
                          const SizedBox(
                            width: 3,
                          ),
                          if (double.parse(model.prVarientList![model.selVarient!]
                                      .disPrice!,) !=
                                  0) Flexible(
                                  child: Row(
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          double.parse(model
                                                      .prVarientList![
                                                          model.selVarient!]
                                                      .disPrice!,) !=
                                                  0
                                              ? getPriceFormat(
                                                  context,
                                                  double.parse(model
                                                      .prVarientList![
                                                          model.selVarient!]
                                                      .price!,),)!
                                              : "",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall!
                                              .copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  letterSpacing: 0,),
                                        ),
                                      ),
                                    ],
                                  ),
                                ) else const SizedBox.shrink(),
                        ],
                      ),),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: model.prVarientList![model.selVarient!]
                                          .attr_name !=
                                      null &&
                                  model.prVarientList![model.selVarient!]
                                      .attr_name!.isNotEmpty
                              ? ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: att.length >= 2 ? 2 : att.length,
                                  itemBuilder: (context, index) {
                                    return Row(children: [
                                      Flexible(
                                        child: Text(
                                          att[index].trim() + ":",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack,),
                                        ),
                                      ),
                                      Flexible(
                                        child: Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  start: 5.0,),
                                          child: Text(
                                            val[index],
                                            maxLines: 1,
                                            overflow: TextOverflow.visible,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack,
                                                    fontWeight:
                                                        FontWeight.bold,),
                                          ),
                                        ),
                                      ),
                                    ],);
                                  },)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 5.0, bottom: 5),
                    child: Text(
                      model.name!,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.lightBlack,),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              onTap: () {
                final Product model = dataModel.products!.product![index];
                currentHero = saleSecHero;
                Navigator.pushNamed(context, Routers.productDetails,
                    arguments: {
                      "id": model.id!,
                      "secPos": 0,
                      "index": index,
                      "list": false,
                      "saleIndex": widget.index,
                    },);
              },
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  updateSectionList() {
    if (mounted) setState(() {});
  }

  _setFav(int index, FlashSaleModel data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (mounted) {
            setState(() {
              data.products!.product![index].isFavLoading = true;
            });
          }
          final parameter = {
            USER_ID: context.read<UserProvider>().userId,
            PRODUCT_ID: data.products!.product![index].id,
          };
          apiBaseHelper.postAPICall(setFavoriteApi, parameter).then((getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (!error) {
              data.products!.product![index].isFav = "1";
              context
                  .read<FavoriteProvider>()
                  .addFavItem(data.products!.product![index]);
            } else {
              setSnackbar(msg!, context);
            }
            if (mounted) {
              setState(() {
                data.products!.product![index].isFavLoading = false;
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

  _removeFav(int index, FlashSaleModel data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (mounted) {
            setState(() {
              data.products!.product![index].isFavLoading = true;
            });
          }
          final parameter = {
            USER_ID: context.read<UserProvider>().userId,
            PRODUCT_ID: data.products!.product![index].id,
          };
          apiBaseHelper.postAPICall(removeFavApi, parameter).then((getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (!error) {
              data.products!.product![index].isFav = "0";
              context.read<FavoriteProvider>().removeFavItem(
                  data.products!.product![index].prVarientList![0].id!,);
            } else {
              setSnackbar(msg!, context);
            }
            if (mounted) {
              setState(() {
                data.products!.product![index].isFavLoading = false;
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
}
