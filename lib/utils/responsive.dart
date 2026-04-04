import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  
  Responsive(this.context);
  
  // Screen dimensions
  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;
  
  // Responsive width
  double wp(double percentage) => width * percentage / 100;
  
  // Responsive height
  double hp(double percentage) => height * percentage / 100;
  
  // Responsive font size
  double sp(double size) {
    final baseWidth = 375.0; // iPhone 11 Pro width as base
    return (size * width) / baseWidth;
  }
  
  // Responsive spacing
  double spacing(double size) => wp(size / 2.75);
  
  // Check if tablet
  bool get isTablet => width >= 600;
  
  // Check if desktop
  bool get isDesktop => width >= 1024;
  
  // Responsive padding
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
    horizontal: wp(6),
    vertical: hp(2),
  );
  
  EdgeInsets get cardPadding => EdgeInsets.all(wp(6));
  
  // Responsive border radius
  double get cardRadius => wp(5);
  double get buttonRadius => wp(4);
  
  // Grid columns based on screen size
  int get gridColumns => isTablet ? 3 : 2;
}

// Extension for easy access
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}