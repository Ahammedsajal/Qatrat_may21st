import 'package:translator/translator.dart';

final GoogleTranslator translator = GoogleTranslator();

Future<String> translateDynamicText(String text, String targetLang) async {
  final translation = await translator.translate(text, to: targetLang);
  return translation.text;
}
