import 'package:flutter/material.dart';

extension TextThemeForFont on TextTheme {
  Font get font => Font();
}

extension CustomContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  ColorScheme get color => Theme.of(this).colorScheme;
  Font get font => Theme.of(this).textTheme.font;
}

class Font {
  double get smaller => 10;
  double get small => 12;
  double get normal => 14;
  double get large => 16;
  double get larger => 18;
  double get extraLarge => 24;
  double get xxLarge => 28;
}
