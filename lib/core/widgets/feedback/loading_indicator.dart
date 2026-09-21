import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;

  const LoadingIndicator({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    // defaultTargetPlatform (not dart:io's Platform) so this is safe to
    // build on web — Platform.isAndroid throws there.
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: isCupertino
            ? CupertinoActivityIndicator(
                radius: size / 2,
                color: Theme.of(context).progressIndicatorTheme.color,
              )
            : CircularProgressIndicator(
                strokeWidth: 4,
                color: Theme.of(context).progressIndicatorTheme.color,
              ),
      ),
    );
  }
}