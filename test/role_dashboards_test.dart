import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fhapp/core/app_store.dart';
import 'package:fhapp/core/app_store_scope.dart';
import 'package:fhapp/core/theme.dart';
import 'package:fhapp/models/account.dart';
import 'package:fhapp/ui/role_home.dart';

Account _account(AccountRole role) {
  return Account(
    id: 'acc_${role.name}',
    displayName: role.name.toUpperCase(),
    username: role.name,
    email: '${role.name}@example.com',
    emailVerified: true,
    passwordSalt: '',
    passwordHash: '',
    role: role,
    status: AccountStatus.approved,
    credentialsSubmitted: true,
  );
}

Widget _wrap({required AppStore store, required Account account}) {
  return AppStoreScope(
    notifier: store,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: foodHubLightThemeForRole(account.role),
      darkTheme: foodHubDarkThemeForRole(account.role),
      home: RoleHome(account: account),
    ),
  );
}

void main() {
  testWidgets('Admin dashboard renders content on wide layout', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore();
    await tester.pumpWidget(
      _wrap(store: store, account: _account(AccountRole.admin)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Pending approvals'), findsOneWidget);
  });

  testWidgets('Admin dashboard renders content', (tester) async {
    final store = AppStore();
    await tester.pumpWidget(_wrap(store: store, account: _account(AccountRole.admin)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Pending approvals'), findsOneWidget);
  });

  testWidgets('Seller dashboard renders content', (tester) async {
    final store = AppStore();
    await tester.pumpWidget(_wrap(store: store, account: _account(AccountRole.seller)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("Today's Orders"), findsOneWidget);
  });

  testWidgets('User (buyer) shop renders content', (tester) async {
    final store = AppStore();
    await tester.pumpWidget(_wrap(store: store, account: _account(AccountRole.user)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Near you'), findsOneWidget);
    expect(find.text('No shops available.'), findsOneWidget);
  });

  testWidgets('Rider dashboard renders content (without maps)', (tester) async {
    final previous = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    try {
      final store = AppStore();
      await tester.pumpWidget(
        _wrap(store: store, account: _account(AccountRole.rider)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Online'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = previous;
    }
  });
}
