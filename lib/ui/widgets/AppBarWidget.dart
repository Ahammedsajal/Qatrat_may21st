import 'package:customer/Helper/Color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../Helper/Session.dart';
import '../../Provider/UserProvider.dart';
import '../../Screen/cart/Cart.dart';
import '../../app/routes.dart';
import '../styles/DesignConfig.dart';

getAppBar(String title, BuildContext context, {int? from}) {
  return AppBar(
    elevation: 0,
    titleSpacing: 0,
    backgroundColor: Theme.of(context).colorScheme.white,
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
    }),
    title: Text(title,
        style: TextStyle(
            color: Theme.of(context).colorScheme.primarytheme,
            fontWeight: FontWeight.normal)),
    actions: <Widget>[
      // --- Currency Converter Dropdown ---
      // Add the currency selector as the first action.
    

      // Rest of your existing actions:
      if (from == 1)
        const SizedBox()
      else
        IconButton(
          icon: SvgPicture.asset(
            "${imagePath}search.svg",
            height: 20,
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.blackInverseInDarkTheme,
                BlendMode.srcIn),
          ),
          onPressed: () {
            Navigator.pushNamed(
              context,
              Routers.searchScreen,
            );
          },
        ),
      if (from == 1)
        const SizedBox()
      else if (title == getTranslated(context, 'FAVORITE')!)
        const SizedBox.shrink()
      else
        IconButton(
          padding: EdgeInsets.zero,
          icon: SvgPicture.asset(
            "${imagePath}desel_fav.svg",
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.blackInverseInDarkTheme,
                BlendMode.srcIn),
          ),
          onPressed: () {
            Navigator.pushNamed(
              context,
              Routers.favoriteScreen,
            );
          },
        ),
      if (from == 1)
        const SizedBox()
      else
        Selector<UserProvider, String>(
          builder: (context, data, child) {
            return IconButton(
              icon: Stack(
                children: [
                  Center(
                      child: SvgPicture.asset(
                    "${imagePath}appbarCart.svg",
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.blackInverseInDarkTheme,
                        BlendMode.srcIn),
                  )),
                  if (data.isNotEmpty && data != "0")
                    Positioned(
                      bottom: 20,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primarytheme,
                        ),
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
                                      .white),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
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
  );
}
