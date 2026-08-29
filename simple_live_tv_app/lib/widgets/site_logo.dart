import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Displays platform logos without cropping vector assets.
class SiteLogo extends StatelessWidget {
  final String asset;
  final double width;
  final double? height;
  final BoxFit fit;

  const SiteLogo({
    required this.asset,
    required this.width,
    this.height,
    this.fit = BoxFit.contain,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(asset, width: width, height: height, fit: fit);
    }
    return Image.asset(asset, width: width, height: height, fit: fit);
  }
}
