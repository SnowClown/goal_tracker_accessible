import 'package:flutter/foundation.dart';

/// App-wide setting toggling between the two ways of acting on Goals,
/// Tasks, and Steps:
/// - Global controls: action buttons shown at the top of each screen,
///   with checkboxes on each item to select what they act on.
/// - Dynamically displayed controls: the existing per-item "More"
///   button, showing actions for just that one item.
class InterfaceConfig extends ChangeNotifier {
  bool useGlobalControls = true;

  void setUseGlobalControls(bool value) {
    if (useGlobalControls != value) {
      useGlobalControls = value;
      notifyListeners();
    }
  }
}

final InterfaceConfig interfaceConfig = InterfaceConfig();
