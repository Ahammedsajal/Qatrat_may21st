import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  // Define your manual conversion rates.
  // Be sure to update the values if your conversion rates change.
  final Map<String, double> _manualRates = {
    'QAR': 1.0,
    'SAR': 0.98,  // Example rate: 1 QAR = 0.98 SAR
    'AED': 0.98,  // Example rate: 1 QAR = 0.98 AED
    'KWD': 0.09,  // Example rate: 1 QAR = 0.09 KWD
    'OMR': 0.10,  // Example rate: 1 QAR = 0.10 OMR
    'USD': 0.27,  // Example rate: 1 QAR = 0.27 USD
  };

  Future<Map<String, double>> fetchRates() async {
    // Simply return the manual conversion rates
    return _manualRates;
  }
}

