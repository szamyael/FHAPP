import 'package:flutter/material.dart';

import '../../core/app_store_scope.dart';
import '../../core/constants.dart';
import '../../core/formatting.dart';
import '../../models/account.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../chat/chat_screen.dart';
import '../common/order_status_timeline.dart';
import '../common/role_scaffold.dart';
import '../common/star_rating.dart';
import '../common/status_badge.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    return RoleScaffold(
      title: 'Buyer',
      onSignOut: store.signOut,
      destinations: const [
        RoleDestination(label: 'Shop', icon: Icons.storefront),
        RoleDestination(label: 'Orders', icon: Icons.receipt_long),
      ],
      pages: [
        _ShopPage(buyer: account),
        _OrdersPage(buyer: account),
      ],
    );
  }
}

class _ShopPage extends StatelessWidget {
  const _ShopPage({required this.buyer});

  final Account buyer;

  @override
  Widget build(BuildContext context) {
    return _ShopDashboard(buyer: buyer);
  }
}

class _ShopDashboard extends StatefulWidget {
  const _ShopDashboard({required this.buyer});

  final Account buyer;

  @override
  State<_ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<_ShopDashboard> {
  final TextEditingController _search = TextEditingController();

  String? _selectedCategory;
  String? _selectedShopId;

  bool _showAllShops = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    final sellers =
        store.accounts
            .where((a) => a.role == AccountRole.seller && a.isApproved)
            .toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

    final categories =
        sellers
            .map((s) => s.storeCategory)
            .whereType<String>()
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final selectedCategory =
        (_selectedCategory != null && categories.contains(_selectedCategory))
        ? _selectedCategory
        : null;

    final visibleSellers = selectedCategory == null
        ? sellers
        : sellers.where((s) => s.storeCategory == selectedCategory).toList();

    final selectedShopId = selectedCategory == null
        ? null
        : (_selectedShopId != null &&
              visibleSellers.any((s) => s.id == _selectedShopId))
        ? _selectedShopId
        : null;

    if (selectedCategory != _selectedCategory ||
        selectedShopId != _selectedShopId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (selectedCategory == _selectedCategory &&
            selectedShopId == _selectedShopId) {
          return;
        }
        setState(() {
          _selectedCategory = selectedCategory;
          _selectedShopId = selectedShopId;
        });
      });
    }

    final categorySellerIds = selectedCategory == null
        ? null
        : visibleSellers.map((s) => s.id).toSet();

    final q = _search.text.trim().toLowerCase();
    final filteredProducts = store.products.where((p) {
      if (_selectedShopId != null && p.sellerId != _selectedShopId) {
        return false;
      }
      if (_selectedShopId == null && categorySellerIds != null) {
        if (!categorySellerIds.contains(p.sellerId)) return false;
      }
      if (q.isNotEmpty) {
        final sellerName = store.accountById(p.sellerId)?.displayName ?? '';
        final hay = '${p.name} ${p.description} $sellerName'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    final topPicks =
        store.products.where((p) {
          if (p.stock <= 0) return false;
          if (p.expiryDate.isBefore(DateTime.now())) return false;
          if (_selectedShopId != null && p.sellerId != _selectedShopId) {
            return false;
          }
          if (_selectedShopId == null && categorySellerIds != null) {
            if (!categorySellerIds.contains(p.sellerId)) return false;
          }
          return true;
        }).toList()..sort((a, b) {
          final byDiscount = b.discountPercent.compareTo(a.discountPercent);
          if (byDiscount != 0) return byDiscount;
          return a.discountedPrice.compareTo(b.discountedPrice);
        });

    final visibleShopCards = _showAllShops
        ? visibleSellers
        : visibleSellers.take(6).toList();

    final hasFilters =
        _selectedCategory != null || _selectedShopId != null || q.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _BuyerHero(
              buyerName: widget.buyer.displayName,
              searchController: _search,
              onChanged: () => setState(() {}),
              onSubmit: () => FocusScope.of(context).unfocus(),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Categories',
                  trailing: hasFilters
                      ? TextButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {
                              _selectedCategory = null;
                              _selectedShopId = null;
                            });
                          },
                          child: const Text('Clear'),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                if (categories.isEmpty)
                  const Text('No categories available.')
                else
                  SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryTile(
                          label: 'All',
                          icon: Icons.restaurant_menu_rounded,
                          selected: _selectedCategory == null,
                          onTap: () {
                            setState(() {
                              _selectedCategory = null;
                              _selectedShopId = null;
                            });
                          },
                        ),
                        for (final c in categories)
                          _CategoryTile(
                            label: c,
                            icon: _categoryIcon(c),
                            selected: _selectedCategory == c,
                            onTap: () {
                              setState(() {
                                _selectedCategory = c;
                                _selectedShopId = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Near you',
              trailing: visibleSellers.length <= 6
                  ? null
                  : TextButton(
                      onPressed: () =>
                          setState(() => _showAllShops = !_showAllShops),
                      child: Text(_showAllShops ? 'Show less' : 'See all'),
                    ),
            ),
          ),
        ),

        if (visibleSellers.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverToBoxAdapter(child: Text('No shops available.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 420,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.0,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final seller = index == 0 ? null : visibleShopCards[index - 1];
                if (seller == null) {
                  return _SellerCard(
                    title: 'All shops',
                    subtitle: _selectedCategory ?? 'Browse everything',
                    icon: Icons.storefront_rounded,
                    selected: _selectedShopId == null,
                    trailing: null,
                    onTap: () => setState(() => _selectedShopId = null),
                  );
                }
                final status = seller.storeIsOpen == true
                    ? _Pill(
                        text: 'OPEN',
                        bg: scheme.tertiary.withAlpha(22),
                        fg: scheme.tertiary,
                      )
                    : _Pill(
                        text: 'CLOSED',
                        bg: scheme.outline.withAlpha(16),
                        fg: scheme.onSurfaceVariant,
                      );
                return _SellerCard(
                  title: seller.displayName,
                  subtitle: seller.storeCategory ?? 'Shop',
                  icon: Icons.store_rounded,
                  selected: _selectedShopId == seller.id,
                  trailing: status,
                  onTap: () => setState(() => _selectedShopId = seller.id),
                );
              }, childCount: visibleShopCards.length + 1),
            ),
          ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Top picks this week',
              subtitle: 'Popular items with great discounts',
            ),
          ),
        ),
        if (topPicks.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverToBoxAdapter(child: Text('No top picks yet.')),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: 174,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 320,
                    child: _TopPickCard(
                      product: topPicks[index],
                      buyer: widget.buyer,
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemCount: topPicks.take(10).length,
              ),
            ),
          ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Products',
              subtitle: hasFilters
                  ? 'Showing results for your filters'
                  : 'Browse everything available today',
            ),
          ),
        ),

        if (filteredProducts.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: const SliverToBoxAdapter(
              child: _EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matches found',
                subtitle:
                    'Try clearing filters or searching for something else.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 420,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.22,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final p = filteredProducts[index];
                return _ProductTile(product: p, buyer: widget.buyer);
              }, childCount: filteredProducts.length),
            ),
          ),
      ],
    );
  }
}

IconData _categoryIcon(String category) {
  final c = category.trim().toLowerCase();
  if (c.contains('burger')) return Icons.lunch_dining_rounded;
  if (c.contains('pizza')) return Icons.local_pizza_rounded;
  if (c.contains('sushi')) return Icons.ramen_dining_rounded;
  if (c.contains('chicken')) return Icons.fastfood_rounded;
  if (c.contains('salad')) return Icons.eco_rounded;
  if (c.contains('pasta')) return Icons.dinner_dining_rounded;
  if (c.contains('dessert')) return Icons.icecream_rounded;
  if (c.contains('drink')) return Icons.local_cafe_rounded;
  return Icons.restaurant_menu_rounded;
}

class _BuyerHero extends StatelessWidget {
  const _BuyerHero({
    required this.buyerName,
    required this.searchController,
    required this.onChanged,
    required this.onSubmit,
  });

  final String buyerName;
  final TextEditingController searchController;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 260),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FoodHubConstants.brandPrimary,
              FoodHubConstants.brandSecondary,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.10,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.ramen_dining_rounded,
                    size: 240,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: DefaultTextStyle(
                style:
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white) ??
                    const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pill(
                      text: 'DELIVERING ACROSS YOUR CITY',
                      bg: Colors.white.withAlpha(22),
                      fg: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Good food,\ndelivered fast.',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      buyerName.trim().isEmpty
                          ? 'Order from local restaurants and sellers near you.'
                          : 'Hi $buyerName — order from local sellers near you.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withAlpha(230),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _HeroSearchBar(
                      controller: searchController,
                      onChanged: onChanged,
                      onSubmit: onSubmit,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _TrustBadge(
                          icon: Icons.timer_outlined,
                          text: 'Fast delivery',
                        ),
                        _TrustBadge(
                          icon: Icons.storefront_outlined,
                          text: 'Local shops',
                        ),
                        _TrustBadge(
                          icon: Icons.track_changes_outlined,
                          text: 'Live updates',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSearchBar extends StatelessWidget {
  const _HeroSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withAlpha(220)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              'City',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 28,
              color: scheme.outline.withAlpha(90),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  hintText: 'Search food or shops',
                  border: InputBorder.none,
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              child: const Icon(Icons.search_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = selected ? scheme.primary : scheme.outline.withAlpha(80);
    final bg = selected ? scheme.primary.withAlpha(16) : scheme.surface;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHighest,
                ),
                child: Icon(icon, color: scheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = selected ? scheme.primary : scheme.outline.withAlpha(80);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHighest,
                ),
                child: Icon(
                  icon,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopPickCard extends StatelessWidget {
  const _TopPickCard({required this.product, required this.buyer});

  final Product product;
  final Account buyer;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final seller = store.accountById(product.sellerId);

    final isExpired = product.expiryDate.isBefore(DateTime.now());
    final canBuy = product.stock > 0 && !isExpired;
    final sellerName = seller?.displayName ?? product.sellerId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withAlpha(16),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (product.discountPercent > 0)
                  _Pill(
                    text: '-${product.discountPercent.toStringAsFixed(0)}%',
                    bg: scheme.primary.withAlpha(18),
                    fg: scheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatMoney(product.discountedPrice),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton(
                  onPressed: canBuy
                      ? () async {
                          final order = await store.placeOrder(
                            buyerId: buyer.id,
                            productId: product.id,
                          );
                          if (!context.mounted) return;
                          final text = order == null
                              ? 'Could not place order.'
                              : 'Order placed (${order.id}). Awaiting seller confirmation.';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(text)));
                        }
                      : null,
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
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
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest,
              ),
              child: Icon(icon, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.buyer});

  final Product product;
  final Account buyer;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final seller = store.accountById(product.sellerId);

    final isExpired = product.expiryDate.isBefore(DateTime.now());
    final canBuy = product.stock > 0 && !isExpired;

    final ratedOrders = store.orders.where(
      (o) => o.productId == product.id && o.ratingStars != null,
    );
    final ratings = ratedOrders.map((o) => o.ratingStars!).toList();
    final avgRating = ratings.isEmpty
        ? null
        : ratings.reduce((a, b) => a + b) / ratings.length;

    final sellerName = seller?.displayName ?? product.sellerId;
    final ctaLabel = isExpired
        ? 'Expired'
        : (product.stock <= 0 ? 'Out of stock' : 'Buy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              sellerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            _PriceLine(product: product),
            const SizedBox(height: 8),
            Text(
              'Stock: ${product.stock} • Expiry: ${formatDate(product.expiryDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (avgRating != null) ...[
              const SizedBox(height: 4),
              Text(
                'Rating: ${avgRating.toStringAsFixed(1)} / 5',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canBuy
                    ? () async {
                        final order = await store.placeOrder(
                          buyerId: buyer.id,
                          productId: product.id,
                        );
                        if (!context.mounted) return;
                        final text = order == null
                            ? 'Could not place order.'
                            : 'Order placed (${order.id}). Awaiting seller confirmation.';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(text)));
                      }
                    : null,
                child: Text(ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPercent > 0;
    final base = formatMoney(product.price);
    final discounted = formatMoney(product.discountedPrice);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price: $base'),
        if (hasDiscount)
          Text(
            'Discount: ${product.discountPercent.toStringAsFixed(0)}%  →  $discounted',
          ),
      ],
    );
  }
}

class _OrdersPage extends StatelessWidget {
  const _OrdersPage({required this.buyer});

  final Account buyer;

  @override
  Widget build(BuildContext context) {
    return _BuyerOrders(buyer: buyer);
  }
}

enum _OrderFilter { all, active, completed, cancelled }

class _BuyerOrders extends StatefulWidget {
  const _BuyerOrders({required this.buyer});

  final Account buyer;

  @override
  State<_BuyerOrders> createState() => _BuyerOrdersState();
}

class _BuyerOrdersState extends State<_BuyerOrders> {
  _OrderFilter _filter = _OrderFilter.all;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final all = store.orders
        .where((o) => o.buyerId == widget.buyer.id)
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    bool isActive(Order o) => !o.status.isDelivered && !o.status.isDeclined;

    final visible = switch (_filter) {
      _OrderFilter.all => all,
      _OrderFilter.active => all.where(isActive).toList(),
      _OrderFilter.completed => all.where((o) => o.status.isDelivered).toList(),
      _OrderFilter.cancelled => all.where((o) => o.status.isDeclined).toList(),
    };

    Widget chip(_OrderFilter f, String label) {
      final selected = _filter == f;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = f),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('My Orders', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip(_OrderFilter.all, 'All'),
              const SizedBox(width: 8),
              chip(_OrderFilter.active, 'Active'),
              const SizedBox(width: 8),
              chip(_OrderFilter.completed, 'Completed'),
              const SizedBox(width: 8),
              chip(_OrderFilter.cancelled, 'Cancelled'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No orders here yet',
            subtitle: 'Place an order from the Shop tab to see it here.',
          )
        else
          for (final o in visible) _OrderCard(order: o),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final product = store.productById(order.productId);
    final seller = store.accountById(order.sellerId);
    final rider = order.riderId == null
        ? null
        : store.accountById(order.riderId!);

    final date = formatDate(order.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product?.name ?? 'Order ${order.id}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Seller: ${seller?.displayName ?? order.sellerId}  •  $date'),
            if (rider != null) Text('Rider: ${rider.displayName}'),
            Text('Total: ${formatMoney(order.netTotal)}'),
            const SizedBox(height: 12),
            OrderStatusTimeline(status: order.status),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          threadId: order.id,
                          title: 'Order chat (${order.id})',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message'),
                ),
                if (order.status.isDelivered && product != null)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final reorder = await store.placeOrder(
                        buyerId: order.buyerId,
                        productId: order.productId,
                        quantity: order.quantity,
                      );
                      if (!context.mounted) return;
                      final text = reorder == null
                          ? 'Could not reorder.'
                          : 'Reorder placed (${reorder.id}).';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(text)));
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Reorder'),
                  ),
                if (order.status.isDelivered)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Rate:'),
                      const SizedBox(width: 8),
                      StarRating(
                        value: order.ratingStars ?? 0,
                        onChanged: order.ratingStars == null
                            ? (stars) => store.buyerRateOrder(
                                orderId: order.id,
                                stars: stars,
                              )
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
