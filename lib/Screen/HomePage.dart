import 'dart:async';

import 'dart:io';
import 'dart:math';
import 'package:customer/Helper/ApiBaseHelper.dart';
import 'package:customer/Helper/Color.dart';
import 'package:customer/Helper/Constant.dart';
import 'package:customer/Helper/Session.dart';
import 'package:customer/Helper/SqliteData.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Model/Model.dart';
import 'package:customer/Model/OfferImages.dart';
import 'package:customer/Model/Section_Model.dart';
import 'package:customer/Provider/CartProvider.dart';
import 'package:customer/Provider/CategoryProvider.dart';
import 'package:customer/Provider/FavoriteProvider.dart';
import 'package:customer/Provider/HomeProvider.dart';
import 'package:customer/Provider/SettingProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/Screen/homeWidgets/popupOfferDialoge.dart';
import 'package:customer/cubits/brandsListCubit.dart';
import 'package:customer/cubits/fetch_citites.dart';
import 'package:customer/cubits/fetch_featured_sections_cubit.dart';
import 'package:customer/ui/widgets/AppBtn.dart';
import 'package:customer/ui/widgets/SimBtn.dart';
import 'package:customer/utils/Extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import '../Provider/ProductProvider.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import 'homeWidgets/sections/featured_section.dart';
import 'homeWidgets/sections/styles/style_1.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:customer/Screen/ProductList.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animations/animations.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

List<Product> catList = [];
ApiBaseHelper apiBaseHelper = ApiBaseHelper();
List<String> tagList = [];
List<Product> sellerList = [];
List<Model> homeSliderList = [];
List<Widget> pages = [];
int count = 1;

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage>, TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  final _controller = PageController();
  late Animation buttonSqueezeanimation;
  late AnimationController buttonController;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  List<SectionModel> featuredSectionList = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  double beginAnim = 0.0;
  double endAnim = 1.0;
  DatabaseHelper db = DatabaseHelper();
  List<String> proIds = [];
  List<Product> mostLikeProList = [];
  List<String> proIds1 = [];
  List<Product> mostFavProList = [];
  PopUpOfferImage popUpOffer = PopUpOfferImage();
  Map? selectedCity;
  String? pincodeOrCityName;
  String? slectedCityId = "";
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    initCityOrPinCodeWiseDelivery();
    callApi();
    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateSlider());
  }

  initCityOrPinCodeWiseDelivery() async {
    final bool isCity = await context
        .read<SettingProvider>()
        .getPrefrenceBool("is_city_wise_delivery");
    if (isCity != isCityWiseDelivery) {
      await context.read<SettingProvider>().removeKey(pinCodeOrCityNameKey);
    }
  }

  @override
  void dispose() {
   
    _controller.dispose();
    buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    featuredSectionList =
        context.watch<FetchFeaturedSectionsCubit>().getFeaturedSections();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
     
      body: _isNetworkAvail
          ? RefreshIndicator(
              color: Theme.of(context).colorScheme.primarytheme,
              key: _refreshIndicatorKey,
              onRefresh: _refresh,
              child: BlocListener<FetchFeaturedSectionsCubit,
                  FetchFeaturedSectionsState>(
                listener: (context, state) {
                  if (state is FetchFeaturedSectionsSuccess) {
                    setState(() {});
                    if (pincodeOrCityName != null &&
                        pincodeOrCityName.toString().isNotEmpty) {
                      context.read<SettingProvider>().setPrefrence(
                            pinCodeOrCityNameKey,
                            pincodeOrCityName!,
                          );
                      context.read<SettingProvider>().setPrefrenceBool(
                            "is_city_wise_delivery",
                            isCityWiseDelivery!,
                          );
                    }
                    context.read<HomeProvider>().setSecLoading(false);
                  }
                  if (state is FetchFeaturedSectionsFail) {
                    if (pincodeOrCityName != null) {
                      setState(() {
                        pincodeOrCityName = null;
                      });
                      context.read<HomeProvider>().setSecLoading(false);
                    }
                    setSnackbar(state.error!.toString(), context);
                  }
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
  _slider(),
  const SizedBox(height: 12),
  _getSearchBar(),
  const SizedBox(height: 6),
  NeumorphicSections(minimal: true), // We'll handle this next
  const SizedBox(height: 0),
  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        getTranslated(context, 'CATEGORIES') ?? "Categories",
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.fontColor,
            ),
      ),
    ],
  ),
),
const SizedBox(height: 10),
_catGridList(),

  const SizedBox(height: 0),
  const BrandsListWidget(),
  _section(),
],

                  ),
                ),
              ),
            )
          : noInternet(context),
    );
  }

  Future<void> _refresh() {
    context.read<HomeProvider>().setCatLoading(true);
    context.read<HomeProvider>().setSecLoading(true);
    context.read<HomeProvider>().setOfferLoading(true);
    context.read<HomeProvider>().setMostLikeLoading(true);
    context.read<HomeProvider>().setSliderLoading(true);
    context.read<CategoryProvider>().setCurSelected(0);
    proIds.clear();
    return callApi();
  }




  

Widget _slider() {
  final double height = deviceWidth! / 1.8; // Adjust height for better fit
  return Selector<HomeProvider, bool>(
    builder: (context, data, child) {
      return data
          ? sliderLoading()
          : Column(
              children: [
                CarouselSlider.builder(
                  itemCount: homeSliderList.length,
                  options: CarouselOptions(
                    height: height,
                    autoPlay: true,
                    viewportFraction: 0.9,
                    autoPlayInterval: Duration(seconds: 4),
                    autoPlayAnimationDuration: Duration(milliseconds: 800),
                    enlargeCenterPage: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        context.read<HomeProvider>().setCurSlider(index);
                      });
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    return _buildImagePageItem(homeSliderList[index]);
                  },
                ),
                SizedBox(height: 10),
                AnimatedSmoothIndicator(
                  activeIndex: context.read<HomeProvider>().curSlider,
                  count: homeSliderList.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                    activeDotColor: Theme.of(context).colorScheme.primary,
                    dotColor: Colors.grey.shade400,
                  ),
                ),
              ],
            );
    },
    selector: (_, homeProvider) => homeProvider.sliderLoading,
  );
}

  void _animateSlider() {
    Future.delayed(const Duration(seconds: 10)).then((_) {
      if (mounted) {
        int nextPage = _controller.hasClients
            ? _controller.page!.round() + 1
            : _controller.initialPage;
        if (nextPage == homeSliderList.length) {
          nextPage = 0;
        }
        if (_controller.hasClients) {
          _controller
              .animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 200),
            curve: Curves.linear,
          )
              .then((_) {
            _animateSlider();
          });
        }
      }
    });
  }

  _singleFeaturedSection(int index) {
    Color back;
    final int pos = index % 5;
    if (pos == 0) {
      back = Theme.of(context).colorScheme.back1;
    } else if (pos == 1) {
      back = Theme.of(context).colorScheme.back2;
    } else if (pos == 2) {
      back = Theme.of(context).colorScheme.back3;
    } else if (pos == 3) {
      back = Theme.of(context).colorScheme.back4;
    } else {
      back = Theme.of(context).colorScheme.back5;
    }
    return featuredSectionList[index].productList!.isNotEmpty
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(
                          color: back,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _getHeading(
                          featuredSectionList[index].title ?? "",
                          index,
                          1,
                          [],
                        ),
                        _getFeaturedSection(index),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }

  _getHeading(String title, int index, int from, List<Product> productList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (from == 1)
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerRight,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: Colors.grey.shade200,
                  ),
                  padding: const EdgeInsetsDirectional.only(
                    start: 12,
                    bottom: 3,
                    top: 3,
                    end: 12,
                  ),
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(color: colors.blackTemp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 12.0, end: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  from == 2
                      ? title
                      : featuredSectionList[index].shortDesc ?? "",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,
                      ),
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  backgroundColor: Theme.of(context).colorScheme.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                ),
                child: Text(
                  getTranslated(context, 'SHOP_NOW')!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                onPressed: () {
                  final SectionModel model = featuredSectionList[index];
                  Navigator.pushNamed(
                    context,
                    Routers.sectionListScreen,
                    arguments: {
                      "index": index,
                      "section_model": model,
                      "from": from,
                      "productList": productList,
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  _getFeaturedSection(int index) {
    final SectionModel featuredSection = featuredSectionList[index];
    final List<Product>? featuredSectionProductList =
        featuredSection.productList;
    return FeaturedSectionGet()
        .get(
          featuredSection.style!,
          index: index,
          products: featuredSectionProductList!,
        )
        .render(context);
  }

  _section() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? SizedBox(
                width: double.infinity,
                child: Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.simmerBase,
                  highlightColor: Theme.of(context).colorScheme.simmerHigh,
                  child: sectionLoading(),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: featuredSectionList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _singleFeaturedSection(index);
                },
              );
      },
      selector: (_, homeProvider) => homeProvider.secLoading,
    );
  }

  _mostLike() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.back3,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Selector<ProductProvider, List<Product>>(
                    builder: (context, data1, child) {
                      return data1.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _getHeading(
                                    getTranslated(
                                      context,
                                      'YOU_MIGHT_ALSO_LIKE',
                                    )!,
                                    0,
                                    2,
                                    data1,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: GridView.count(
                                      padding: const EdgeInsetsDirectional.only(
                                        top: 5,
                                      ),
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: List.generate(
                                        data1.length < 4 ? data1.length : 4,
                                        (index) {
                                          return productItem(
                                            0,
                                            index,
                                            index % 2 == 0 ? true : false,
                                            data1[index],
                                            2,
                                            data1.length,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox();
                    },
                    selector: (_, provider) => provider.productList,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      selector: (_, homeProvider) => homeProvider.mostLikeLoading,
    );
  }

  Widget _catGridList() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: catList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final cat = catList[index];
        return InkWell(
          onTap: () async {
            await Navigator.pushNamed(
              context,
              Routers.productListScreen,
              arguments: {
                "name": cat.name,
                "id": cat.id,
                "tag": false,
                "fromSeller": false,
              },
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF26897e), Color(0xFF1ebaaa)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (cat.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: networkImageCommon(
                      cat.image!,
                      30,
                      width: 30,
                      height: 30,
                      false,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getTranslated(context, cat.name!) ??
                        capitalize(cat.name!.toLowerCase()),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                    overflow: TextOverflow.ellipsis,
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







  List<T> map<T>(List list, Function handler) {
    final List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }
    return result;
  }

  Future<void> callApi() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final UserProvider user =
          Provider.of<UserProvider>(context, listen: false);
      final SettingProvider setting =
          Provider.of<SettingProvider>(context, listen: false);
      pincodeOrCityName = await setting.getPrefrence(pinCodeOrCityNameKey);
      user.setUserId(setting.userId);
      user.setMobile(setting.mobile);
      user.setName(setting.userName);
      user.setEmail(setting.email);
      user.setProfilePic(setting.profileUrl);
      user.setType(setting.loginType);
    });
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getSetting();
      final cityId =
          await context.read<SettingProvider>().getPrefrence("cityId");
      context.read<FetchFeaturedSectionsCubit>().fetchSections(
            context,
            userId: context.read<UserProvider>().userId,
            
            isCityWiseDelivery: isCityWiseDelivery!,
          );
      context.read<BrandsListCubit>().getBrandsList();
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
    return;
  }

  Future _getFav() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (context.read<UserProvider>().userId != "") {
          final Map parameter = {
            USER_ID: context.read<UserProvider>().userId,
          };
          apiBaseHelper.postAPICall(getFavApi, parameter).then(
            (getdata) {
              final bool error = getdata["error"];
              final String? msg = getdata["message"];
              if (!error) {
                final data = getdata["data"];
                final List<Product> tempList = (data as List)
                    .map((data) => Product.fromJson(data))
                    .toList();
                context.read<FavoriteProvider>().setFavlist(tempList);
              } else {
                if (msg != 'No Favourite(s) Product Are Added') {
                  setSnackbar(msg!, context);
                }
              }
              context.read<FavoriteProvider>().setLoading(false);
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
              context.read<FavoriteProvider>().setLoading(false);
            },
          );
        } else {
          context.read<FavoriteProvider>().setLoading(false);
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

  void getSetting() {
    try {
      Map parameter = {};
      if (context.read<UserProvider>().userId != "") {
        parameter = {USER_ID: context.read<UserProvider>().userId};
      }
      apiBaseHelper.postAPICall(getSettingApi, parameter).then(
        (getdata) async {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
            final data = getdata["data"]["system_settings"][0];
            SUPPORTED_LOCALES = data["supported_locals"];
            if (data.toString().contains(MAINTAINANCE_MODE)) {
              Is_APP_IN_MAINTANCE = data[MAINTAINANCE_MODE];
            }
            if (Is_APP_IN_MAINTANCE != "1") {
              getSlider();
              getCat();
              context.read<FetchFeaturedSectionsCubit>().fetchSections(
                    context,
                    userId: context.read<UserProvider>().userId,
                    isCityWiseDelivery: isCityWiseDelivery!,
                  );
              proIds = (await db.getMostLike())!;
              getMostLikePro();
              proIds1 = (await db.getMostFav())!;
              getMostFavPro();
            }
            if (data.toString().contains(MAINTAINANCE_MESSAGE)) {
              IS_APP_MAINTENANCE_MESSAGE = data[MAINTAINANCE_MESSAGE];
            }
            cartBtnList = data["cart_btn_on_list"] == "1" ? true : false;
            refer = data["is_refer_earn_on"] == "1" ? true : false;
            CUR_CURRENCY = data["currency"];
            RETURN_DAYS = data['max_product_return_days'];
            MAX_ITEMS = data["max_items_cart"];
            MIN_AMT = data['min_amount'];
            CUR_DEL_CHR = data['delivery_charge'];
            final String? isVerion = data['is_version_system_on'];
            extendImg = data["expand_product_images"] == "1" ? true : false;
            final String? del = data["area_wise_delivery_charge"];
            MIN_ALLOW_CART_AMT = data[MIN_CART_AMT];
            IS_LOCAL_PICKUP = data[LOCAL_PICKUP];
            ADMIN_ADDRESS = data[ADDRESS];
            ADMIN_LAT = data[LATITUDE];
            ADMIN_LONG = data[LONGITUDE];
            ADMIN_MOB = data[SUPPORT_NUM];
            IS_SHIPROCKET_ON = getdata["data"]["shipping_method"][0]
                ["shiprocket_shipping_method"];
            IS_LOCAL_ON =
                getdata["data"]["shipping_method"][0]["local_shipping_method"];
            ALLOW_ATT_MEDIA = data[ALLOW_ATTACH];
            whatsappOrderingOn = data['whatsapp_status'].toString() == "1";
            if (whatsappOrderingOn) {
              whatsappOrderingPhoneNumber = data['whatsapp_number'] ?? "";
            }
            try {
              popUpOffer =
                  PopUpOfferImage.fromJson(getdata["data"]["popup_offer"][0]);
              final SharedPreferences sharedData =
                  await SharedPreferences.getInstance();
              final String storedOfferPopUpID =
                  sharedData.getString("offerPopUpID") ?? "";
              popUpOffer.isActive == "1" &&
                      (popUpOffer.showMultipleTime == "1" ||
                          storedOfferPopUpID != popUpOffer.id)
                  ? showPopUpOfferDialog()
                  : null;
            } catch (e) {
              print("error is $e");
            }
            if (data.toString().contains(UPLOAD_LIMIT)) {
              UP_MEDIA_LIMIT = data[UPLOAD_LIMIT];
            }
            if (Is_APP_IN_MAINTANCE == "1") {
              appMaintenanceDialog();
            }
            if (del == "0") {
              ISFLAT_DEL = true;
            } else {
              ISFLAT_DEL = false;
            }
            if (context.read<UserProvider>().userId != "") {
              REFER_CODE = getdata['data']['user_data'][0]['referral_code'];
              context.read<UserProvider>().setPincode(
                    getdata["data"]["user_data"][0][pinCodeOrCityNameKey],
                  );
              if (REFER_CODE == null ||
                  REFER_CODE == '' ||
                  REFER_CODE!.isEmpty) {
                generateReferral();
              }
              context.read<UserProvider>().setCartCount(
                    getdata["data"]["user_data"][0]["cart_total_items"]
                        .toString(),
                  );
              context
                  .read<UserProvider>()
                  .setBalance(getdata["data"]["user_data"][0]["balance"]);
              if (Is_APP_IN_MAINTANCE != "1") {
                _getFav();
                _getCart("0");
              }
            } else {
              if (Is_APP_IN_MAINTANCE != "1") {
                _getOffFav();
                _getOffCart();
              }
            }
            final Map<String, dynamic> tempData = getdata["data"];
            if (tempData.containsKey(TAG)) {
              tagList = List<String>.from(getdata["data"][TAG] ?? "");
            }
            if (isVerion == "1") {
              final String? verionAnd = data['current_version'];
              final String? verionIOS = data['current_version_ios'];
              final PackageInfo packageInfo = await PackageInfo.fromPlatform();
              final String version = packageInfo.version;
              final Version currentVersion = Version.parse(version);
              final Version latestVersionAnd = Version.parse(verionAnd!);
              final Version latestVersionIos = Version.parse(verionIOS!);
              if ((Platform.isAndroid && latestVersionAnd > currentVersion) ||
                  (Platform.isIOS && latestVersionIos > currentVersion)) {
                updateDailog();
              }
            }
          } else {
            setSnackbar(msg!, context);
          }
        },
        onError: (error) {
          setSnackbar(error.toString(), context);
        },
      );
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> getMostLikePro() async {
    if (proIds.isNotEmpty) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          final parameter = {"product_ids": proIds.join(',')};
          apiBaseHelper.postAPICall(getProductApi, parameter).then(
            (getdata) async {
              final bool error = getdata["error"];
              if (!error) {
                final data = getdata["data"];
                final List<Product> tempList = (data as List)
                    .map((data) => Product.fromJson(data))
                    .toList();
                mostLikeProList.clear();
                mostLikeProList.addAll(tempList);
                context.read<ProductProvider>().setProductList(mostLikeProList);
              }
              if (mounted) {
                setState(() {
                  context.read<HomeProvider>().setMostLikeLoading(false);
                });
              }
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
            },
          );
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
      context.read<ProductProvider>().setProductList([]);
      setState(() {
        context.read<HomeProvider>().setMostLikeLoading(false);
      });
    }
  }

  Future<void> getMostFavPro() async {
    if (proIds1.isNotEmpty) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          final parameter = {"product_ids": proIds1.join(',')};
          apiBaseHelper.postAPICall(getProductApi, parameter).then(
            (getdata) async {
              final bool error = getdata["error"];
              if (!error) {
                final data = getdata["data"];
                final List<Product> tempList = (data as List)
                    .map((data) => Product.fromJson(data))
                    .toList();
                mostFavProList.clear();
                mostFavProList.addAll(tempList);
              }
              if (mounted) {
                setState(() {
                  context.read<HomeProvider>().setMostLikeLoading(false);
                });
              }
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
            },
          );
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

  Future<void> _getOffCart() async {
    if (context.read<UserProvider>().userId == "") {
      final List<String> proIds = (await db.getCart())!;
      if (proIds.isNotEmpty) {
        _isNetworkAvail = await isNetworkAvailable();
        if (_isNetworkAvail) {
          try {
            final parameter = {"product_variant_ids": proIds.join(',')};
            apiBaseHelper.postAPICall(getProductApi, parameter).then(
              (getdata) async {
                final bool error = getdata["error"];
                if (!error) {
                  final data = getdata["data"];
                  final List<Product> tempList = (data as List)
                      .map((data) => Product.fromJson(data))
                      .toList();
                  final List<SectionModel> cartSecList = [];
                  for (int i = 0; i < tempList.length; i++) {
                    for (int j = 0;
                        j < tempList[i].prVarientList!.length;
                        j++) {
                      if (proIds.contains(tempList[i].prVarientList![j].id)) {
                        final String qty = (await db.checkCartItemExists(
                          tempList[i].id!,
                          tempList[i].prVarientList![j].id!,
                        ))!;
                        final List<Product> prList = [];
                        prList.add(tempList[i]);
                        cartSecList.add(
                          SectionModel(
                            id: tempList[i].id,
                            varientId: tempList[i].prVarientList![j].id,
                            qty: qty,
                            productList: prList,
                          ),
                        );
                      }
                    }
                  }
                  context.read<CartProvider>().setCartlist(cartSecList);
                }
                if (mounted) {
                  setState(() {
                    context.read<CartProvider>().setProgress(false);
                  });
                }
              },
              onError: (error) {
                setSnackbar(error.toString(), context);
              },
            );
          } on TimeoutException catch (_) {
            setSnackbar(getTranslated(context, 'somethingMSg')!, context);
            context.read<CartProvider>().setProgress(false);
          }
        } else {
          if (mounted) {
            setState(() {
              _isNetworkAvail = false;
              context.read<CartProvider>().setProgress(false);
            });
          }
        }
      } else {
        context.read<CartProvider>().setCartlist([]);
        setState(() {
          context.read<CartProvider>().setProgress(false);
        });
      }
    }
  }

  Future<void> _getOffFav() async {
    if (context.read<UserProvider>().userId == "") {
      final List<String> proIds = (await db.getFav())!;
      if (proIds.isNotEmpty) {
        _isNetworkAvail = await isNetworkAvailable();
        if (_isNetworkAvail) {
          try {
            final parameter = {"product_ids": proIds.join(',')};
            apiBaseHelper.postAPICall(getProductApi, parameter).then(
              (getdata) {
                final bool error = getdata["error"];
                if (!error) {
                  final data = getdata["data"];
                  final List<Product> tempList = (data as List)
                      .map((data) => Product.fromJson(data))
                      .toList();
                  context.read<FavoriteProvider>().setFavlist(tempList);
                }
                if (mounted) {
                  setState(() {
                    context.read<FavoriteProvider>().setLoading(false);
                  });
                }
              },
              onError: (error) {
                setSnackbar(error.toString(), context);
              },
            );
          } on TimeoutException catch (_) {
            setSnackbar(getTranslated(context, 'somethingMSg')!, context);
            context.read<FavoriteProvider>().setLoading(false);
          }
        } else {
          if (mounted) {
            setState(() {
              _isNetworkAvail = false;
              context.read<FavoriteProvider>().setLoading(false);
            });
          }
        }
      } else {
        context.read<FavoriteProvider>().setFavlist([]);
        setState(() {
          context.read<FavoriteProvider>().setLoading(false);
        });
      }
    }
  }

  Future<void> _getCart(String save) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (context.read<UserProvider>().userId != "") {
          try {
            final parameter = {
              USER_ID: context.read<UserProvider>().userId,
              SAVE_LATER: save,
              "only_delivery_charge": "0",
            };
            apiBaseHelper.postAPICall(getCartApi, parameter).then(
              (getdata) {
                final bool error = getdata["error"];
                if (!error) {
                  final data = getdata["data"];
                  final List<SectionModel> cartList = (data as List)
                      .map((data) => SectionModel.fromCart(data))
                      .toList();
                  context.read<CartProvider>().setCartlist(cartList);
                }
              },
              onError: (error) {
                setSnackbar(error.toString(), context);
              },
            );
          } on TimeoutException catch (_) {}
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

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(
        Iterable.generate(
          length,
          (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
        ),
      );
  Future<void> generateReferral() async {
    try {
      final String refer = getRandomString(8);
      final Map parameter = {
        REFERCODE: refer,
      };
      apiBaseHelper.postAPICall(validateReferalApi, parameter).then(
        (getdata) {
          final bool error = getdata["error"];
          if (!error) {
            REFER_CODE = refer;
            context
                .read<SettingProvider>()
                .setPrefrence(REFERCODE, REFER_CODE!);
            final Map parameter = {
              USER_ID: context.read<UserProvider>().userId,
              REFERCODE: refer,
            };
            apiBaseHelper.postAPICall(getUpdateUserApi, parameter);
          } else {
            if (count < 5) generateReferral();
            count++;
          }
          context.read<HomeProvider>().setSecLoading(false);
        },
        onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<HomeProvider>().setSecLoading(false);
        },
      );
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  updateDailog() async {
    await dialogAnimate(
      context,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setStater) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
            ),
            title: Text(getTranslated(context, 'UPDATE_APP')!),
            content: Text(
              getTranslated(context, 'UPDATE_AVAIL')!,
              style: Theme.of(this.context)
                  .textTheme
                  .titleMedium!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  getTranslated(context, 'NO')!,
                  style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.lightBlack,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(
                  getTranslated(context, 'YES')!,
                  style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop(false);
                  String url = '';
                  if (Platform.isAndroid) {
                    url = androidLink + packageName;
                  } else if (Platform.isIOS) {
                    url = iosLink;
                  }
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    throw 'Could not launch $url';
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget homeShimmer() {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: SingleChildScrollView(
          child: Column(
            children: [
              catLoading(),
              sliderLoading(),
              sectionLoading(),
            ],
          ),
        ),
      ),
    );
  }

  Widget sliderLoading() {
    final double width = deviceWidth!;
    final double height = width / 2;
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.simmerBase,
      highlightColor: Theme.of(context).colorScheme.simmerHigh,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: double.infinity,
        height: height,
        color: Theme.of(context).colorScheme.white,
      ),
    );
  }

 


Widget _buildImagePageItem(Model slider) {
  final double height = deviceWidth! / 1.8; // Adjust height for better aspect ratio

  return GestureDetector(
    onTap: () async {
      final int curSlider = context.read<HomeProvider>().curSlider;
      if (homeSliderList[curSlider].type == "products") {
        final Product? item = homeSliderList[curSlider].list;
        Navigator.pushNamed(
          context,
          Routers.productDetails,
          arguments: {
            "secPos": 0,
            "index": 0,
            "list": true,
            "id": item!.id!,
          },
        );
      } else if (homeSliderList[curSlider].type == "categories") {
        final Product item = homeSliderList[curSlider].list!;
        if (item.subList == null || item.subList!.isEmpty) {
          Navigator.pushNamed(
            context,
            Routers.productListScreen,
            arguments: {
              "name": item.name,
              "id": item.id,
              "tag": false,
              "fromSeller": false,
            },
          );
        } else {
          Navigator.pushNamed(
            context,
            Routers.subCategoryScreen,
            arguments: {
              "title": item.name,
              "subList": item.subList,
            },
          );
        }
      } else if (homeSliderList[curSlider].type == "slider_url") {
        final String url = homeSliderList[curSlider].urlLink.toString();
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Error launching URL: $e');
        }
      }
    },
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cached Image for better performance
            CachedNetworkImage(
              imageUrl: slider.image!,
              width: double.infinity,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(Icons.error, size: 50, color: Colors.red),
              ),
            ),
            // Gradient Overlay for better readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Optional Text Overlay (Remove if not needed)
            Positioned(
              bottom: 15,
              left: 15,
              child: Text(
                slider.title ?? '', // Ensure title exists
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget deliverLoading() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.simmerBase,
      highlightColor: Theme.of(context).colorScheme.simmerHigh,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        width: double.infinity,
        height: 18.0,
        color: Theme.of(context).colorScheme.white,
      ),
    );
  }

  Widget catLoading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                  .map(
                    (_) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.white,
                        shape: BoxShape.circle,
                      ),
                      width: 50.0,
                      height: 50.0,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ),
      ],
    );
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              context.read<HomeProvider>().setCatLoading(true);
              context.read<HomeProvider>().setSecLoading(true);
              context.read<HomeProvider>().setOfferLoading(true);
              context.read<HomeProvider>().setMostLikeLoading(true);
              context.read<HomeProvider>().setSliderLoading(true);
              _playAnimation();
              Future.delayed(const Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  if (mounted) {
                    setState(() {
                      _isNetworkAvail = true;
                    });
                  }
                  callApi();
                } else {
                  await buttonController.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          ),
        ],
      ),
    );
  }

 

  _getSearchBar() {
  return Column(
    children: [
      const SizedBox(height: 15), // ✅ Adjust this value for more spacing
      InkWell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 44,
            child: TextField(
              enabled: false,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(15.0, 5.0, 0, 5.0),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(50.0),
                  ),
                ),
                isDense: true,
                hintText: getTranslated(context, 'searchHint'),
                hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                    ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SvgPicture.asset(
                    'assets/images/search.svg',
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primarytheme,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                fillColor: Theme.of(context).colorScheme.lightWhite,
                filled: true,
              ),
            ),
          ),
        ),
        onTap: () async {
          await Navigator.pushNamed(context, Routers.searchScreen);
          if (mounted) setState(() {});
        },
      ),
    ],
  );
}




  

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {
      return;
    }
  }

  void getSlider() {
    try {
      final Map map = {};
      apiBaseHelper.postAPICall(getSliderApi, map).then(
        (getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
            final data = getdata["data"];
            homeSliderList =
                (data as List).map((data) => Model.fromSlider(data)).toList();
            pages = homeSliderList.map((slider) {
              return _buildImagePageItem(slider);
            }).toList();
          } else {
            setSnackbar(msg!, context);
          }
          context.read<HomeProvider>().setSliderLoading(false);
        },
        onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<HomeProvider>().setSliderLoading(false);
        },
      );
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  void getCat() {
    try {
      final Map parameter = {
        CAT_FILTER: "false",
      };
      apiBaseHelper.postAPICall(getCatApi, parameter).then(
        (getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
            final data = getdata["data"];
            catList =
                (data as List).map((data) => Product.fromCat(data)).toList();
            
          } else {
            setSnackbar(msg!, context);
          }
          context.read<HomeProvider>().setCatLoading(false);
        },
        onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<HomeProvider>().setCatLoading(false);
        },
      );
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  sectionLoading() {
    return Column(
      children: [0, 1, 2, 3, 4]
          .map(
            (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 40),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 5,
                            ),
                            width: double.infinity,
                            height: 18.0,
                            color: Theme.of(context).colorScheme.white,
                          ),
                          GridView.count(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 5,
                            crossAxisSpacing: 5,
                            children: List.generate(
                              4,
                              (index) {
                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Theme.of(context).colorScheme.white,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                sliderLoading(),
              ],
            ),
          )
          .toList(),
    );
  }

  Future<void> appMaintenanceDialog() async {
    await dialogAnimate(
      context,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setStater) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
              ),
              title: Text(
                getTranslated(context, 'APP_MAINTENANCE')!,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    child: Lottie.asset('assets/animation/maintenance.json'),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Text(
                    IS_APP_MAINTENANCE_MESSAGE != ''
                        ? IS_APP_MAINTENANCE_MESSAGE!
                        : getTranslated(
                            context, 'MAINTENANCE_DEFAULT_MESSAGE',)!,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
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

  Future<void> showPopUpOfferDialog() async {
    PopupOfferDialog(
      onDialogClick: () {},
      popupOffer: popUpOffer,
    ).show(context);
  }
}

class BrandsListWidget extends StatelessWidget {
  const BrandsListWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrandsListCubit, BrandsListState>(
      builder: (context, state) {
        if (state is BrandsListSuccess) {
          return state.brands.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        getTranslated(context, 'Brands')!,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontFamily: 'ubuntu',
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          itemCount: state.brands.length,
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(end: 18),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    Routers.productListScreen,
                                    arguments: {
                                      "name": state.brands[index].name,
                                      "id": state.brands[index].id,
                                      "brandId": state.brands[index].id,
                                      "tag": false,
                                      "fromSeller": false,
                                    },
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: networkImageCommon(
                                        state.brands[index].image,
                                        60,
                                        false,
                                        boxFit: BoxFit.cover,
                                        height: 60.0,
                                        width: 60.0,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: SizedBox(
                                        width: 60,
                                        child: Text(
                                          state.brands[index].name,
                                          maxLines: 2,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                fontFamily: 'ubuntu',
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink();
        } else if (state is BrandsListInProgress) {
          return SizedBox(
            width: double.infinity,
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.simmerBase,
              highlightColor: Theme.of(context).colorScheme.simmerHigh,
              child: brandLoading(context),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  static Widget brandLoading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: 100,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                  .map(
                    (_) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.white,
                        shape: BoxShape.circle,
                      ),
                      width: 50.0,
                      height: 50.0,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ),
      ],
    );
  }
}


class NeumorphicSections extends StatelessWidget {
  final bool minimal;
  NeumorphicSections({this.minimal = false});

  final List<Map<String, dynamic>> sections = [
    {
      "title": "MOST_NEEDED_MOSQUES",
      "icon": Icons.water_drop,
      "route": Routers.mostNeededMosquesScreen,
      "color": Color(0xFF26897e),
    },
    {
      "title": "QATAR_MOSQUES",
      "icon": Icons.location_on,
      "route": Routers.qatarMosquesScreen,
      "color": Color(0xFF1ebaaa),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10,10,10,0), // Reduced bottom padding from 10 to 5
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 0,
          childAspectRatio: 1.5,
        ),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          return _buildNeumorphicCard(
            context,
            title: sections[index]["title"],
            icon: sections[index]["icon"],
            color: sections[index]["color"],
            route: sections[index]["route"],
          );
        },
      ),
    );
  }

  Widget _buildNeumorphicCard(
    BuildContext context, {
    required String title,
    required dynamic icon,
    required Color color,
    required String route,
    String? categoryId,
  }) {
    Widget iconWidget;
    if (icon is IconData) {
      iconWidget = NeumorphicIcon(
        icon,
        size: 55,
        style: NeumorphicStyle(
          color: Colors.white,
          depth: 4,
        ),
      );
    } else if (icon is String) {
      iconWidget = Image.asset(
        icon,
        width: 70,
        height: 70,
      );
    } else {
      iconWidget = const SizedBox.shrink();
    }

    return NeumorphicButton(
      onPressed: () {
        if (categoryId != null) {
          Navigator.pushNamed(context, route, arguments: {
            "name": getTranslated(context, title) ?? title,
            "tag": false,
            "fromSeller": false,
          });
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      style: NeumorphicStyle(
        depth: 0,
        intensity: 0,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(18)),
        color: color,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 6),
          Text(
            getTranslated(context, title) ?? title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}