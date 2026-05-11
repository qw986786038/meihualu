import 'package:flutter/foundation.dart';

import 'package:getx_plus/getx_plus.dart';

/// [GetInterface] is the base class of the [Get] singleton.
/// Extensions on this class add dependency injection and reactive state
/// capabilities — all accessible via the single `Get` object.
class GetInterface {
  SmartManagement smartManagement = SmartManagement.full;
  bool isLogEnable = kDebugMode;
  LogWriterCallback log = defaultLogWriterCallback;
}
