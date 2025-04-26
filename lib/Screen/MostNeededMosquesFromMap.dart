import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Model/MosqueModel.dart';
import '../Provider/MosqueProvider.dart';
import '../cubits/FetchMosquesCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../ui/widgets/SimpleAppBar.dart';
import '../ui/widgets/AppBarWidget.dart';
import 'dart:async';
import 'dart:math';
import 'package:collection/src/iterable_extensions.dart';
import 'package:customer/Helper/SqliteData.dart';
import 'package:customer/Provider/CartProvider.dart';
import 'package:customer/Provider/FavoriteProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/app/routes.dart';
import 'package:customer/ui/widgets/AppBtn.dart';
import 'package:customer/ui/widgets/SimBtn.dart';
import 'package:customer/ui/widgets/Slideanimation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import 'package:customer/Helper/String.dart' hide currencySymbol;
import 'package:customer/app/curreny_converter.dart';
import '../Model/Section_Model.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';
import 'Search.dart';
import '../ui/widgets/product_list_content.dart';

import '../Screen/ProductList.dart';

class MostNeededMosquesFromMap extends StatefulWidget {
  final List<MosqueModel> mosques;

  const MostNeededMosquesFromMap({Key? key, required this.mosques}) : super(key: key);

  @override
  _MostNeededMosquesFromMapState createState() => _MostNeededMosquesFromMapState();
}

class _MostNeededMosquesFromMapState extends State<MostNeededMosquesFromMap> {
  MosqueModel? _selectedMosque;

  @override
  void initState() {
    super.initState();
    // Retrieve the pre-selected mosque from the provider.
    _selectedMosque = context.read<MosqueProvider>().selectedMosque;
  }

  @override
  @override
Widget build(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == "ar";

  final displayName = _selectedMosque != null
      ? isArabic
          ? (_selectedMosque!.nameAr?.isNotEmpty ?? false
              ? _selectedMosque!.nameAr!
              : _selectedMosque!.name)
          : _selectedMosque!.name
      : "";

  final displayAddress = _selectedMosque != null
      ? isArabic
          ? (_selectedMosque!.addressAr?.isNotEmpty ?? false
              ? _selectedMosque!.addressAr!
              : getTranslated(context, 'NO_ADDRESS_PROVIDED') ?? "No Address Provided")
          : (_selectedMosque!.address?.isNotEmpty ?? false
              ? _selectedMosque!.address!
              : getTranslated(context, 'NO_ADDRESS_PROVIDED') ?? "No Address Provided")
      : "";

  return Scaffold(
    appBar: getAppBar(
      getTranslated(context, 'MOST_NEEDED_MOSQUES') ?? 'Most Needed Mosques',
      context,
    ),
    body: Column(
      children: [
        // Display selected mosque (if any) inside a Card.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: _selectedMosque == null
              ? Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    getTranslated(context, 'NO_MOSQUE_SELECTED') ?? "No Mosque Selected",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'DELIVERING_TO_MOSQUE') ?? "Delivering to:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        title: Text(
                          "${_selectedMosque!.id} - $displayName",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          displayAddress,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
        ),

        // Clear or change mosque selection
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.clear,
                  title: getTranslated(context, 'CLEAR_MOSQUE') ?? "Clear Mosque",
                  onTap: () {
                    setState(() {
                      _selectedMosque = null;
                    });
                    context.read<MosqueProvider>().clearSelectedMosque();
                  },
                  fontSize: 12,
                  iconSize: 18,
                  verticalPadding: 6,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  icon: Icons.map,
                  title: getTranslated(context, 'CHANGE_MOSQUE') ?? "Change Mosque",
                  onTap: () {
                    Navigator.pushNamed(context, Routers.qatarMosquesScreen);
                  },
                  fontSize: 12,
                  iconSize: 18,
                  verticalPadding: 6,
                ),
              ),
            ],
          ),
        ),

        // Product list content below.
        const Expanded(
          child: ProductListContent(
            id: "111",
            tag: false,
            fromSeller: false,
          ),
        ),
      ],
    ),
  );
}

}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final double fontSize;
  final double iconSize;
  final double verticalPadding;

  const _ActionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.fontSize = 14,
    this.iconSize = 20,
    this.verticalPadding = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: iconSize),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
