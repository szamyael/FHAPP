enum AccountRole {
  user,
  seller,
  rider,
  admin,
}

enum AccountStatus {
  pending,
  approved,
  declined,
  suspended,
}

class Account {
  const Account({
    required this.id,
    required this.displayName,
    required this.username,
    required this.email,
    required this.emailVerified,
    required this.passwordSalt,
    required this.passwordHash,
    required this.role,
    required this.status,
    required this.credentialsSubmitted,
    this.storeCategory,
    this.storeIsOpen,
    this.riderIsOnline,
    this.commissionRateOverride,
  });

  final String id;
  final String displayName;
  final String username;
  final String email;
  final bool emailVerified;
  final String passwordSalt;
  final String passwordHash;
  final AccountRole role;
  final AccountStatus status;
  final bool credentialsSubmitted;

  /// Seller-only metadata sourced from the `accounts.profile` JSON.
  ///
  /// Populated from `profile.store.store_category` when available.
  final String? storeCategory;

  /// Seller-only metadata sourced from the `accounts.profile` JSON.
  ///
  /// Populated from `profile.store.is_open` when available.
  final bool? storeIsOpen;

  /// Rider-only metadata sourced from the `accounts.profile` JSON.
  ///
  /// Populated from `profile.rider.is_online` when available.
  final bool? riderIsOnline;

  /// Seller-only metadata sourced from the `accounts.profile` JSON.
  ///
  /// Optional per-seller override for commission base rate (0.0–1.0), stored at
  /// `profile.commission.rate`.
  final double? commissionRateOverride;

  bool get isApproved => status == AccountStatus.approved;

  Account copyWith({
    String? displayName,
    String? username,
    String? email,
    bool? emailVerified,
    String? passwordSalt,
    String? passwordHash,
    AccountStatus? status,
    bool? credentialsSubmitted,
    String? storeCategory,
    bool? storeIsOpen,
    bool? riderIsOnline,
    double? commissionRateOverride,
  }) {
    return Account(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role,
      status: status ?? this.status,
      credentialsSubmitted: credentialsSubmitted ?? this.credentialsSubmitted,
      storeCategory: storeCategory ?? this.storeCategory,
      storeIsOpen: storeIsOpen ?? this.storeIsOpen,
      riderIsOnline: riderIsOnline ?? this.riderIsOnline,
      commissionRateOverride:
          commissionRateOverride ?? this.commissionRateOverride,
    );
  }
}
