import 'package:flutter/material.dart';

import '../../core/app_store_scope.dart';
import '../../core/constants.dart';
import '../../core/formatting.dart';
import '../../models/account.dart';
import '../../models/order.dart';
import '../common/role_scaffold.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return RoleScaffold(
      title: 'Admin',
      onSignOut: store.signOut,
      destinations: const [
        RoleDestination(label: 'Dashboard', icon: Icons.dashboard_outlined),
        RoleDestination(label: 'Approvals', icon: Icons.verified_user_outlined),
        RoleDestination(label: 'Users', icon: Icons.people_alt_outlined),
        RoleDestination(label: 'Analytics', icon: Icons.query_stats_outlined),
      ],
      pages: const [
        _AdminOverview(),
        _AdminApprovals(),
        _AdminUsers(),
        _AdminAnalytics(),
      ],
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview();

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    final pending = store
        .pendingAccounts()
        .where((a) => a.role != AccountRole.admin)
        .toList();
    final pendingSubmitted = pending
        .where((a) => a.credentialsSubmitted)
        .length;

    final accounts = store.accounts
        .where((a) => a.role != AccountRole.admin)
        .toList();
    final activeAccounts = accounts
        .where((a) => a.status == AccountStatus.approved)
        .length;

    final delivered = store.orders.where((o) => o.status.isDelivered).toList();
    final revenue = delivered
        .map((o) => o.netTotal)
        .fold<double>(0, (a, b) => a + b);
    final commission = store.totalCommissionCollected();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (store.loadError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(store.loadError!),
              ),
            ),
          ),
        const _AdminInvitationCodeCard(),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Metric(
              label: 'Pending approvals',
              value: pending.isEmpty
                  ? '0'
                  : '$pendingSubmitted/${pending.length}',
            ),
            _Metric(label: 'Accounts', value: '${accounts.length}'),
            _Metric(label: 'Active accounts', value: '$activeAccounts'),
            _Metric(label: 'Delivered orders', value: '${delivered.length}'),
            _Metric(label: 'Revenue (net)', value: formatMoney(revenue)),
            _Metric(
              label: 'Commission collected',
              value: formatMoney(commission),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminInvitationCodeCard extends StatefulWidget {
  const _AdminInvitationCodeCard();

  @override
  State<_AdminInvitationCodeCard> createState() => _AdminInvitationCodeCardState();
}

class _AdminInvitationCodeCardState extends State<_AdminInvitationCodeCard> {
  bool _loading = false;
  String? _code;

  Future<void> _generate() async {
    final store = AppStoreScope.of(context);
    setState(() => _loading = true);
    final code = await store.adminGenerateInvitationCode(role: 'admin', length: 8);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _code = code;
    });

    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate invitation code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin invitation code',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Generate a code for a new admin to register.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  onPressed: _loading ? null : _generate,
                  child: Text(_loading ? 'Generating…' : 'Generate code'),
                ),
                if (_code != null)
                  SelectableText(
                    'Code: $_code',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminApprovals extends StatelessWidget {
  const _AdminApprovals();

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final pending = store
        .pendingAccounts()
        .where((a) => a.role != AccountRole.admin)
        .toList();

    pending.sort((a, b) {
      final byCreds =
          (b.credentialsSubmitted ? 1 : 0) - (a.credentialsSubmitted ? 1 : 0);
      if (byCreds != 0) return byCreds;
      return a.displayName.compareTo(b.displayName);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Approvals', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (pending.isEmpty) const Text('No pending accounts.'),
        for (final a in pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    if (a.email.trim().isNotEmpty) Text('Email: ${a.email}'),
                    Text('Role: ${a.role.name}'),
                    Text(
                      'Credentials submitted: ${a.credentialsSubmitted ? 'Yes' : 'No'}',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: () async {
                            await store.approveAccount(a.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Approved ${a.displayName}'),
                              ),
                            );
                          },
                          child: const Text('Approve'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            await store.declineAccount(a.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Declined ${a.displayName}'),
                              ),
                            );
                          },
                          child: const Text('Decline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminUsers extends StatelessWidget {
  const _AdminUsers();

  @override
  Widget build(BuildContext context) {
    return const _AdminUsersBody();
  }
}

enum _AdminUserStatusFilter { all, active, suspended, pending }

enum _AdminUserAction { suspend, unsuspend, setCommission }

class _AdminUsersBody extends StatefulWidget {
  const _AdminUsersBody();

  @override
  State<_AdminUsersBody> createState() => _AdminUsersBodyState();
}

class _AdminUsersBodyState extends State<_AdminUsersBody> {
  final TextEditingController _search = TextEditingController();
  _AdminUserStatusFilter _statusFilter = _AdminUserStatusFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesStatus(Account a) {
    return switch (_statusFilter) {
      _AdminUserStatusFilter.all => true,
      _AdminUserStatusFilter.active => a.status == AccountStatus.approved,
      _AdminUserStatusFilter.suspended => a.status == AccountStatus.suspended,
      _AdminUserStatusFilter.pending => a.status == AccountStatus.pending,
    };
  }

  bool _matchesSearch(Account a) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = '${a.displayName} ${a.username} ${a.email}'.toLowerCase();
    return hay.contains(q);
  }

  Future<void> _setCommission(BuildContext context, Account seller) async {
    final store = AppStoreScope.of(context);
    final controller = TextEditingController(
      text:
          ((seller.commissionRateOverride ??
                      FoodHubConstants.baseCommissionRate) *
                  100)
              .toStringAsFixed(1),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set commission rate'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Commission (%)',
            hintText: 'e.g. 10',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final percent = double.tryParse(controller.text.trim());
              if (percent == null) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(percent);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (result == null) return;
    final clampedPercent = result.clamp(0, 100).toDouble();
    await store.adminSetSellerCommissionRate(
      sellerId: seller.id,
      rate: clampedPercent / 100.0,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Set ${seller.displayName} commission to ${clampedPercent.toStringAsFixed(1)}%.',
        ),
      ),
    );
  }

  Widget _statusChip(_AdminUserStatusFilter f, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _statusFilter == f,
      onSelected: (_) => setState(() => _statusFilter = f),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    final visible = store.accounts
        .where((a) => a.role != AccountRole.admin)
        .where((a) => _matchesStatus(a) && _matchesSearch(a))
        .toList();
    visible.sort((a, b) => a.displayName.compareTo(b.displayName));

    final sellers = visible.where((a) => a.role == AccountRole.seller).toList();
    final riders = visible.where((a) => a.role == AccountRole.rider).toList();
    final buyers = visible.where((a) => a.role == AccountRole.user).toList();

    Widget list(List<Account> accounts, {required String emptyText}) {
      if (accounts.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(emptyText),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: accounts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final a = accounts[index];
          return _AdminUserCard(
            account: a,
            onSuspend: a.status == AccountStatus.approved
                ? () async {
                    await store.adminSetAccountStatus(
                      accountId: a.id,
                      status: AccountStatus.suspended,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Suspended ${a.displayName}.')),
                    );
                  }
                : null,
            onUnsuspend: a.status == AccountStatus.suspended
                ? () async {
                    await store.adminSetAccountStatus(
                      accountId: a.id,
                      status: AccountStatus.approved,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unsuspended ${a.displayName}.')),
                    );
                  }
                : null,
            onSetCommission: a.role == AccountRole.seller
                ? () => _setCommission(context, a)
                : null,
          );
        },
      );
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Users', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name, username, or email',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statusChip(_AdminUserStatusFilter.all, 'All'),
                      const SizedBox(width: 8),
                      _statusChip(_AdminUserStatusFilter.active, 'Active'),
                      const SizedBox(width: 8),
                      _statusChip(_AdminUserStatusFilter.pending, 'Pending'),
                      const SizedBox(width: 8),
                      _statusChip(
                        _AdminUserStatusFilter.suspended,
                        'Suspended',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All (${visible.length})'),
              Tab(text: 'Sellers (${sellers.length})'),
              Tab(text: 'Riders (${riders.length})'),
              Tab(text: 'Buyers (${buyers.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                list(visible, emptyText: 'No users match your filters.'),
                list(sellers, emptyText: 'No sellers match your filters.'),
                list(riders, emptyText: 'No riders match your filters.'),
                list(buyers, emptyText: 'No buyers match your filters.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.account,
    required this.onSuspend,
    required this.onUnsuspend,
    required this.onSetCommission,
  });

  final Account account;
  final VoidCallback? onSuspend;
  final VoidCallback? onUnsuspend;
  final VoidCallback? onSetCommission;

  String get _initials {
    final parts = account.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'FH';
    final a = parts.first.characters.first;
    final b = parts.length > 1 ? parts.last.characters.first : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusText = switch (account.status) {
      AccountStatus.approved => 'ACTIVE',
      AccountStatus.pending => 'PENDING',
      AccountStatus.suspended => 'SUSPENDED',
      AccountStatus.declined => 'DECLINED',
    };
    final statusBg = account.status == AccountStatus.approved
        ? scheme.tertiary.withAlpha(18)
        : (account.status == AccountStatus.suspended
              ? scheme.error.withAlpha(14)
              : scheme.outline.withAlpha(16));
    final statusFg = account.status == AccountStatus.approved
        ? scheme.tertiary
        : (account.status == AccountStatus.suspended
              ? scheme.error
              : scheme.onSurfaceVariant);

    final roleText = switch (account.role) {
      AccountRole.user => 'BUYER',
      AccountRole.seller => 'SELLER',
      AccountRole.rider => 'RIDER',
      AccountRole.admin => 'ADMIN',
    };

    final menuItems = <PopupMenuEntry<_AdminUserAction>>[
      if (onSuspend != null)
        const PopupMenuItem(
          value: _AdminUserAction.suspend,
          child: Text('Suspend account'),
        ),
      if (onUnsuspend != null)
        const PopupMenuItem(
          value: _AdminUserAction.unsuspend,
          child: Text('Unsuspend account'),
        ),
      if (onSetCommission != null)
        const PopupMenuItem(
          value: _AdminUserAction.setCommission,
          child: Text('Set commission'),
        ),
    ];

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.surfaceContainerHighest,
          child: Text(_initials, style: Theme.of(context).textTheme.labelLarge),
        ),
        title: Text(account.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.email.trim().isNotEmpty) Text(account.email),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  text: roleText,
                  bg: scheme.primary.withAlpha(14),
                  fg: scheme.primary,
                ),
                _Pill(text: statusText, bg: statusBg, fg: statusFg),
                if (account.role == AccountRole.seller)
                  _Pill(
                    text:
                        'COMMISSION ${((account.commissionRateOverride ?? FoodHubConstants.baseCommissionRate) * 100).toStringAsFixed(1)}%',
                    bg: scheme.secondary.withAlpha(16),
                    fg: scheme.onSurface,
                  ),
              ],
            ),
          ],
        ),
        trailing: menuItems.isEmpty
            ? null
            : PopupMenuButton<_AdminUserAction>(
                tooltip: 'Actions',
                itemBuilder: (context) => menuItems,
                onSelected: (value) {
                  switch (value) {
                    case _AdminUserAction.suspend:
                      onSuspend?.call();
                      break;
                    case _AdminUserAction.unsuspend:
                      onUnsuspend?.call();
                      break;
                    case _AdminUserAction.setCommission:
                      onSetCommission?.call();
                      break;
                  }
                },
              ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _AdminAnalytics extends StatelessWidget {
  const _AdminAnalytics();

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final delivered = store.orders.where((o) => o.status.isDelivered).toList();
    final deliveredCount = delivered.length;
    final netRevenue = delivered
        .map((o) => o.netTotal)
        .fold<double>(0, (a, b) => a + b);
    final commission = store.totalCommissionCollected();

    final sellers = store.accounts
        .where((a) => a.role == AccountRole.seller && a.isApproved)
        .toList();
    sellers.sort(
      (a, b) => store.sellerRevenue(b.id).compareTo(store.sellerRevenue(a.id)),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Analytics', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Metric(label: 'Delivered orders', value: '$deliveredCount'),
            _Metric(label: 'Revenue (net)', value: formatMoney(netRevenue)),
            _Metric(
              label: 'Commission collected',
              value: formatMoney(commission),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Commission base: ${(FoodHubConstants.baseCommissionRate * 100).toStringAsFixed(0)}%\n'
          'Commission is reduced based on the applied discount percent.',
        ),
        const SizedBox(height: 12),
        Text('Top sellers', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (sellers.isEmpty) const Text('No sellers.'),
        for (final s in sellers)
          ListTile(
            title: Text(s.displayName),
            subtitle: Text(
              'Revenue: ${formatMoney(store.sellerRevenue(s.id))}',
            ),
          ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
