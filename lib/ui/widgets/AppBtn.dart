import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../Helper/Color.dart';

class AppBtn extends StatelessWidget {
  final String? title;
  final AnimationController? btnCntrl;
  final Animation? btnAnim;
  final VoidCallback? onBtnSelected;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? fontColor;
  const AppBtn(
      {super.key,
      this.title,
      this.btnCntrl,
      this.btnAnim,
      this.onBtnSelected,
      this.padding,
      this.color,
      this.fontColor,});
  @override
  Widget build(BuildContext context) {
    final initialWidth = btnAnim!.value;
    return AnimatedBuilder(
      builder: (c, child) => _buildBtnAnimation(
        c,
        child,
        initialWidth: initialWidth,
      ),
      animation: btnCntrl!,
    );
  }

  Widget _buildBtnAnimation(BuildContext context, Widget? child,
      {required double initialWidth,}) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 18),
      child: CupertinoButton(
        child: Container(
          width: btnAnim!.value,
          height: 50,
          alignment: FractionalOffset.center,
          decoration: BoxDecoration(
            color: color ?? Theme.of(context).colorScheme.primarytheme,
            boxShadow: [
              BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 8),
                  color: color == null
                      ? Theme.of(context)
                          .colorScheme
                          .primarytheme
                          .withOpacity(0.4)
                      : color!.withOpacity(0.4),),
            ],
            borderRadius: const BorderRadius.all(Radius.circular(100.0)),
          ),
          child: btnAnim!.value > 75.0
              ? Text(title!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: fontColor ?? colors.whiteTemp,
                      fontWeight: FontWeight.normal,),)
              : CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primarytheme,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(colors.whiteTemp),
                ),
        ),
        onPressed: () {
          if (btnAnim!.value == initialWidth) {
            onBtnSelected!();
          }
        },
      ),
    );
  }
}
