import 'package:customer/Model/language_model.dart';
import '../utils/language_manager.dart';

class Languages extends LanguageManager {
  @override
  final String defaultLanguageCode = "en";
  @override
  List<Language> supported() {
    return const [
      Language(code: "en", languageName: "English", languageSubName: "إنجليزي"),
     
      Language(code: "ar", languageName: "Arabic", languageSubName: "عربي"),
      
    ];
  }
}
