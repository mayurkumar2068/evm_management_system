import 'package:flutter/material.dart';

/// The Madhya Pradesh State Election Commission emblem.
///
/// Shared so the splash, onboarding and any future branded surface render the
/// exact same mark. By default the baked-in caption at the bottom of the asset
/// is cropped so only the sun + tricolor emblem shows (the styled title is
/// rendered separately by the caller).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 168, this.cropCaption = true});

  static const String asset = 'assets/images/mp_election_logo.png';

  /// Rendered width of the emblem.
  final double width;

  /// When true, crops the asset's baked-in "म.प्र. राज्य निर्वाचन आयोग" caption.
  final bool cropCaption;

  @override
  Widget build(BuildContext context) {
    final Widget image = Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          asset,
          width: width,
          fit: BoxFit.contain,
        ),
      ),
    );
    if (!cropCaption) {
      return SizedBox(width: width, child: image);
    }
    return SizedBox(
      width: width,
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
