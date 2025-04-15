import 'package:flutter/material.dart';
import '../Model/MosqueModel.dart';

class MosqueProvider extends ChangeNotifier {
  MosqueModel? _selectedMosque;

  MosqueModel? get selectedMosque => _selectedMosque;

  /// Set a new selected Mosque and notify listeners
  void setSelectedMosque(MosqueModel mosque) {
    _selectedMosque = mosque;
    notifyListeners();
  }

  /// Clear the selected Mosque
  void clearSelectedMosque() {
    _selectedMosque = null;
    notifyListeners();
  }
}
