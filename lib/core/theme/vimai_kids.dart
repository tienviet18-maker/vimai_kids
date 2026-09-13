/// ViMai Kids design system entry.
///
/// New UI should import this file. Token values live in [vimai_tokens.dart]
/// so existing screens keep compiling; this file names the product systems.
library;

import 'vimai_art.dart';
import 'vimai_tokens.dart';

export 'vimai_art.dart';
export 'vimai_tokens.dart';

/// Color system. Prefer [VimaiKidsColors] in new scene widgets.
typedef VimaiKidsColors = VimaiColor;

/// Type scale for child-facing copy.
typedef VimaiKidsTypography = VimaiType;

/// Spacing scale. No magic numbers in scene layout.
typedef VimaiKidsSpacing = VimaiSpace;

/// Corner language for stickers and chunky controls.
typedef VimaiKidsRadius = VimaiRadius;

/// Depth language. Prefer stacked “chunky” faces over decorative shadows.
typedef VimaiKidsElevation = VimaiShadow;

/// Motion durations. Always go through [VimaiMotion.of] for reduced-motion.
typedef VimaiKidsMotion = VimaiMotion;

/// Illustration catalog.
typedef VimaiKidsIllustration = VimaiArt;

/// Responsive breakpoints for web composition.
typedef VimaiKidsBreakpoints = VimaiBreakpoints;
