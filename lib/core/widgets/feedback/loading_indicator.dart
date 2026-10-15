import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'animated_loading_logo.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;

  const LoadingIndicator({super.key, this.size = 60});

  /// Below this, the indicator sits inline in a button or a status line --
  /// too small for [AnimatedLoadingLogo]'s glow+logo to read as anything
  /// but a blurry smudge, so those contexts keep the plain platform spinner.
  static const double _prominentThreshold = 40;

  @override
  Widget build(BuildContext context) {
    if (size >= _prominentThreshold) {
      return Center(child: AnimatedLoadingLogo(size: size));
    }

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
