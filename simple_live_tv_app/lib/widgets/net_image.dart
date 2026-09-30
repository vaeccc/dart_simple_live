import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NetImage extends StatelessWidget {
  final String picUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double borderRadius;
  final int? cacheWidth;
  const NetImage(this.picUrl,
      {this.width,
      this.height,
      this.fit = BoxFit.cover,
      this.borderRadius = 0,
      this.cacheWidth,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = picUrl.trim();
    if (normalizedUrl.isEmpty) {
      return Image.asset(
        'assets/images/logo.png',
        width: width,
        height: height,
        fit: fit,
      );
    }
    var pic = normalizedUrl;
    if (pic.startsWith("//")) {
      pic = 'https:$pic';
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ExtendedImage.network(
        pic,
        fit: fit,
        height: height,
        width: width,
        cacheWidth: cacheWidth,
        cache: true,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(borderRadius),
        loadStateChanged: (e) {
          if (e.extendedImageLoadState == LoadState.loading) {
            return const SizedBox();
          }
          if (e.extendedImageLoadState == LoadState.failed) {
            return Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 24.w,
            );
          }
          return null;
        },
      ),
    );
  }
}
