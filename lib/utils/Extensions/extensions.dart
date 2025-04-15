import 'package:flutter/cupertino.dart';
export 'lib/build_context.dart';
export 'lib/color.dart';
export 'lib/date.dart';
export 'lib/textWidgetExtention.dart';

extension ScrollEndListen on ScrollController {
  bool isEndReached() {
    if (offset >= position.maxScrollExtent) {
      return true;
    }
    return false;
  }
}
