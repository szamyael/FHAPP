import 'package:flutter/material.dart';

import '../models/account.dart';
import 'roles/admin_home.dart';
import 'roles/rider_home.dart';
import 'roles/seller_home.dart';
import 'roles/user_home.dart';

class RoleHome extends StatelessWidget {
  const RoleHome({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return switch (account.role) {
      AccountRole.user => UserHome(account: account),
      AccountRole.seller => SellerHome(account: account),
      AccountRole.rider => RiderHome(account: account),
      AccountRole.admin => AdminHome(account: account),
    };
  }
}
