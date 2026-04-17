import 'package:flutter/widgets.dart';

import 'app_store.dart';

class AppStoreScope extends InheritedNotifier<AppStore> {
  const AppStoreScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStoreScope>();
    assert(scope != null, 'No AppStoreScope found in context');
    return scope!.notifier!;
  }
}
