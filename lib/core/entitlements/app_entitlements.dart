/// Future store entitlements. Core learning is free and bundled.
///
/// Do not put payment UI here. Do not fake a successful purchase.
enum AppPlan { free, pro }

class AppEntitlements {
  final AppPlan plan;
  const AppEntitlements({this.plan = AppPlan.free});

  bool get isFree => plan == AppPlan.free;
  bool get isPro => plan == AppPlan.pro;

  /// All current curriculum, audio, and games are available offline on Free.
  bool get coreLearningUnlocked => true;
}

/// Purchase adapter for a future store. Implementations must talk to a real store SDK.
abstract class PurchasePort {
  Future<AppPlan> currentPlan();
}

/// Default: no store connected. Always Free. Never reports a fake purchase.
class UnconfiguredPurchasePort implements PurchasePort {
  const UnconfiguredPurchasePort();

  @override
  Future<AppPlan> currentPlan() async => AppPlan.free;
}
