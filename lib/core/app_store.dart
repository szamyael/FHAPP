import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'auth_utils.dart';
import '../models/account.dart';
import '../models/chat_message.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'config.dart';
import 'constants.dart';
import 'discounts.dart';
import 'supabase_bootstrap.dart';

class AppStore extends ChangeNotifier {
  AppStore() {
    final client = _client;
    if (client == null) {
      final initErr = FoodHubSupabase.initError;
      if (!FoodHubConfig.hasSupabase) {
        _loadError =
            'Supabase is not configured for this build. Provide SUPABASE_URL and SUPABASE_ANON_KEY (or SUPABASE_PUBLISHABLE_KEY).';
      } else if (initErr != null) {
        _loadError = initErr.toString();
      } else {
        _loadError = 'Supabase is not initialized.';
      }
      return;
    }

    _isLoading = true;
    unawaited(_loadFromSupabase(client));
    _authSub = client.auth.onAuthStateChange.listen((data) {
      unawaited(_handleAuthChange(client, data.event, data.session));
    });
  }

  final Uuid _uuid = const Uuid();

  bool _isLoading = false;
  String? _loadError;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get isUsingSupabase => _client != null;

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  SupabaseClient? get _client => FoodHubSupabase.clientOrNull;

  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;

  bool _isInPasswordRecoveryFlow = false;
  bool get isInPasswordRecoveryFlow => _isInPasswordRecoveryFlow;

  Account? _currentAccount;
  Account? get currentAccount => _currentAccount;

  final List<Account> _accounts = [];
  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<ChatMessage> _messages = [];

  static const Duration _emailCodeResendCooldown = Duration(minutes: 1);
  final Map<String, _EmailCodeState> _emailCodesByEmail = {};

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Product> get products => List.unmodifiable(_products);
  List<Order> get orders => List.unmodifiable(_orders);
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  String _nextId(String prefix) {
    return '${prefix}_${_uuid.v4()}';
  }

  @override
  void dispose() {
    unawaited(_channel?.unsubscribe());
    unawaited(_authSub?.cancel());
    super.dispose();
  }

  Account? accountById(String accountId) {
    for (final a in _accounts) {
      if (a.id == accountId) return a;
    }
    return null;
  }

  Product? productById(String productId) {
    for (final p in _products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  Order? orderById(String orderId) {
    for (final o in _orders) {
      if (o.id == orderId) return o;
    }
    return null;
  }

  List<Account> approvedAccountsForRole(AccountRole role) {
    return _accounts.where((a) => a.role == role && a.isApproved).toList();
  }

  List<Account> pendingAccounts() {
    return _accounts.where((a) => a.status == AccountStatus.pending).toList();
  }

  void signIn(String accountId) {
    final account = accountById(accountId);
    if (account == null) return;
    if (!account.isApproved) return;
    _currentAccount = account;
    notifyListeners();
  }

  Account? accountByUsernameOrEmail(String identifier) {
    final id = identifier.trim().toLowerCase();
    if (id.isEmpty) return null;

    for (final a in _accounts) {
      if (a.username.trim().toLowerCase() == id) return a;
      if (a.email.trim().toLowerCase() == id) return a;
    }
    return null;
  }

  bool isUsernameAvailable(String username, {String? ignoreAccountId}) {
    final u = username.trim().toLowerCase();
    if (u.isEmpty) return false;

    for (final a in _accounts) {
      if (ignoreAccountId != null && a.id == ignoreAccountId) continue;
      if (a.username.trim().toLowerCase() == u) return false;
    }
    return true;
  }

  ({bool sent, String? code, Duration? retryAfter}) sendEmailVerificationCode(
    String email,
  ) {
    final key = email.trim().toLowerCase();
    if (key.isEmpty) return (sent: false, code: null, retryAfter: null);

    final existing = _emailCodesByEmail[key];
    if (existing != null) {
      final elapsed = DateTime.now().difference(existing.sentAt);
      final remaining = _emailCodeResendCooldown - elapsed;
      if (remaining > Duration.zero) {
        return (sent: false, code: null, retryAfter: remaining);
      }
    }

    final code = generateNumericCode(length: 6);
    _emailCodesByEmail[key] = _EmailCodeState(
      code: code,
      sentAt: DateTime.now(),
    );
    return (sent: true, code: code, retryAfter: null);
  }

  bool verifyEmailCode({required String email, required String code}) {
    final key = email.trim().toLowerCase();
    final state = _emailCodesByEmail[key];
    if (state == null) return false;

    final trimmed = code.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed != state.code) return false;
    return true;
  }

  Future<String?> signInWithCredentials({
    required String identifier,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return 'Supabase is not configured.';
    }

    final trimmedId = identifier.trim();
    if (trimmedId.isEmpty) return 'Enter your email or username.';
    if (password.trim().isEmpty) return 'Enter your password.';

    String email;
    if (trimmedId.contains('@')) {
      email = trimmedId;
    } else {
      final account = accountByUsernameOrEmail(trimmedId);
      if (account == null) return 'Account not found.';
      if (account.email.trim().isEmpty) {
        return 'This username has no email. Please sign in using email.';
      }
      email = account.email.trim();
    }

    _isLoading = true;
    notifyListeners();

    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        return 'Unable to sign in.';
      }

      final account = await _fetchAccountById(client, user.id);
      if (account == null) {
        await client.auth.signOut();
        return 'Account record not found in database. Please register first.';
      }

      if (!account.isApproved) {
        await client.auth.signOut();
        return 'Account is pending approval.';
      }

      _currentAccount = account;
      _loadError = null;
      return null;
    } catch (e) {
      return _friendlySupabaseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithOAuth({required OAuthProvider provider}) async {
    final client = _client;
    if (client == null) {
      return 'Supabase is not configured.';
    }

    _isLoading = true;
    notifyListeners();

    try {
      await client.auth.signInWithOAuth(provider);
      _loadError = null;
      return null;
    } catch (e) {
      return _friendlySupabaseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> registerAccount({
    required AccountRole role,
    required String displayName,
    required String username,
    required String email,
    required String password,
    required bool credentialsSubmitted,
    required Map<String, dynamic> profile,
  }) async {
    final u = username.trim();
    final e = email.trim();
    if (!isUsernameAvailable(u)) return 'Username is already taken.';
    if (e.isEmpty || !e.contains('@')) return 'Please enter a valid email.';
    if (accountByUsernameOrEmail(e) != null) {
      return 'Email is already registered. Try signing in instead.';
    }

    final client = _client;
    if (client == null) {
      return 'Supabase is required to register.';
    }

    try {
      final authRes = await client.auth.signUp(
        email: e,
        password: password,
        data: {
          'display_name': displayName.trim().isEmpty ? u : displayName.trim(),
          'role': role.name,
          'credentials_submitted': credentialsSubmitted,
          'username': u,
          'profile': profile,
        },
      );

      final user = authRes.user;
      if (user == null) return 'Unable to create auth user.';

      // If the project does not require email confirmation, signUp may create a session.
      // We sign out after registration because the account is pending approval.
      if (authRes.session != null) {
        await client.auth.signOut();
      }
    } catch (e) {
      final friendly = _friendlySupabaseError(e);
      return friendly;
    }

    return null;
  }

  /// Starts a Supabase Auth signup to trigger email OTP delivery.
  ///
  /// Returns whether an email OTP is required (i.e., signup did not return an
  /// immediate session).
  Future<({String? error, bool requiresEmailOtp})>
  beginSignupForEmailVerification({
    required String displayName,
    required String username,
    required String email,
    required String password,
    required Map<String, dynamic> profileDraft,
  }) async {
    final u = username.trim();
    final e = email.trim();
    if (!isUsernameAvailable(u)) {
      return (error: 'Username is already taken.', requiresEmailOtp: false);
    }
    if (e.isEmpty || !e.contains('@')) {
      return (error: 'Please enter a valid email.', requiresEmailOtp: false);
    }
    if (accountByUsernameOrEmail(e) != null) {
      return (
        error: 'Email is already registered. Try signing in instead.',
        requiresEmailOtp: false,
      );
    }

    final client = _client;
    if (client == null) {
      return (
        error: 'Supabase is required to register.',
        requiresEmailOtp: false,
      );
    }

    try {
      final authRes = await client.auth.signUp(
        email: e,
        password: password,
        data: {
          'display_name': displayName.trim().isEmpty ? u : displayName.trim(),
          'username': u,
          'profile': profileDraft,
        },
      );

      final user = authRes.user;
      if (user == null) {
        return (error: 'Unable to create auth user.', requiresEmailOtp: false);
      }

      // If email confirmation is disabled, a session may already exist.
      final requiresOtp = authRes.session == null;
      return (error: null, requiresEmailOtp: requiresOtp);
    } catch (e) {
      return (error: _friendlySupabaseError(e), requiresEmailOtp: false);
    }
  }

  Future<String?> sendPasswordResetEmail({required String email}) async {
    final client = _client;
    if (client == null) return 'Supabase is not configured.';
    final e = email.trim();
    if (e.isEmpty || !e.contains('@')) return 'Please enter a valid email.';

    try {
      await client.auth.resetPasswordForEmail(e);
      return null;
    } catch (err) {
      return _friendlySupabaseError(err);
    }
  }

  /// Verifies a Supabase password recovery code (OTP) and starts the in-app
  /// password recovery flow.
  ///
  /// This is useful if you want users to paste a code from the recovery email
  /// instead of opening the reset link.
  Future<String?> verifyPasswordRecoveryCode({
    required String email,
    required String code,
  }) async {
    final client = _client;
    if (client == null) return 'Supabase is not configured.';
    final e = email.trim();
    if (e.isEmpty || !e.contains('@')) return 'Please enter a valid email.';
    final c = code.trim();
    if (c.isEmpty) return 'Enter the verification code.';

    try {
      await client.auth.verifyOTP(type: OtpType.recovery, email: e, token: c);

      // verifyOTP(recovery) should also emit AuthChangeEvent.passwordRecovery,
      // but we set the flag proactively so the UI can switch immediately.
      _isInPasswordRecoveryFlow = true;
      notifyListeners();
      return null;
    } catch (err) {
      return _friendlySupabaseError(err);
    }
  }

  /// Verifies a Supabase email confirmation code (OTP) for a signup.
  ///
  /// Note: Supabase must be configured to send OTP codes (not confirmation links)
  /// in the email template for this to work.
  Future<String?> verifySignupEmailOtp({
    required String email,
    required String code,
    bool signOutAfter = true,
  }) async {
    final client = _client;
    if (client == null) return 'Supabase is not configured.';
    final e = email.trim();
    if (e.isEmpty || !e.contains('@')) return 'Please enter a valid email.';
    final c = code.trim();
    if (c.isEmpty) return 'Enter the verification code.';

    try {
      await client.auth.verifyOTP(type: OtpType.signup, email: e, token: c);

      // The user may be signed in after verification; we keep them signed out
      // since registration is still pending admin approval.
      if (signOutAfter) {
        await client.auth.signOut();
      }
      return null;
    } catch (err) {
      return _friendlySupabaseError(err);
    }
  }

  /// Finalizes a registration after email verification by updating the pending
  /// `public.accounts` row for the currently authenticated user.
  ///
  /// This is implemented server-side as an RPC to avoid RLS blocking updates.
  Future<String?> finalizeRegistration({
    required AccountRole role,
    required String displayName,
    required bool credentialsSubmitted,
    required Map<String, dynamic> profile,
    String? adminInvitationCode,
  }) async {
    final client = _client;
    if (client == null) return 'Supabase is not configured.';
    if (client.auth.currentUser == null) {
      return 'Please verify your email first.';
    }

    try {
      await client.rpc(
        'finalize_registration',
        params: {
          'p_role': role.name,
          'p_display_name': displayName.trim(),
          'p_credentials_submitted': credentialsSubmitted,
          'p_profile': profile,
          'p_admin_invitation_code': adminInvitationCode?.trim(),
        },
      );
      return null;
    } catch (e) {
      return _friendlySupabaseError(e);
    }
  }

  /// Generates a new invitation code (admin-only).
  ///
  /// Returns the generated code, or null if an error occurred (error details
  /// are stored in `loadError`).
  Future<String?> adminGenerateInvitationCode({
    required String role,
    required int length,
  }) async {
    final client = _client;
    if (client == null) return null;

    final user = client.auth.currentUser;
    if (user == null) {
      _loadError =
          'Please sign in as an approved admin to generate invitation codes.';
      notifyListeners();
      return null;
    }

    Future<String?> tryClientSideFallbackInsert() async {
      final normalizedRole = role.trim().isEmpty ? 'admin' : role.trim();
      if (normalizedRole != 'admin' || length != 8) return null;

      // Fallback: generate a code client-side and insert into `invitation_codes`.
      // Requires the `invitation_codes_insert_admin` RLS policy in schema.sql.
      for (var tries = 0; tries < 6; tries++) {
        final code = _uuid
            .v4()
            .replaceAll('-', '')
            .substring(0, 8)
            .toUpperCase();
        try {
          await client.from('invitation_codes').insert({
            'role': normalizedRole,
            'code': code,
            'created_by': user.id,
          });
          return code;
        } catch (e) {
          final friendly = _friendlySupabaseError(e);
          final lower = friendly.toLowerCase();

          // Unique collisions are extremely unlikely, but we retry a few times.
          if (lower.contains('duplicate') || lower.contains('unique')) {
            continue;
          }

          _loadError = friendly;
          notifyListeners();
          return null;
        }
      }

      _loadError = 'Unable to generate a unique invitation code.';
      notifyListeners();
      return null;
    }

    try {
      final res = await client.rpc(
        'admin_generate_invitation_code',
        params: {'p_role': role, 'p_length': length},
      );
      if (res is String && res.trim().isNotEmpty) return res.trim();
      return null;
    } catch (e) {
      final friendly = _friendlySupabaseError(e);
      _loadError = friendly;
      notifyListeners();

      // If the RPC endpoint isn't available (schema cache miss, missing grant,
      // etc.), attempt a safe client-side fallback insert.
      if (e is PostgrestException) {
        final msg = e.message.toLowerCase();
        final details = (e.details ?? '').toString().toLowerCase();
        final looksLikeMissingRpc =
            e.code == 'PGRST202' ||
            e.code == '404' ||
            msg.contains('not found') ||
            details.contains('not found') ||
            msg.contains('schema cache') ||
            details.contains('schema cache') ||
            msg.contains('could not find the function') ||
            details.contains('could not find the function');

        final looksLikeRlsBlocked =
            msg.contains('row-level security') ||
            details.contains('row-level security') ||
            e.code == '42501';

        if (looksLikeMissingRpc || looksLikeRlsBlocked) {
          final code = await tryClientSideFallbackInsert();
          if (code != null) {
            _loadError = null;
            notifyListeners();
          }
          return code;
        }
      } else if (friendly.toLowerCase().contains('rpc is missing') ||
          friendly.toLowerCase().contains('not found') ||
          friendly.toLowerCase().contains('row-level security')) {
        final code = await tryClientSideFallbackInsert();
        if (code != null) {
          _loadError = null;
          notifyListeners();
        }
        return code;
      }

      return null;
    }
  }

  /// Resends the Supabase signup confirmation email.
  ///
  /// If your email template uses `{{ .Token }}`, Supabase will send an OTP code.
  /// If it uses `{{ .ConfirmationURL }}`, Supabase will send a confirmation link.
  Future<String?> resendSignupEmailOtp({required String email}) async {
    final client = _client;
    if (client == null) return 'Supabase is not configured.';
    final e = email.trim();
    if (e.isEmpty || !e.contains('@')) return 'Please enter a valid email.';

    try {
      await client.auth.resend(type: OtpType.signup, email: e);
      return null;
    } catch (err) {
      return _friendlySupabaseError(err);
    }
  }

  Future<String?> updatePasswordFromRecovery({
    required String newPassword,
  }) async {
    final client = _client;
    if (client == null) return 'Supabase is not configured.';
    final p = newPassword.trim();
    if (p.length < 8) return 'Password must be at least 8 characters.';

    try {
      await client.auth.updateUser(UserAttributes(password: p));
      await client.auth.signOut();
      _isInPasswordRecoveryFlow = false;
      notifyListeners();
      return null;
    } catch (err) {
      return _friendlySupabaseError(err);
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final account = accountByUsernameOrEmail(email);
    if (account == null) return 'Account not found.';

    final salt = generateSalt();
    final hash = hashPassword(password: newPassword, salt: salt);

    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx < 0) return 'Account not found.';

    final client = _client;
    if (client == null) {
      return 'Supabase is required to reset password.';
    }

    try {
      await client
          .from('accounts')
          .update({'password_salt': salt, 'password_hash': hash})
          .eq('id', account.id);

      _accounts[idx] = _accounts[idx].copyWith(
        passwordSalt: salt,
        passwordHash: hash,
      );
      notifyListeners();
    } catch (e) {
      final friendly = _friendlySupabaseError(e);
      return friendly;
    }

    return null;
  }

  Future<void> signOut() async {
    _currentAccount = null;
    _isInPasswordRecoveryFlow = false;
    _orders.clear();
    _messages.clear();
    unawaited(_channel?.unsubscribe());
    _channel = null;
    notifyListeners();
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
  }

  Future<void> approveAccount(String accountId) async {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx < 0) return;
    final client = _client;
    if (client == null) return;

    await client
        .from('accounts')
        .update({'status': 'approved'})
        .eq('id', accountId);
    _accounts[idx] = _accounts[idx].copyWith(status: AccountStatus.approved);
    notifyListeners();
  }

  Future<void> adminSetAccountStatus({
    required String accountId,
    required AccountStatus status,
  }) async {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx < 0) return;
    final client = _client;
    if (client == null) return;

    try {
      await client
          .from('accounts')
          .update({'status': status.name})
          .eq('id', accountId);
      _accounts[idx] = _accounts[idx].copyWith(status: status);
      notifyListeners();
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  Future<void> declineAccount(String accountId) async {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx < 0) return;
    final client = _client;
    if (client == null) return;

    await client
        .from('accounts')
        .update({'status': 'declined'})
        .eq('id', accountId);
    _accounts[idx] = _accounts[idx].copyWith(status: AccountStatus.declined);
    notifyListeners();
  }

  Future<void> adminSetSellerCommissionRate({
    required String sellerId,
    required double rate,
  }) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.rpc(
        'admin_set_seller_commission_rate',
        params: {'p_seller_id': sellerId, 'p_rate': rate},
      );
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  DiscountSuggestion? suggestionForProduct(Product product, {DateTime? now}) {
    return suggestDiscount(
      expiryDate: product.expiryDate,
      now: now ?? DateTime.now(),
    );
  }

  double? recommendedDiscountPercentForSuggestion(
    DiscountSuggestion suggestion,
  ) {
    if (suggestion.fixedPercent != null) return suggestion.fixedPercent;
    if (suggestion.isRange) return suggestion.minPercent;
    return null;
  }

  List<
    ({
      Product product,
      DiscountSuggestion suggestion,
      double recommendedPercent,
    })
  >
  expiryDiscountAlertsForSeller(String sellerId, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final alerts =
        <
          ({
            Product product,
            DiscountSuggestion suggestion,
            double recommendedPercent,
          })
        >[];

    for (final product in _products) {
      if (product.sellerId != sellerId) continue;
      if (product.stock <= 0) continue;
      if (!product.expiryDate.isAfter(at)) continue;

      final suggestion = suggestDiscount(
        expiryDate: product.expiryDate,
        now: at,
      );
      if (suggestion == null) continue;

      final recommended = recommendedDiscountPercentForSuggestion(suggestion);
      if (recommended == null) continue;

      // Only alert if the current discount is below the minimum suggested discount.
      if (product.discountPercent + 0.0001 >= recommended) continue;

      alerts.add((
        product: product,
        suggestion: suggestion,
        recommendedPercent: recommended,
      ));
    }

    alerts.sort(
      (a, b) => a.suggestion.daysToExpiry.compareTo(b.suggestion.daysToExpiry),
    );
    return alerts;
  }

  Future<bool> updateProductDiscount(
    String productId,
    double discountPercent,
  ) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx < 0) return false;

    final client = _client;
    if (client == null) return false;

    final applied = discountPercent.clamp(0, 100).toDouble();

    try {
      await client
          .from('products')
          .update({'discount_percent': applied})
          .eq('id', productId);
      _products[idx] = _products[idx].copyWith(discountPercent: applied);
      notifyListeners();
      return true;
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> addProduct({
    required String sellerId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required DateTime expiryDate,
  }) async {
    final seller = accountById(sellerId);
    if (seller == null ||
        seller.role != AccountRole.seller ||
        !seller.isApproved) {
      return false;
    }

    final client = _client;
    if (client == null) return false;

    final product = Product(
      id: _nextId('product'),
      sellerId: sellerId,
      name: name,
      description: description,
      price: price,
      stock: stock,
      expiryDate: expiryDate,
      discountPercent: 0,
    );

    try {
      await client.from('products').insert({
        'id': product.id,
        'seller_id': product.sellerId,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'stock': product.stock,
        'expiry_date': product.expiryDate.toIso8601String().substring(0, 10),
        'discount_percent': product.discountPercent,
      });

      _products.add(product);
      notifyListeners();
      return true;
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    int? stock,
    DateTime? expiryDate,
  }) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx < 0) return false;

    final current = _currentAccount;
    if (current == null || !current.isApproved) return false;

    final product = _products[idx];
    final canEdit =
        (current.role == AccountRole.admin) ||
        (current.role == AccountRole.seller && product.sellerId == current.id);
    if (!canEdit) return false;

    final updates = <String, dynamic>{};
    String? trimmedName;
    String? trimmedDescription;

    if (name != null) {
      trimmedName = name.trim();
      if (trimmedName.isNotEmpty && trimmedName != product.name) {
        updates['name'] = trimmedName;
      }
    }
    if (description != null) {
      trimmedDescription = description.trim();
      if (trimmedDescription.isNotEmpty &&
          trimmedDescription != product.description) {
        updates['description'] = trimmedDescription;
      }
    }
    if (price != null && price >= 0 && price != product.price) {
      updates['price'] = price;
    }
    if (stock != null && stock >= 0 && stock != product.stock) {
      updates['stock'] = stock;
    }
    if (expiryDate != null && expiryDate != product.expiryDate) {
      updates['expiry_date'] = expiryDate.toIso8601String().substring(0, 10);
    }

    if (updates.isEmpty) return false;

    final client = _client;
    if (client == null) return false;

    try {
      await client.from('products').update(updates).eq('id', productId);
      _products[idx] = product.copyWith(
        name: trimmedName ?? product.name,
        description: trimmedDescription ?? product.description,
        price: price ?? product.price,
        stock: stock ?? product.stock,
        expiryDate: expiryDate ?? product.expiryDate,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx < 0) return false;

    final current = _currentAccount;
    if (current == null || !current.isApproved) return false;

    final product = _products[idx];
    final canDelete =
        (current.role == AccountRole.admin) ||
        (current.role == AccountRole.seller && product.sellerId == current.id);
    if (!canDelete) return false;

    final client = _client;
    if (client == null) return false;

    try {
      await client.from('products').delete().eq('id', productId);
      _products.removeAt(idx);
      notifyListeners();
      return true;
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<Order?> placeOrder({
    required String buyerId,
    required String productId,
    int quantity = 1,
  }) async {
    final buyer = accountById(buyerId);
    final productIdx = _products.indexWhere((p) => p.id == productId);
    if (buyer == null || buyer.role != AccountRole.user || !buyer.isApproved) {
      return null;
    }
    if (productIdx < 0) return null;

    final product = _products[productIdx];
    if (product.stock < quantity) return null;
    if (product.expiryDate.isBefore(DateTime.now())) {
      return null;
    }

    final order = Order(
      id: _nextId('order'),
      buyerId: buyerId,
      sellerId: product.sellerId,
      riderId: null,
      productId: productId,
      quantity: quantity,
      unitPrice: product.price,
      discountPercent: product.discountPercent,
      createdAt: DateTime.now(),
      status: OrderStatus.pendingSellerConfirmation,
      ratingStars: null,
    );

    final client = _client;
    if (client == null) return null;

    final nextStock = product.stock - quantity;

    try {
      await client
          .from('products')
          .update({'stock': nextStock})
          .eq('id', productId);
      await client.from('orders').insert({
        'id': order.id,
        'buyer_id': order.buyerId,
        'seller_id': order.sellerId,
        'rider_id': order.riderId,
        'product_id': order.productId,
        'quantity': order.quantity,
        'unit_price': order.unitPrice,
        'discount_percent': order.discountPercent,
        'created_at': order.createdAt.toIso8601String(),
        'status': order.status.name,
        'rating_stars': order.ratingStars,
      });

      _products[productIdx] = product.copyWith(stock: nextStock);
      _orders.insert(0, order);
      notifyListeners();
      return order;
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> sellerRespondToOrder({
    required String orderId,
    required bool accept,
  }) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;

    final client = _client;
    if (client == null) return;

    final order = _orders[idx];
    if (order.status != OrderStatus.pendingSellerConfirmation) return;

    if (!accept) {
      final productIdx = _products.indexWhere((p) => p.id == order.productId);
      int? restoredStock;
      if (productIdx >= 0) {
        final product = _products[productIdx];
        restoredStock = product.stock + order.quantity;
      }

      try {
        await client
            .from('orders')
            .update({'status': OrderStatus.declinedBySeller.name})
            .eq('id', orderId);
        if (restoredStock != null) {
          await client
              .from('products')
              .update({'stock': restoredStock})
              .eq('id', order.productId);
        }

        if (productIdx >= 0 && restoredStock != null) {
          final product = _products[productIdx];
          _products[productIdx] = product.copyWith(stock: restoredStock);
        }
        _orders[idx] = order.copyWith(status: OrderStatus.declinedBySeller);
        notifyListeners();
      } catch (e) {
        _loadError = _friendlySupabaseError(e);
        notifyListeners();
      }
      return;
    }

    try {
      await client
          .from('orders')
          .update({'status': OrderStatus.preparing.name, 'rider_id': null})
          .eq('id', orderId);

      _orders[idx] = order.copyWith(
        status: OrderStatus.preparing,
        riderId: null,
      );
      notifyListeners();
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  Future<void> sellerMarkOrderReady({required String orderId}) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;

    final client = _client;
    if (client == null) return;

    final order = _orders[idx];
    if (order.status != OrderStatus.preparing) return;

    try {
      await client
          .from('orders')
          .update({'status': OrderStatus.confirmedAwaitingPickup.name})
          .eq('id', orderId);
      _orders[idx] = order.copyWith(
        status: OrderStatus.confirmedAwaitingPickup,
      );
      notifyListeners();
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  Future<void> riderClaimOrder({required String orderId}) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;

    final rider = _currentAccount;
    if (rider == null || rider.role != AccountRole.rider || !rider.isApproved) {
      return;
    }

    final client = _client;
    if (client == null) return;

    final order = _orders[idx];
    if (order.riderId != null) return;
    if (order.status != OrderStatus.confirmedAwaitingPickup) return;

    try {
      await client
          .from('orders')
          .update({'rider_id': rider.id})
          .eq('id', orderId);
      _orders[idx] = order.copyWith(riderId: rider.id);
      notifyListeners();
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  Future<void> setStoreOpen({required bool isOpen}) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.rpc('set_store_open', params: {'p_is_open': isOpen});
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  Future<void> setRiderOnline({required bool isOnline}) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.rpc('set_rider_online', params: {'p_is_online': isOnline});
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  Future<void> riderUpdateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;

    final client = _client;
    if (client == null) return;

    final order = _orders[idx];
    if (order.riderId == null) return;
    if (order.status.isDeclined || order.status.isDelivered) return;

    final allowed = <OrderStatus, Set<OrderStatus>>{
      OrderStatus.confirmedAwaitingPickup: {OrderStatus.pickedUp},
      OrderStatus.pickedUp: {OrderStatus.onTheWay},
      OrderStatus.onTheWay: {OrderStatus.delivered},
    };

    final next = allowed[order.status];
    if (next == null || !next.contains(status)) return;

    try {
      await client
          .from('orders')
          .update({'status': status.name})
          .eq('id', orderId);
      _orders[idx] = order.copyWith(status: status);
      notifyListeners();
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  Future<void> buyerRateOrder({
    required String orderId,
    required int stars,
  }) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    final order = _orders[idx];
    if (!order.status.isDelivered) return;
    final clamped = stars.clamp(1, 5);

    final client = _client;
    if (client == null) return;

    try {
      await client
          .from('orders')
          .update({'rating_stars': clamped})
          .eq('id', orderId);
      _orders[idx] = order.copyWith(ratingStars: clamped);
      notifyListeners();
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final client = _client;
    if (client == null) return;

    final msg = ChatMessage(
      id: _nextId('msg'),
      threadId: threadId,
      senderId: senderId,
      text: trimmed,
      sentAt: DateTime.now(),
    );

    try {
      await client.from('messages').insert({
        'id': msg.id,
        'thread_id': msg.threadId,
        'sender_id': msg.senderId,
        'text': msg.text,
        'sent_at': msg.sentAt.toIso8601String(),
      });
      _messages.add(msg);
      notifyListeners();
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      notifyListeners();
    }
  }

  Future<void> _loadFromSupabase(SupabaseClient client) async {
    try {
      // Public data (available even before sign-in).
      final results = await Future.wait([
        client.from('accounts').select().order('display_name'),
        client.from('products').select().order('created_at'),
      ]);

      final accountsRows = (results[0] as List).cast<Map<String, dynamic>>();
      final productsRows = (results[1] as List).cast<Map<String, dynamic>>();

      _accounts
        ..clear()
        ..addAll(accountsRows.map(_accountFromRow));
      _products
        ..clear()
        ..addAll(productsRows.map(_productFromRow));

      // Restore session (if any) after loading accounts.
      await _restoreCurrentAccountFromSession(client);

      // Private data requires an approved signed-in session.
      if (_currentAccount != null) {
        await _loadPrivateFromSupabase(client);
        _subscribeRealtime(client);
      } else {
        _orders.clear();
        _messages.clear();
        unawaited(_channel?.unsubscribe());
        _channel = null;
      }

      _isLoading = false;
      _loadError = null;
    } catch (e) {
      _isLoading = false;
      _loadError = _friendlySupabaseError(e);
    }

    notifyListeners();
  }

  Future<void> _loadPrivateFromSupabase(SupabaseClient client) async {
    final results = await Future.wait([
      client.from('orders').select().order('created_at', ascending: false),
      client.from('messages').select().order('sent_at'),
    ]);

    final ordersRows = (results[0] as List).cast<Map<String, dynamic>>();
    final messagesRows = (results[1] as List).cast<Map<String, dynamic>>();

    _orders
      ..clear()
      ..addAll(ordersRows.map(_orderFromRow));
    _messages
      ..clear()
      ..addAll(messagesRows.map(_messageFromRow));
  }

  Future<void> _handleAuthChange(
    SupabaseClient client,
    AuthChangeEvent event,
    Session? session,
  ) async {
    if (event == AuthChangeEvent.passwordRecovery) {
      _isInPasswordRecoveryFlow = true;
      _currentAccount = null;
      notifyListeners();
      return;
    }

    if (session == null) {
      _isInPasswordRecoveryFlow = false;
      _currentAccount = null;
      _orders.clear();
      _messages.clear();
      unawaited(_channel?.unsubscribe());
      _channel = null;
      notifyListeners();
      return;
    }

    // Signed in (or refreshed) with a normal session.
    _isInPasswordRecoveryFlow = false;
    _isLoading = true;
    notifyListeners();

    try {
      await _restoreCurrentAccountFromSession(client);
      if (_currentAccount != null) {
        await _loadPrivateFromSupabase(client);
        _subscribeRealtime(client);
      } else {
        // Pending/declined accounts do not load private data.
        _orders.clear();
        _messages.clear();
        unawaited(_channel?.unsubscribe());
        _channel = null;
      }
      _loadError = null;
    } catch (e) {
      _loadError = _friendlySupabaseError(e);
      // Keep the app usable (dashboards can still render without private data).
      _orders.clear();
      _messages.clear();
      unawaited(_channel?.unsubscribe());
      _channel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreCurrentAccountFromSession(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) {
      _currentAccount = null;
      return;
    }

    final account = await _fetchAccountById(client, user.id);
    if (account == null) {
      _currentAccount = null;
      return;
    }

    if (!account.isApproved) {
      // Keep them signed out inside the app until approved.
      _currentAccount = null;
      return;
    }

    _currentAccount = account;
  }

  Future<Account?> _fetchAccountById(
    SupabaseClient client,
    String accountId,
  ) async {
    final existing = accountById(accountId);
    if (existing != null) return existing;

    try {
      final row = await client
          .from('accounts')
          .select()
          .eq('id', accountId)
          .maybeSingle();
      if (row == null) return null;
      final account = _accountFromRow(row);
      _upsertAccount(account);
      return account;
    } catch (_) {
      return null;
    }
  }

  String _friendlySupabaseError(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Invalid email/username or password.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Please verify your email before signing in.';
      }
      if (msg.contains('user already registered') ||
          msg.contains('already registered')) {
        return 'Email is already registered. Try signing in instead.';
      }

      // Supabase Auth email sending (custom SMTP) failures often surface with
      // generic messages like "Error sending confirmation email".
      if (msg.contains('error sending') && msg.contains('email')) {
        return 'Supabase failed to send an email (SMTP error). Check Supabase Dashboard → Authentication → SMTP Settings (host/port/TLS/sender) and Logs for the exact SMTP response.';
      }
      if (msg.contains('smtp')) {
        return 'Supabase SMTP error. Verify Supabase Dashboard → Authentication → SMTP Settings (host/port/TLS/sender) and make sure your SMTP provider allows connections from Supabase.';
      }

      return error.message;
    }

    if (error is PostgrestException) {
      final code = error.code;
      final msg = error.message.toLowerCase();
      final details = (error.details ?? '').toString().toLowerCase();

      // PostgREST returns 404 (schema cache miss) for missing/hidden RPCs.
      // This typically means the SQL function wasn't created, PostgREST schema
      // cache hasn't been reloaded, or EXECUTE wasn't granted to the role.
      if (code == 'PGRST202' ||
          code == '404' ||
          msg.contains('not found') ||
          details.contains('not found') ||
          msg.contains('could not find the function') ||
          details.contains('could not find the function') ||
          msg.contains('schema cache') ||
          details.contains('schema cache')) {
        return 'Supabase endpoint is missing (404) or hidden. Run supabase/schema.sql in Supabase → SQL Editor, then reload the API schema (Settings → API → Reload schema) and restart the app.';
      }

      // 42P01: undefined_table
      if (code == '42P01' || msg.contains('does not exist')) {
        return 'Supabase tables are missing. Run supabase/schema.sql in Supabase → SQL Editor, then reload the app.';
      }

      // 42703: undefined_column
      if (code == '42703' ||
          (msg.contains('column') && msg.contains('does not exist'))) {
        return 'Supabase schema is outdated. Re-run supabase/schema.sql to add missing columns, then reload the app.';
      }

      if (msg.contains('row-level security')) {
        return 'Supabase RLS is blocking requests. Disable RLS for prototype tables or add policies for select/insert/update.';
      }

      if (msg.contains('duplicate key') || msg.contains('unique')) {
        return 'Duplicate value (username/email). Please choose a different username/email.';
      }
    }

    final s = error.toString();
    final lower = s.toLowerCase();
    if (lower.contains('not found')) {
      return 'Supabase endpoint is missing (404) or hidden. Run supabase/schema.sql in Supabase → SQL Editor, then reload the API schema (Settings → API → Reload schema) and restart the app.';
    }
    if (s.contains('42P01') || lower.contains('does not exist')) {
      return 'Supabase tables are missing. Run supabase/schema.sql in Supabase → SQL Editor, then reload the app.';
    }
    if (s.contains('42703') ||
        (lower.contains('column') && lower.contains('does not exist'))) {
      return 'Supabase schema is outdated. Re-run supabase/schema.sql to add missing columns, then reload the app.';
    }
    if (lower.contains('row-level security')) {
      return 'Supabase RLS is blocking requests. Disable RLS for prototype tables or add policies for select/insert/update.';
    }
    return s;
  }

  void _subscribeRealtime(SupabaseClient client) {
    if (_channel != null) return;
    // Keep the UI updated if the database changes (other sessions/devices).
    _channel = client.channel('foodhub-realtime')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'accounts',
        callback: (payload) => _handleAccountsChange(payload),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'products',
        callback: (payload) => _handleProductsChange(payload),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (payload) => _handleOrdersChange(payload),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (payload) => _handleMessagesChange(payload),
      )
      ..subscribe();
  }

  void _handleAccountsChange(PostgresChangePayload payload) {
    _handleChange(
      payload,
      upsert: (row) => _upsertAccount(_accountFromRow(row)),
      remove: (row) => _removeById(_accounts, row['id']?.toString()),
    );
  }

  void _handleProductsChange(PostgresChangePayload payload) {
    _handleChange(
      payload,
      upsert: (row) => _upsertProduct(_productFromRow(row)),
      remove: (row) => _removeById(_products, row['id']?.toString()),
    );
  }

  void _handleOrdersChange(PostgresChangePayload payload) {
    _handleChange(
      payload,
      upsert: (row) => _upsertOrder(_orderFromRow(row)),
      remove: (row) => _removeById(_orders, row['id']?.toString()),
    );
  }

  void _handleMessagesChange(PostgresChangePayload payload) {
    _handleChange(
      payload,
      upsert: (row) => _upsertMessage(_messageFromRow(row)),
      remove: (row) => _removeById(_messages, row['id']?.toString()),
    );
  }

  void _handleChange(
    PostgresChangePayload payload, {
    required void Function(Map<String, dynamic> row) upsert,
    required void Function(Map<String, dynamic> row) remove,
  }) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
      case PostgresChangeEvent.update:
        final row = payload.newRecord;
        if (row.isNotEmpty) {
          try {
            upsert(row);
            _loadError = null;
          } catch (e) {
            _loadError = _friendlySupabaseError(e);
          }
          notifyListeners();
        }
        break;
      case PostgresChangeEvent.delete:
        final row = payload.oldRecord;
        if (row.isNotEmpty) {
          try {
            remove(row);
            _loadError = null;
          } catch (e) {
            _loadError = _friendlySupabaseError(e);
          }
          notifyListeners();
        }
        break;
      case PostgresChangeEvent.all:
        break;
    }
  }

  void _upsertAccount(Account account) {
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx < 0) {
      _accounts.add(account);
    } else {
      _accounts[idx] = account;
    }

    if (_currentAccount?.id == account.id) {
      if (!account.isApproved) {
        unawaited(signOut());
      } else {
        _currentAccount = account;
      }
    }
  }

  void _upsertProduct(Product product) {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx < 0) {
      _products.add(product);
    } else {
      _products[idx] = product;
    }
  }

  void _upsertOrder(Order order) {
    final idx = _orders.indexWhere((o) => o.id == order.id);
    if (idx < 0) {
      _orders.insert(0, order);
    } else {
      _orders[idx] = order;
    }
  }

  void _upsertMessage(ChatMessage message) {
    final idx = _messages.indexWhere((m) => m.id == message.id);
    if (idx < 0) {
      _messages.add(message);
    } else {
      _messages[idx] = message;
    }
  }

  void _removeById<T>(List<T> list, String? id) {
    if (id == null) return;
    if (T == Account) {
      list.removeWhere((e) => (e as Account).id == id);
      return;
    }
    if (T == Product) {
      list.removeWhere((e) => (e as Product).id == id);
      return;
    }
    if (T == Order) {
      list.removeWhere((e) => (e as Order).id == id);
      return;
    }
    if (T == ChatMessage) {
      list.removeWhere((e) => (e as ChatMessage).id == id);
      return;
    }
  }

  Account _accountFromRow(Map<String, dynamic> row) {
    String? storeCategory;
    bool? storeIsOpen;
    bool? riderIsOnline;
    double? commissionRateOverride;
    final rawProfile = row['profile'];
    Map<String, dynamic>? profile;
    if (rawProfile is Map<String, dynamic>) {
      profile = rawProfile;
    } else if (rawProfile is String && rawProfile.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawProfile);
        if (decoded is Map<String, dynamic>) {
          profile = decoded;
        }
      } catch (_) {
        // Ignore profile parsing errors.
      }
    }

    if (profile != null) {
      final store = profile['store'];
      if (store is Map) {
        final cat = store['store_category'];
        if (cat is String && cat.trim().isNotEmpty) {
          storeCategory = cat.trim();
        }

        final isOpen = store['is_open'];
        if (isOpen is bool) {
          storeIsOpen = isOpen;
        } else if (isOpen is String) {
          final v = isOpen.trim().toLowerCase();
          if (v == 'true' || v == '1' || v == 'yes') storeIsOpen = true;
          if (v == 'false' || v == '0' || v == 'no') storeIsOpen = false;
        }
      }

      final rider = profile['rider'];
      if (rider is Map) {
        final isOnline = rider['is_online'];
        if (isOnline is bool) {
          riderIsOnline = isOnline;
        } else if (isOnline is String) {
          final v = isOnline.trim().toLowerCase();
          if (v == 'true' || v == '1' || v == 'yes') riderIsOnline = true;
          if (v == 'false' || v == '0' || v == 'no') riderIsOnline = false;
        }
      }

      final commission = profile['commission'];
      if (commission is Map) {
        final rate = commission['rate'];
        if (rate != null) {
          final parsed = _toDouble(rate);
          if (parsed > 0) commissionRateOverride = parsed;
        }
      }
    }

    return Account(
      id: row['id']?.toString() ?? '',
      displayName: row['display_name']?.toString() ?? '',
      username: row['username']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      emailVerified: row['email_verified'] == true,
      passwordSalt: row['password_salt']?.toString() ?? '',
      passwordHash: row['password_hash']?.toString() ?? '',
      role: _enumFromString<AccountRole>(
        AccountRole.values,
        row['role']?.toString(),
        AccountRole.user,
        aliases: const {
          // Legacy/UX naming: treat "buyer" as the app's user role.
          'buyer': AccountRole.user,
        },
      ),
      status: _enumFromString<AccountStatus>(
        AccountStatus.values,
        row['status']?.toString(),
        AccountStatus.pending,
      ),
      credentialsSubmitted: row['credentials_submitted'] == true,
      storeCategory: storeCategory,
      storeIsOpen: storeIsOpen,
      riderIsOnline: riderIsOnline,
      commissionRateOverride: commissionRateOverride,
    );
  }

  Product _productFromRow(Map<String, dynamic> row) {
    final expiry = _parseDate(row['expiry_date']);
    return Product(
      id: row['id']?.toString() ?? '',
      sellerId: row['seller_id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      price: _toDouble(row['price']),
      stock: _toInt(row['stock']),
      expiryDate: expiry,
      discountPercent: _toDouble(row['discount_percent']),
    );
  }

  Order _orderFromRow(Map<String, dynamic> row) {
    return Order(
      id: row['id']?.toString() ?? '',
      buyerId: row['buyer_id']?.toString() ?? '',
      sellerId: row['seller_id']?.toString() ?? '',
      riderId: row['rider_id']?.toString(),
      productId: row['product_id']?.toString() ?? '',
      quantity: _toInt(row['quantity']),
      unitPrice: _toDouble(row['unit_price']),
      discountPercent: _toDouble(row['discount_percent']),
      createdAt: _parseDateTime(row['created_at']),
      status: _enumFromString<OrderStatus>(
        OrderStatus.values,
        row['status']?.toString(),
        OrderStatus.pendingSellerConfirmation,
      ),
      ratingStars: row['rating_stars'] == null
          ? null
          : _toInt(row['rating_stars']),
    );
  }

  ChatMessage _messageFromRow(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id']?.toString() ?? '',
      threadId: row['thread_id']?.toString() ?? '',
      senderId: row['sender_id']?.toString() ?? '',
      text: row['text']?.toString() ?? '',
      sentAt: _parseDateTime(row['sent_at']),
    );
  }

  String _normalizeEnumKey(String value) {
    return value.trim().toLowerCase()
    // Strip separators to accept snake_case/kebab-case/spaces.
    .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  T _enumFromString<T extends Enum>(
    List<T> values,
    String? raw,
    T fallback, {
    Map<String, T>? aliases,
  }) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return fallback;

    final key = _normalizeEnumKey(s);
    final alias = aliases?[key];
    if (alias != null) return alias;

    for (final v in values) {
      if (_normalizeEnumKey(v.name) == key) return v;
    }
    return fallback;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    final s = value?.toString();
    if (s == null || s.isEmpty) return DateTime.now();
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return DateTime.now();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    final s = value?.toString();
    if (s == null || s.isEmpty) return DateTime.now();
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  List<ChatMessage> messagesForThread(String threadId) {
    return _messages.where((m) => m.threadId == threadId).toList();
  }

  double commissionForOrder(Order order) {
    final seller = accountById(order.sellerId);
    final base = seller?.commissionRateOverride;
    final appliedBase = (base ?? FoodHubConstants.baseCommissionRate)
        .clamp(0.0, 1.0)
        .toDouble();
    final rate = commissionRateForDiscount(
      baseCommissionRate: appliedBase,
      discountPercent: order.discountPercent,
    );
    return order.netTotal * rate;
  }

  double totalCommissionCollected() {
    return _orders
        .where((o) => o.status.isDelivered)
        .map(commissionForOrder)
        .fold<double>(0, (a, b) => a + b);
  }

  double sellerRevenue(String sellerId) {
    return _orders
        .where((o) => o.sellerId == sellerId && o.status.isDelivered)
        .map((o) => o.netTotal)
        .fold<double>(0, (a, b) => a + b);
  }

  double sellerCommissionPaid(String sellerId) {
    return _orders
        .where((o) => o.sellerId == sellerId && o.status.isDelivered)
        .map(commissionForOrder)
        .fold<double>(0, (a, b) => a + b);
  }

  int riderDeliveredCount(String riderId) {
    return _orders
        .where((o) => o.riderId == riderId && o.status.isDelivered)
        .length;
  }

  // ignore: unused_element
  void _seedDemoData() {
    const demoPasswords = (
      admin: 'Admin123!',
      user: 'User123!',
      seller: 'Seller123!',
      rider: 'Rider123!',
    );

    String makeSalt(String seed) => base64UrlEncode(utf8.encode(seed));

    ({String salt, String hash}) credsFor(String saltSeed, String password) {
      final salt = makeSalt(saltSeed);
      final hash = hashPassword(password: password, salt: salt);
      return (salt: salt, hash: hash);
    }

    final adminCreds = credsFor('admin_1', demoPasswords.admin);
    final buyerCreds = credsFor('user_1', demoPasswords.user);
    final sellerCreds = credsFor('seller_1', demoPasswords.seller);
    final riderCreds = credsFor('rider_1', demoPasswords.rider);
    final pendingBuyerCreds = credsFor('user_pending', demoPasswords.user);
    final pendingSellerCreds = credsFor('seller_pending', demoPasswords.seller);
    final pendingRiderCreds = credsFor('rider_pending', demoPasswords.rider);

    final admin = Account(
      id: 'admin_1',
      displayName: 'Admin',
      username: 'admin',
      email: 'admin@foodhub.local',
      emailVerified: true,
      passwordSalt: adminCreds.salt,
      passwordHash: adminCreds.hash,
      role: AccountRole.admin,
      status: AccountStatus.approved,
      credentialsSubmitted: true,
    );
    final buyer = Account(
      id: 'user_1',
      displayName: 'Alice (Buyer)',
      username: 'alice',
      email: 'alice@foodhub.local',
      emailVerified: true,
      passwordSalt: buyerCreds.salt,
      passwordHash: buyerCreds.hash,
      role: AccountRole.user,
      status: AccountStatus.approved,
      credentialsSubmitted: false,
    );
    final seller = Account(
      id: 'seller_1',
      displayName: 'FreshMart (Seller)',
      username: 'freshmart',
      email: 'seller@foodhub.local',
      emailVerified: true,
      passwordSalt: sellerCreds.salt,
      passwordHash: sellerCreds.hash,
      role: AccountRole.seller,
      status: AccountStatus.approved,
      credentialsSubmitted: true,
    );
    final rider = Account(
      id: 'rider_1',
      displayName: 'Ramon (Rider)',
      username: 'ramon',
      email: 'rider@foodhub.local',
      emailVerified: true,
      passwordSalt: riderCreds.salt,
      passwordHash: riderCreds.hash,
      role: AccountRole.rider,
      status: AccountStatus.approved,
      credentialsSubmitted: true,
    );

    _accounts.addAll([
      admin,
      buyer,
      seller,
      rider,
      Account(
        id: 'user_pending',
        displayName: 'New Buyer (Pending)',
        username: 'newbuyer',
        email: 'newbuyer@foodhub.local',
        emailVerified: true,
        passwordSalt: pendingBuyerCreds.salt,
        passwordHash: pendingBuyerCreds.hash,
        role: AccountRole.user,
        status: AccountStatus.pending,
        credentialsSubmitted: false,
      ),
      Account(
        id: 'seller_pending',
        displayName: 'New Seller (Pending)',
        username: 'newseller',
        email: 'newseller@foodhub.local',
        emailVerified: true,
        passwordSalt: pendingSellerCreds.salt,
        passwordHash: pendingSellerCreds.hash,
        role: AccountRole.seller,
        status: AccountStatus.pending,
        credentialsSubmitted: true,
      ),
      Account(
        id: 'rider_pending',
        displayName: 'New Rider (Pending)',
        username: 'newrider',
        email: 'newrider@foodhub.local',
        emailVerified: true,
        passwordSalt: pendingRiderCreds.salt,
        passwordHash: pendingRiderCreds.hash,
        role: AccountRole.rider,
        status: AccountStatus.pending,
        credentialsSubmitted: true,
      ),
    ]);

    final now = DateTime.now();
    _products.addAll([
      Product(
        id: 'product_1',
        sellerId: seller.id,
        name: 'Whole Wheat Bread',
        description: 'Fresh-baked loaf. Best consumed before expiry.',
        price: 60,
        stock: 12,
        expiryDate: now.add(const Duration(days: 18)),
        discountPercent: 0,
      ),
      Product(
        id: 'product_2',
        sellerId: seller.id,
        name: 'Fresh Milk 1L',
        description: 'Chilled milk. Keep refrigerated.',
        price: 75,
        stock: 20,
        expiryDate: now.add(const Duration(days: 10)),
        discountPercent: 0,
      ),
      Product(
        id: 'product_3',
        sellerId: seller.id,
        name: 'Yogurt Cup',
        description: 'Single-serve yogurt.',
        price: 35,
        stock: 30,
        expiryDate: now.add(const Duration(days: 5)),
        discountPercent: 0,
      ),
      Product(
        id: 'product_4',
        sellerId: seller.id,
        name: 'Salad Pack',
        description: 'Ready-to-eat mixed greens.',
        price: 50,
        stock: 8,
        expiryDate: now.add(const Duration(days: 2)),
        discountPercent: 0,
      ),
    ]);

    _orders.addAll([
      Order(
        id: 'order_1',
        buyerId: buyer.id,
        sellerId: seller.id,
        riderId: rider.id,
        productId: 'product_2',
        quantity: 1,
        unitPrice: 75,
        discountPercent: 15,
        createdAt: now.subtract(const Duration(days: 2)),
        status: OrderStatus.delivered,
        ratingStars: 4,
      ),
      Order(
        id: 'order_2',
        buyerId: buyer.id,
        sellerId: seller.id,
        riderId: null,
        productId: 'product_1',
        quantity: 1,
        unitPrice: 60,
        discountPercent: 0,
        createdAt: now.subtract(const Duration(hours: 3)),
        status: OrderStatus.pendingSellerConfirmation,
        ratingStars: null,
      ),
    ]);

    _messages.addAll([
      ChatMessage(
        id: 'msg_1',
        threadId: 'order_2',
        senderId: buyer.id,
        text: 'Hi! Can you confirm my order when ready?',
        sentAt: now.subtract(const Duration(hours: 2, minutes: 30)),
      ),
    ]);
  }
}

class _EmailCodeState {
  _EmailCodeState({required this.code, required this.sentAt});

  final String code;
  final DateTime sentAt;
}
