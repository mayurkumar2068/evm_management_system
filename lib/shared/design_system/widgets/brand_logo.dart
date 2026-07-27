import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.width = 168,
    this.height = 168,
    this.cropCaption = true,
    this.padding = 4,
    this.borderRadius = 30,
    this.backgroundColor = Colors.white,
  });

  static const String asset = 'assets/images/mp_election_logo.png';

  final double width;
  final bool cropCaption;
  final double height;

  // New customizable parameters
  final double padding;
  final double borderRadius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final Widget image = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          asset,
          width: width,
          height: height,
          fit: BoxFit.fitWidth,
        ),
      ),
    );

    if (!cropCaption) {
      return SizedBox(width: width, child: image);
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.96,
          child: image,
        ),
      ),
    );
  }
}