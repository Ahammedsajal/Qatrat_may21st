import 'package:flutter/material.dart';

enum SlideDirection { fromTop, fromLeft, fromRight, fromBottom }

class SlideAnimation extends StatefulWidget {
  final int position;
  final int itemCount;
  final Widget? child;
  final SlideDirection slideDirection;
  final AnimationController? animationController;
  const SlideAnimation({
    super.key,
    required this.position,
    required this.itemCount,
    required this.slideDirection,
    required this.animationController,
    required this.child,
  });
  @override
  _SlideAnimationState createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation> {
  @override
  Widget build(BuildContext context) {
    var xTranslation = 0.0;
    var yTranslation = 0.0;
    final animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: widget.animationController!,
      curve: Interval((1 / widget.itemCount) * widget.position, 1.0,
          curve: Curves.fastOutSlowIn,),
    ),);
    widget.animationController!.forward();
    return AnimatedBuilder(
      animation: widget.animationController!,
      builder: (context, child) {
        if (widget.slideDirection == SlideDirection.fromTop) {
          yTranslation = -50 * (1.0 - animation.value);
        } else if (widget.slideDirection == SlideDirection.fromBottom) {
          yTranslation = 50 * (1.0 - animation.value);
        } else if (widget.slideDirection == SlideDirection.fromRight) {
          xTranslation = 400 * (1.0 - animation.value);
        } else {
          xTranslation = -400 * (1.0 - animation.value);
        }
        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform:
                Matrix4.translationValues(xTranslation, yTranslation, 0.0),
            child: widget.child,
          ),
        );
      },
    );
  }
}
