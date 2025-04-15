import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class BlurredRouter extends PageRoute<void> {
  final double? sigmaX;
  final double? sigmaY;
  final bool? barrierDismiss;

  BlurredRouter({
    required this.builder,
    this.barrierDismiss,
    super.settings,
    this.sigmaX,
    this.sigmaY,
  }) : super(fullscreenDialog: false);

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => barrierDismiss ?? super.barrierDismissible;

  @override
  String get barrierLabel => "blurred";

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final result = builder(context);

    // Check if the platform is iOS, but also consider web compatibility
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    if (isIOS) {
      final theme = Theme.of(context).pageTransitionsTheme;
      return theme.buildTransitions(
        this,
        context,
        animation,
        secondaryAnimation,
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: sigmaX ?? 5,
            sigmaY: sigmaY ?? 10,
          ),
          child: result,
        ),
      );
    }

    // Default for other platforms and web
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: sigmaX ?? 5,
          sigmaY: sigmaY ?? 10,
        ),
        child: result,
      ),
    );
  }
}
