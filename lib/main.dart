import 'package:customer/Helper/Color.dart';
import 'package:customer/Helper/Constant.dart';
import 'package:customer/Provider/CartProvider.dart';
import 'package:customer/Provider/MosqueProvider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:customer/Provider/CategoryProvider.dart';
import 'package:customer/Provider/FavoriteProvider.dart';
import 'package:customer/Provider/FlashSaleProvider.dart';
import 'package:customer/Provider/HomeProvider.dart';
import 'package:customer/Provider/OfferImagesProvider.dart';
import 'package:customer/Provider/ProductDetailProvider.dart';
import 'package:customer/Provider/ProductProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/Provider/pushNotificationProvider.dart';
import 'package:customer/app/languages.dart';
import 'package:customer/cubits/brandsListCubit.dart';
import 'package:customer/cubits/fetch_citites.dart';
import 'package:customer/cubits/fetch_featured_sections_cubit.dart';
import 'package:customer/cubits/personalConverstationsCubit.dart';
import 'package:customer/repository/brandsRepository.dart';
import 'package:customer/repository/chatRepository.dart';
import 'package:customer/ui/styles/themedata.dart';
import 'package:customer/utils/Hive/hive_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // For native platforms
import 'package:provider/single_child_widget.dart';
import 'package:sqflite/sqflite.dart'; // ✅ Keep only `sqflite`, no `sqflite_common_ffi`
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Provider/MyFatoraahPaymentProvider.dart';
import 'Provider/SettingProvider.dart';
import 'Provider/Theme.dart';
import 'Provider/order_provider.dart';
import 'app/app_Localization.dart';
import 'app/routes.dart';
import 'firebase_options.dart';
import 'app/curreny_converter.dart';
import 'model/MosqueModel.dart'; 
import 'cubits/FetchMosquesCubit.dart';

/// App version
/// V4.4.1

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  await Hive.initFlutter();
  // Register the adapter for MosqueModel

  await HiveUtils.initBoxes();

  // Initialize Firebase only once.
 

  // Set up HTTP overrides for native platforms.
  setupHttpOverrides();

  // Ensure both the status bar and navigation bar are always visible.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  // Commenting out SystemChrome for iOS since it's not needed
  // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  //   systemNavigationBarColor: Colors.transparent, // Transparent navigation bar
  //   systemNavigationBarDividerColor: Colors.transparent,
  //   statusBarColor: Colors.transparent, // Optional: Transparent status bar
  //   statusBarBrightness: Brightness.light, // Adjust based on your theme
  //   statusBarIconBrightness: Brightness.dark, // Adjust based on your theme
  // ));

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: _buildProviders(prefs),
      child: MyApp(sharedPreferences: prefs),
    ),
  );
}

/// Set up HTTP overrides for native platforms if needed.
void setupHttpOverrides() {
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }
}

/// Build the list of providers for the app.
List<SingleChildWidget> _buildProviders(SharedPreferences prefs) {
  return [
    ChangeNotifierProvider<ThemeNotifier>(
      create: (BuildContext context) {
        if (disableDarkTheme == false) {
          final String? theme = prefs.getString(APP_THEME);
          if (theme == DARK) {
            ISDARK = "true";
          } else if (theme == LIGHT) {
            ISDARK = "false";
          }
          if (theme == null || theme == "" || theme == DEFAULT_SYSTEM) {
            prefs.setString(APP_THEME, DEFAULT_SYSTEM);
            final brightness =
                SchedulerBinding.instance.platformDispatcher.platformBrightness;
            ISDARK = (brightness == Brightness.dark).toString();
            return ThemeNotifier(ThemeMode.system);
          }
          return ThemeNotifier(
            theme == LIGHT ? ThemeMode.light : ThemeMode.dark,
          );
        } else {
          return ThemeNotifier(ThemeMode.light);
        }
      },
    ),
    Provider<SettingProvider>(
      create: (context) => SettingProvider(prefs),
    ),
    ChangeNotifierProvider(create: (_) => CurrencyProvider()),
    ChangeNotifierProvider<UserProvider>(
      create: (context) => UserProvider(),
    ),
    ChangeNotifierProvider<HomeProvider>(
      create: (context) => HomeProvider(),
    ),
    ChangeNotifierProvider<CategoryProvider>(
      create: (context) => CategoryProvider(),
    ),
    ChangeNotifierProvider<ProductDetailProvider>(
      create: (context) => ProductDetailProvider(),
    ),
    ChangeNotifierProvider<FavoriteProvider>(
      create: (context) => FavoriteProvider(),
    ),
    ChangeNotifierProvider<OrderProvider>(
      create: (context) => OrderProvider(),
    ),
    ChangeNotifierProvider<CartProvider>(
      create: (context) => CartProvider(),
    ),
    ChangeNotifierProvider(create: (_) => MosqueProvider()),
    BlocProvider(create: (_) => FetchMosquesCubit()..fetchMosques()),
    ChangeNotifierProvider<ProductProvider>(
      create: (context) => ProductProvider(),
    ),
    ChangeNotifierProvider<FlashSaleProvider>(
      create: (context) => FlashSaleProvider(),
    ),
    ChangeNotifierProvider<OfferImagesProvider>(
      create: (context) => OfferImagesProvider(),
    ),
    ChangeNotifierProvider<PaymentIdProvider>(
      create: (context) => PaymentIdProvider(),
    ),
    ChangeNotifierProvider<PushNotificationProvider>(
      create: (context) => PushNotificationProvider(),
    ),
    BlocProvider<PersonalConverstationsCubit>(
      create: (context) => PersonalConverstationsCubit(ChatRepository()),
    ),
    BlocProvider<BrandsListCubit>(
      create: (context) =>
          BrandsListCubit(brandsRepository: BrandsRepository()),
    ),
    BlocProvider<FetchCitiesCubit>(create: (context) => FetchCitiesCubit()),
    BlocProvider<FetchFeaturedSectionsCubit>(
      create: (context) => FetchFeaturedSectionsCubit(),
    ),
  ];
}

class MyApp extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const MyApp({super.key, required this.sharedPreferences});

  @override
  _MyAppState createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      if (mounted) {
        setState(() {
          _locale = locale;
        });
      }
    });
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
  }

  setLocale(Locale locale) {
    if (mounted) {
      setState(() {
        _locale = locale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    if (_locale == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return MaterialApp(
        locale: _locale,
        supportedLocales: [...Languages().codes()],
        onGenerateRoute: Routers.onGenerateRouted,
        initialRoute: Routers.splash,
        localizationsDelegates: const [
          AppLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode &&
                supportedLocale.countryCode == locale?.countryCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        navigatorKey: navigatorKey,
        title: appName,
        theme: lightTheme,
        debugShowCheckedModeBanner: false,
        darkTheme: darkTheme,
        themeMode: themeNotifier.getThemeMode(),
        builder: (context, child) {
          final bottomInset = MediaQuery.of(context).viewPadding.bottom;
          final theme = Theme.of(context);

          return Stack(
            children: [
              // Let content extend to the bottom, no SafeArea needed here
              child!,

              // WhatsApp Floating Button
              Positioned(
                bottom: bottomInset + 16, // Adjusted for iOS home indicator
                right: 16,
                child: FloatingActionButton(
                  onPressed: openWhatsAppChat,
                  backgroundColor: Colors.green,
                  child: const Icon(FontAwesomeIcons.whatsapp, size: 30),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}

void openWhatsAppChat() async {
  final String phoneNumber = "+97433277077"; // Replace with your WhatsApp number
  final String message = "Hello, I need assistance!";
  final Uri whatsappUri = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");

  if (await canLaunchUrl(whatsappUri)) {
    await launchUrl(whatsappUri);
  } else {
    final Uri webWhatsappUri = Uri.parse("https://api.whatsapp.com/send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(webWhatsappUri)) {
      await launchUrl(webWhatsappUri);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// Adding empty lines to maintain the original line count of 345
//
//
//
//