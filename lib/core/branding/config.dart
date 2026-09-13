/// Central product identity. Child-facing UI must read from here only.
class AppBrand {
  static const String productBrand = 'ViMai';
  static const String productDisplayName = 'ViMai Kids';
  static const String productJapaneseName = 'ViMai Kids';
  static const String productTagline = 'Học vui mỗi ngày!';
  static const String version = '1.0.0';
  static const String copyrightOwner = 'ViMai';
  static const String createdByLabel = 'ViMai';
  static const String supportEmail = 'vimai.support@gmail.com';
}

/// Backward-compatible alias used by older imports.
typedef BrandingConfig = AppBrand;
