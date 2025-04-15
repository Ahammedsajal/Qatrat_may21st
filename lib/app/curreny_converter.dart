// currency_converter.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Returns the currency symbol for a given [code].
String currencySymbol(String code) {
  switch (code) {
    case 'QAR':
      return 'ر.ق';
    case 'SAR':
      return 'ر.س';
    case 'AED':
      return 'د.إ';
    case 'KWT':
      return 'د.ك';
    case 'OMN':
      return 'ر.ع.';
    case 'USD':
      return '\$';
    default:
      return ''; // Returns an empty string if code is not provided or unknown.
  }
}

/// Service to provide currency conversion rates manually.
class CurrencyService {
  /// Predefined manual conversion rates.
  final Map<String, double> _manualRates = {
    'QAR': 1.0,
    'SAR': 0.98,
    'AED': 0.99,
    'KWT': 0.07,
    'OMN': 0.11,
    'USD': 0.27,
  };

  Future<Map<String, double>> fetchRates() async {
    // Returns the manual conversion rates directly without an API call.
    return _manualRates;
  }
}

/// Provider to manage currency state and conversion.
class CurrencyProvider extends ChangeNotifier {
  final CurrencyService _service = CurrencyService();
  Map<String, double> _rates = {};
  String _selectedCurrency = 'QAR';

  Map<String, double> get rates => _rates;
  String get selectedCurrency => _selectedCurrency;

  CurrencyProvider() {
    loadRates();
  }

  Future<void> loadRates() async {
    try {
      _rates = await _service.fetchRates();
      debugPrint("Loaded manual rates: $_rates");
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading manual rates: $e");
      // In case of error, fallback to a predefined set.
      _rates = {
        'QAR': 1.0,
        'SAR': 0.98,
        'AED': 0.99,
        'KWT': 0.07,
        'OMN': 0.11,
        'USD': 0.27,
      };
      notifyListeners();
    }
  }

  /// Change the currently selected currency.
  void changeCurrency(String currency) {
    _selectedCurrency = currency;
    debugPrint("Currency changed to: $_selectedCurrency");
    notifyListeners();
  }

  /// Converts a price (assumed to be in QAR) into the selected currency.
  double convertPrice(double priceInQAR) {
    final rate = _rates[_selectedCurrency] ?? 1.0;
    debugPrint("Converting $priceInQAR QAR using rate $rate for $_selectedCurrency");
    return priceInQAR * rate;
  }
}

/// A widget that displays a converted price.
/// 
/// [basePrice] should be the product’s price in QAR (as provided by your backend).
/// Set [isOriginal] to true if you want to display the original price (e.g. with a strikethrough).
Widget buildConvertedPrice(
  BuildContext context,
  double basePrice, {
  bool isOriginal = false,
  TextStyle? style,
}) {
  return Consumer<CurrencyProvider>(
    builder: (context, currencyProvider, child) {
      double convertedPrice = currencyProvider.convertPrice(basePrice);
      return Text(
        "${currencySymbol(currencyProvider.selectedCurrency)} ${convertedPrice.toStringAsFixed(2)}",
        style: style ??
            (isOriginal
                ? Theme.of(context).textTheme.labelSmall!.copyWith(
                      decoration: TextDecoration.lineThrough,
                      letterSpacing: 0,
                    )
                : Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    )),
      );
    },
  );
}
