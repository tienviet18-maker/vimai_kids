/// The browser's user agent on the web, '' everywhere else.
library;

export 'browser_user_agent_stub.dart'
    if (dart.library.js_interop) 'browser_user_agent_web.dart';
