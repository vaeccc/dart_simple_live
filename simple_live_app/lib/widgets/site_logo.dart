import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SiteLogo extends StatelessWidget {
  const SiteLogo({
    required this.assetName,
    required this.width,
    required this.height,
    super.key,
  });

  final String assetName;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (assetName.endsWith('.svg')) {
      return SvgPicture.asset(
        assetName,
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      assetName,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
