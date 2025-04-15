import 'package:customer/Helper/ApiBaseHelper.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Model/Section_Model.dart';
import 'package:customer/ui/widgets/ApiException.dart';
import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<SectionModel> _cartList = [];
  List<SectionModel> get cartList => _cartList;
  bool _isProgress = false;
  get cartIdList => _cartList.map((fav) => fav.varientId).toList();
  get isProgress => _isProgress;
  setProgress(bool progress) {
    _isProgress = progress;
    notifyListeners();
  }

  bool _isProductInCart = false;
  bool get isProductInCart => _isProductInCart;
  void updateIsProductInCart(bool value) {
    _isProductInCart = value;
    notifyListeners();
  }

  removeCartItem(String id, {int? index}) {
    if (index != null) {
      _cartList.removeWhere(
          (item) => item.productList![0].prVarientList![index].id == id,);
    } else {
      _cartList.removeWhere((item) => item.varientId == id);
    }
    notifyListeners();
  }

  void clearCartExcept(SectionModel itemsToKeep) {
    _cartList
        .removeWhere((element) => element.varientId != itemsToKeep.varientId);
    notifyListeners();
  }

  addCartItem(SectionModel? item) {
    if (item != null) {
      _cartList.add(item);
      notifyListeners();
    }
  }

  updateCartItem(String? id, String qty, int index, String vId) {
    final i = _cartList.indexWhere((cp) => cp.id == id && cp.varientId == vId);
    _cartList[i].qty = qty;
    _cartList[i].productList![0].prVarientList![index].cartCount = qty;
    notifyListeners();
  }
void clearCart() {
  _cartList.clear();
  notifyListeners();
}

  setCartlist(List<SectionModel> cartList) {
    _cartList.clear();
    _cartList.addAll(cartList);
    notifyListeners();
  }
}
