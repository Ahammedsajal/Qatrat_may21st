import 'package:flutter/cupertino.dart';

class ContainerClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    final width = size.width / 2;
    final Path path = Path();
    path.moveTo(width - 60, 0);
    path.lineTo(width, 60);
    path.lineTo(width + 60, 0);
    path.lineTo(size.width * 0.97, 0);
    path.quadraticBezierTo(size.width, 0, size.width, size.height * 0.03);
    path.lineTo(size.width, size.height * (0.97));
    path.quadraticBezierTo(
        size.width, size.height, size.width * (0.98), size.height,);
    path.lineTo(size.width * (0.03), size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height * (0.97));
    path.lineTo(0, size.height * (0.03));
    path.quadraticBezierTo(0, 0, size.width * (0.03), 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }
}
