import 'dart:math';

import 'package:flutter/widgets.dart';

class Dimension {
  static late double deviceHeight;
  static late double deviceWidth;
  static late bool isTablet;
  static late bool isLargeTablet;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    deviceHeight = size.height;
    deviceWidth = size.width;

    // 600 is a common breakpoint for tablets in Flutter (shortestSide)
    isTablet = size.shortestSide >= 600;
    // 900+ for 10-inch tablets
    isLargeTablet = size.shortestSide >= 900;
  }

  // Use these methods to get responsive height and width
  static double height(double value) {
    // 812 is a common reference height (iPhone X)
    double scale = deviceHeight / 812.0;
    // Limit scaling on tablets to prevent excessively large elements
    if (isTablet) {
      scale = scale.clamp(1.0, 1.4);
    }
    return value * scale;
  }

  static double width(double value) {
    // 375 is a common reference width (iPhone X)
    double scale = deviceWidth / 375.0;
    if (isTablet) {
      scale = scale.clamp(1.0, 1.4);
    }
    return value * scale;
  }

  // Responsive font size based on geometric mean of width and height
  static double font(double value) {
    // 812 and 375 are reference height and width (iPhone X)
    double hScale = deviceHeight / 812.0;
    double wScale = deviceWidth / 375.0;

    if (isTablet) {
      hScale = hScale.clamp(1.0, 1.3);
      wScale = wScale.clamp(1.0, 1.3);
    }

    double scale = sqrt(hScale * wScale);
    return value * scale;
  }
}
