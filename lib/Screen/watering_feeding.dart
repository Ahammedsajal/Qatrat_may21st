import 'package:flutter/material.dart';
import 'package:customer/ui/widgets/AppBtn.dart';
import '../ui/widgets/AppBarWidget.dart'; // This file should contain getSimpleAppBar.
import '../Helper/Constant.dart';
import 'package:customer/Helper/String.dart';
import '../Model/Section_Model.dart';
import '../ui/styles/DesignConfig.dart';
import '../Helper/Session.dart';
import '../ui/widgets/SimpleAppBar.dart';

class WateringFeeding extends StatelessWidget {
  final bool fromSeller;
  final String? name;

  const WateringFeeding({Key? key, this.fromSeller = false, this.name})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using the simple app bar widget.
      appBar: fromSeller
    ? null
    : getSimpleAppBar(
        name ?? (getTranslated(context, 'FOOD_DATES') ?? "FOOD_DATES"),
        context,
      ),

      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10.0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This feature is under development. Stay tuned for updates!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
