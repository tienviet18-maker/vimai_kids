/// Outside the web: no install flags; the guide is never offered.
String installState() => '';

Future<String> promptInstall() async => 'unavailable';
