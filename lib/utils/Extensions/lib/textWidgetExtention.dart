import 'package:flutter/material.dart';

extension StyledText<T extends Text> on T {
  Text copyWith({
    String? data,
    InlineSpan? textSpan,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    bool? softWrap,
    TextOverflow? overflow,
    TextScaler? textScaler,
    Locale? locale,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
  }) {
    return Text(
      data ?? this.data ?? "",
      style: style ?? this.style,
      locale: locale ?? this.locale,
      maxLines: maxLines ?? this.maxLines,
      overflow: overflow ?? this.overflow,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      softWrap: softWrap ?? this.softWrap,
      strutStyle: strutStyle ?? this.strutStyle,
      textAlign: textAlign ?? this.textAlign,
      textDirection: textDirection ?? this.textDirection,
      textHeightBehavior: textHeightBehavior ?? this.textHeightBehavior,
      textScaler: textScaler ?? this.textScaler,
      textWidthBasis: textWidthBasis ?? this.textWidthBasis,
    );
  }

  T bold({FontWeight? weight}) => copyWith(
        style: (style ?? const TextStyle()).copyWith(
          fontWeight: weight ?? FontWeight.bold,
        ),
      ) as T;
  T setMaxLines({required int lines}) {
    return copyWith(
        maxLines: lines, overflow: TextOverflow.ellipsis, softWrap: true,) as T;
  }

  T italic() {
    return copyWith(
      style: (style ?? const TextStyle()).copyWith(fontStyle: FontStyle.italic),
    ) as T;
  }

  T size(double size) {
    return copyWith(
        style: (style ?? const TextStyle()).copyWith(fontSize: size),) as T;
  }

  T color(Color color) {
    return copyWith(style: (style ?? const TextStyle()).copyWith(color: color))
        as T;
  }

  T underline() => copyWith(
        style: (style ?? const TextStyle())
            .copyWith(decoration: TextDecoration.underline),
      ) as T;
  T centerAlign() => copyWith(textAlign: TextAlign.center) as T;
  T firstUpperCaseWidget() {
    String upperCase = "";
    var suffix = "";
    if (data?.isNotEmpty ?? true) {
      upperCase = data?[0].toUpperCase() ?? "";
      suffix = data!.substring(1, data?.length);
    }
    return copyWith(data: upperCase + suffix) as T;
  }
}
