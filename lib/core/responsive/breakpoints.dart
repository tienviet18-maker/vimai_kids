import 'package:flutter/material.dart';

class Breakpoints {
  static bool isPhone(double width) => width < 600;
  static bool isTablet(double width) => width >= 600 && width < 1024;
  static bool isDesktop(double width) => width >= 1024;

  static int gridCount(double width, {int phone = 2, int tablet = 3, int desktop = 4}) {
    if (isDesktop(width)) return desktop;
    if (isTablet(width)) return tablet;
    return phone;
  }

  static double pagePadding(double width) => isPhone(width) ? 16 : 24;

  static double kanaFontSize(BoxConstraints constraints) {
    final shortest = constraints.biggest.shortestSide;
    final height = constraints.maxHeight.isFinite ? constraints.maxHeight : shortest;
    final byWidth = shortest * 0.22;
    final byHeight = height * 0.28;
    final size = byWidth < byHeight ? byWidth : byHeight;
    final cap = height < 420 ? 64.0 : (height < 560 ? 88.0 : 120.0);
    return size.clamp(36.0, cap);
  }
}

class ScrollSafe extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ScrollSafe({super.key, required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}
