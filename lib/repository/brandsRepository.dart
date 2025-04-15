import 'package:customer/Helper/ApiBaseHelper.dart';
import 'package:customer/Helper/Constant.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Model/brandModel.dart';
import 'package:customer/ui/widgets/ApiException.dart';

class BrandsRepository {
  Future<List<BrandData>> getAllBrands() async {
    try {
      final responseData = await ApiBaseHelper().postAPICall(getBrandsApi, {});
      return responseData['data']
          .map<BrandData>((e) => BrandData.fromJson(e))
          .toList();
    } on Exception catch (e) {
      throw ApiException('$errorMesaage$e');
    }
  }
}
