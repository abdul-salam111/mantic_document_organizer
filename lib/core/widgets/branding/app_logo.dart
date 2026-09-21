import 'package:flutter/material.dart';
import 'package:flutter_template/core/constants/app_icons.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final double width;

  const AppLogo({super.key, this.height = 100, this.width = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(AppIcons.logo)),
      ),
    );
  }
}
