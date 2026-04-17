import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import '../../core/app_store.dart';
import '../../core/app_store_scope.dart';
import '../../core/config.dart';
import '../../core/ph_locations.dart';
import '../../models/account.dart';
import 'auth_scaffold.dart';
import 'password_strength_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _LocationDraft {
  String? regionCode;
  String? cityCode;
  String? barangayCode;
  List<PhBarangay> barangays = const <PhBarangay>[];
  bool loadingBarangays = false;

  final TextEditingController street = TextEditingController();

  double? latitude;
  double? longitude;

  void dispose() {
    street.dispose();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _totalSteps = 4;
  static const int _emailOtpLength = 6;
  static const int _adminInviteCodeLength = 8;

  final _formKey = GlobalKey<FormState>();

  int _stepIndex = 0;
  AccountRole _role = AccountRole.user;

  Future<void>? _phLocationsLoad;
  final _deliveryLocation = _LocationDraft();
  final _storeLocation = _LocationDraft();

  final FocusNode _operatingHoursFocus = FocusNode();

  // STEP 1 — Account basics
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _suffix = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // STEP 1b — Email verification
  bool _awaitingEmailOtp = false;
  bool _emailVerified = false;

  // STEP 3a — User
  final _deliveryAddress = TextEditingController();
  final _profilePhotoRef = TextEditingController();
  DateTime? _birthday;

  // STEP 3b — Seller
  final _storeName = TextEditingController();
  final _cuisineType = TextEditingController();
  final _storeAddress = TextEditingController();
  final _operatingHours = TextEditingController();
  final _storeLogoRef = TextEditingController();
  final _businessPermitRef = TextEditingController();
  final _ownerIdRef = TextEditingController();

  // STEP 3c — Rider
  bool _riderNameConfirmed = false;
  String? _vehicleType;
  final _plateNumber = TextEditingController();
  final _driversLicenseRef = TextEditingController();
  final _vehicleRegistrationRef = TextEditingController();

  // STEP 4 — Verification
  final _emailOtp = TextEditingController();
  int _otpResendSeconds = 0;
  Timer? _otpResendTimer;
  String? _pendingEmail;

  // STEP 2 — Admin invitation
  final _adminInvitationCode = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _phLocationsLoad = PhLocations.ensureLoaded();
  }

  @override
  void dispose() {
    _otpResendTimer?.cancel();

    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _suffix.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();

    _deliveryAddress.dispose();
    _profilePhotoRef.dispose();

    _storeName.dispose();
    _cuisineType.dispose();
    _storeAddress.dispose();
    _operatingHours.dispose();
    _storeLogoRef.dispose();
    _businessPermitRef.dispose();
    _ownerIdRef.dispose();

    _plateNumber.dispose();
    _driversLicenseRef.dispose();
    _vehicleRegistrationRef.dispose();

    _emailOtp.dispose();
    _adminInvitationCode.dispose();

    _deliveryLocation.dispose();
    _storeLocation.dispose();
    _operatingHoursFocus.dispose();

    super.dispose();
  }

  static String _joinNameParts(Iterable<String> parts) {
    final cleaned = parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return cleaned.join(' ');
  }

  String _fullName() {
    return _joinNameParts([
      _firstName.text,
      _middleName.text,
      _lastName.text,
      _suffix.text,
    ]);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static String _formatLatLng(double lat, double lng) {
    return 'GPS: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  Future<void> _pickFileInto(TextEditingController controller) async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final ref = (file.path?.trim().isNotEmpty ?? false) ? file.path! : file.name;
      setState(() => controller.text = ref);
    } catch (_) {
      _snack('Unable to pick file from device storage.');
    }
  }

  Future<void> _useDeviceLocation({
    required _LocationDraft draft,
    required TextEditingController addressController,
  }) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _snack('Location services are disabled.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _snack('Location permission is denied (Settings required).');
        return;
      }
      if (permission == LocationPermission.denied) {
        _snack('Location permission denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;

      setState(() {
        draft.latitude = pos.latitude;
        draft.longitude = pos.longitude;

        // Clear dropdown entry to avoid mixing "GPS" vs cascading selection.
        draft.regionCode = null;
        draft.cityCode = null;
        draft.barangayCode = null;
        draft.barangays = const <PhBarangay>[];
        draft.loadingBarangays = false;
        draft.street.text = '';

        addressController.text = _formatLatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {
      _snack('Unable to get device location.');
    }
  }

  Future<void> _loadBarangaysForCity(_LocationDraft draft, String cityCode) async {
    setState(() {
      draft.loadingBarangays = true;
      draft.barangays = const <PhBarangay>[];
      draft.barangayCode = null;
    });

    try {
      final items = await PhBarangayApi.fetchBarangays(
        cityOrMunicipalityCode: cityCode,
      );
      if (!mounted) return;
      setState(() {
        draft.barangays = items;
        draft.loadingBarangays = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        draft.loadingBarangays = false;
      });
      _snack('Unable to load barangays.');
    }
  }

  void _syncAddressFromDraft(
    TextEditingController addressController,
    _LocationDraft draft,
  ) {
    final region =
        draft.regionCode == null ? null : PhLocations.regionByCode(draft.regionCode!);
    final city = draft.cityCode == null ? null : PhLocations.cityByCode(draft.cityCode!);

    PhBarangay? barangay;
    final bCode = draft.barangayCode;
    if (bCode != null) {
      for (final b in draft.barangays) {
        if (b.code == bCode) {
          barangay = b;
          break;
        }
      }
    }

    final street = draft.street.text.trim();
    final hasCascade =
        street.isNotEmpty || region != null || city != null || barangay != null;

    if (!hasCascade) {
      final lat = draft.latitude;
      final lng = draft.longitude;
      addressController.text =
          (lat != null && lng != null) ? _formatLatLng(lat, lng) : '';
      return;
    }

    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (barangay != null) parts.add(barangay.name);
    if (city != null) parts.add(city.name);
    if (region != null) parts.add(region.label);
    addressController.text = parts.join(', ');
  }

  Map<String, dynamic> _locationProfile(_LocationDraft draft) {
    final out = <String, dynamic>{};
    final lat = draft.latitude;
    final lng = draft.longitude;
    if (lat != null) out['lat'] = lat;
    if (lng != null) out['lng'] = lng;
    if ((draft.regionCode ?? '').trim().isNotEmpty) {
      out['region_code'] = draft.regionCode;
    }
    if ((draft.cityCode ?? '').trim().isNotEmpty) out['city_code'] = draft.cityCode;
    if ((draft.barangayCode ?? '').trim().isNotEmpty) {
      out['barangay_code'] = draft.barangayCode;
    }
    final street = draft.street.text.trim();
    if (street.isNotEmpty) out['street'] = street;
    return out;
  }

  bool _canUseSupabase(AppStore store) {
    return FoodHubConfig.hasSupabase && store.isUsingSupabase;
  }

  void _startOtpResendCountdown(int seconds) {
    _otpResendTimer?.cancel();
    setState(() => _otpResendSeconds = seconds);

    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_otpResendSeconds <= 1) {
        t.cancel();
        setState(() => _otpResendSeconds = 0);
        return;
      }
      setState(() => _otpResendSeconds--);
    });
  }

  static String _sanitizeUsername(String input) {
    final lower = input.trim().toLowerCase();
    final sanitized = lower
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    var start = 0;
    var end = sanitized.length;
    while (start < end && sanitized[start] == '_') {
      start++;
    }
    while (end > start && sanitized[end - 1] == '_') {
      end--;
    }
    return sanitized.substring(start, end);
  }

  String _generateUsername(AppStore store) {
    final email = _email.text.trim();
    final localPart = email.contains('@') ? email.split('@').first : email;
    final base = _sanitizeUsername(localPart);
    final suffix = (DateTime.now().microsecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    final candidate = base.isEmpty ? 'user_$suffix' : '${base}_$suffix';
    if (store.isUsernameAvailable(candidate)) return candidate;
    return '${candidate}_${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  Map<String, dynamic> _buildProfile() {
    return switch (_role) {
      AccountRole.user => {
          'user': {
            'delivery_address': _deliveryAddress.text.trim(),
            'location': _locationProfile(_deliveryLocation),
            'profile_photo': _profilePhotoRef.text.trim(),
            'birthday': _birthday?.toIso8601String().substring(0, 10),
          },
        },
      AccountRole.seller => {
          'store': {
            'store_name': _storeName.text.trim(),
            'store_category': _cuisineType.text.trim(),
            'address': _storeAddress.text.trim(),
            'location': _locationProfile(_storeLocation),
            'operating_hours': _operatingHours.text.trim(),
            'uploads': {
              'store_logo': _storeLogoRef.text.trim(),
              'business_permit': _businessPermitRef.text.trim(),
              'owner_id': _ownerIdRef.text.trim(),
            },
          },
        },
      AccountRole.rider => {
          'rider': {
            'vehicle_type': _vehicleType,
            'plate_number': _plateNumber.text.trim(),
            'uploads': {
              'drivers_license': _driversLicenseRef.text.trim(),
              'vehicle_registration': _vehicleRegistrationRef.text.trim(),
            },
          },
        },
      AccountRole.admin => const <String, dynamic>{},
    };
  }

  bool _validateCurrentStep(AppStore store) {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return false;

    if (_stepIndex == 2 && _role == AccountRole.rider) {
      if (!_riderNameConfirmed) {
        _snack('Please confirm your full name.');
        return false;
      }
    }

    if (_stepIndex == 0 && _awaitingEmailOtp) {
      final code = _emailOtp.text.trim();
      if (code.length != _emailOtpLength) {
        _snack('Enter the $_emailOtpLength-digit code.');
        return false;
      }
    }

    if (_stepIndex <= 2 && !_canUseSupabase(store)) {
      _snack('Supabase is not configured for this build.');
      return false;
    }

    return true;
  }

  Map<String, dynamic> _buildNameProfile() {
    return {
      'name': {
        'first': _firstName.text.trim(),
        'middle': _middleName.text.trim(),
        'last': _lastName.text.trim(),
        'suffix': _suffix.text.trim(),
        'full': _fullName(),
      },
    };
  }

  Future<void> _beginEmailVerification(AppStore store) async {
    final email = _email.text.trim();
    final fullName = _fullName().trim();
    final username = _generateUsername(store);

    final displayName = fullName.isNotEmpty ? fullName : username;

    setState(() => _submitting = true);
    final result = await store.beginSignupForEmailVerification(
      displayName: displayName,
      username: username,
      email: email,
      password: _password.text,
      profileDraft: _buildNameProfile(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.error != null) {
      _snack(result.error!);
      return;
    }

    if (!result.requiresEmailOtp) {
      setState(() {
        _pendingEmail = email;
        _emailOtp.clear();
        _awaitingEmailOtp = false;
        _emailVerified = true;
        _stepIndex = 1;
      });
      return;
    }

    setState(() {
      _pendingEmail = email;
      _emailOtp.clear();
      _awaitingEmailOtp = true;
      _emailVerified = false;
    });
    _startOtpResendCountdown(30);
  }

  Future<void> _finalizeRegistration(AppStore store) async {
    final fullName = _fullName().trim();
    final displayName = switch (_role) {
      AccountRole.seller => _storeName.text.trim().isNotEmpty
          ? _storeName.text.trim()
          : (fullName.isNotEmpty ? fullName : _generateUsername(store)),
      _ => fullName.isNotEmpty ? fullName : _generateUsername(store),
    };

    final credentialsSubmitted = switch (_role) {
      AccountRole.seller => true,
      AccountRole.rider => true,
      AccountRole.admin => true,
      _ => false,
    };

    final profile = <String, dynamic>{
      ..._buildNameProfile(),
      ..._buildProfile(),
    };

    setState(() => _submitting = true);
    final err = await store.finalizeRegistration(
      role: _role,
      displayName: displayName,
      credentialsSubmitted: credentialsSubmitted,
      profile: profile,
      adminInvitationCode:
          _role == AccountRole.admin ? _adminInvitationCode.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (err != null) {
      _snack(err);
      return;
    }

    await store.signOut();
    if (!mounted) return;
    setState(() => _stepIndex = 3);
  }

  Future<void> _verifyEmailOtp(AppStore store) async {
    final email = (_pendingEmail ?? _email.text).trim();
    final code = _emailOtp.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter a valid email.');
      return;
    }
    if (code.length != _emailOtpLength) {
      _snack('Enter the $_emailOtpLength-digit code.');
      return;
    }

    setState(() => _submitting = true);
    final err = await store.verifySignupEmailOtp(
      email: email,
      code: code,
      signOutAfter: false,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (err != null) {
      _snack(err);
      return;
    }

    _otpResendTimer?.cancel();
    setState(() {
      _awaitingEmailOtp = false;
      _emailVerified = true;
      _stepIndex = 1;
    });
  }

  Future<void> _resendEmailOtp(AppStore store) async {
    final email = (_pendingEmail ?? _email.text).trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter a valid email.');
      return;
    }

    setState(() => _submitting = true);
    final err = await store.resendSignupEmailOtp(email: email);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (err != null) {
      _snack(err);
      return;
    }

    _startOtpResendCountdown(30);
    _snack('Verification code resent. Check your inbox.');
  }

  Future<void> _next(AppStore store) async {
    if (_stepIndex == 3) {
      Navigator.of(context).pop();
      return;
    }

    if (_stepIndex == 0) {
      if (!_validateCurrentStep(store)) return;
      if (!_awaitingEmailOtp && !_emailVerified) {
        await _beginEmailVerification(store);
        return;
      }
      if (_awaitingEmailOtp && !_emailVerified) {
        await _verifyEmailOtp(store);
        return;
      }
      setState(() => _stepIndex = 1);
      return;
    }

    if (!_validateCurrentStep(store)) return;

    if (_stepIndex == 2) {
      await _finalizeRegistration(store);
      return;
    }

    setState(() => _stepIndex++);
  }

  void _back() {
    if (_stepIndex <= 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _stepIndex--);
  }

  Widget _stepHeader() {
    final title = switch (_stepIndex) {
      0 => 'Account basics',
      1 => 'Choose account type',
      2 => 'Tell us about you',
      _ => 'Welcome',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${_stepIndex + 1} of $_totalSteps',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 28,
                height: 1.1,
              ),
        ),
      ],
    );
  }

  Widget _buildBasicsStep(AppStore store) {
    final canEdit = !_submitting && !store.isLoading;
    final canEditBasics = canEdit && !_awaitingEmailOtp && !_emailVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstName,
                enabled: canEditBasics,
                decoration: const InputDecoration(labelText: 'First name'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'First name is required.'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _middleName,
                enabled: canEditBasics,
                decoration: const InputDecoration(
                  labelText: 'Middle name (optional)',
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lastName,
                enabled: canEditBasics,
                decoration: const InputDecoration(labelText: 'Last name'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Last name is required.'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _suffix,
                enabled: canEditBasics,
                decoration: const InputDecoration(
                  labelText: 'Suffix (optional)',
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_awaitingEmailOtp) ...[
          Text(
            'We sent a $_emailOtpLength-digit code to ${(_pendingEmail ?? _email.text).trim()}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailOtp,
            enabled: canEdit,
            decoration: const InputDecoration(labelText: 'Verification code'),
            keyboardType: TextInputType.number,
            maxLength: _emailOtpLength,
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.isEmpty) return 'Code is required.';
              if (text.length != _emailOtpLength) {
                return 'Enter $_emailOtpLength digits.';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(
                onPressed: (!canEdit || _otpResendSeconds > 0)
                    ? null
                    : () async => _resendEmailOtp(store),
                child: Text(
                  _otpResendSeconds > 0
                      ? 'Resend (${_otpResendSeconds}s)'
                      : 'Resend code',
                ),
              ),
            ],
          ),
        ] else ...[
          TextFormField(
            controller: _email,
            enabled: canEditBasics,
            decoration: InputDecoration(
              labelText: _emailVerified ? 'Email (verified)' : 'Email',
              suffixIcon: _emailVerified
                  ? const Icon(Icons.verified_rounded)
                  : null,
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.isEmpty) return 'Email is required.';
              if (!text.contains('@')) return 'Enter a valid email.';
              if (store.accountByUsernameOrEmail(text) != null) {
                return 'Email is already registered.';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _password,
          enabled: canEditBasics,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: canEdit
                  ? () => setState(() => _obscurePassword = !_obscurePassword)
                  : null,
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: (v) {
            final text = v ?? '';
            if (text.trim().isEmpty) return 'Password is required.';
            if (text.trim().length < 8) return 'Minimum 8 characters.';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        PasswordStrengthBar(password: _password.text),
        const SizedBox(height: 12),
        TextFormField(
          controller: _confirmPassword,
          enabled: canEditBasics,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm password',
            suffixIcon: IconButton(
              tooltip:
                  _obscureConfirmPassword ? 'Show password' : 'Hide password',
              onPressed: canEdit
                  ? () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      )
                  : null,
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: (v) {
            if ((v ?? '').isEmpty) return 'Confirm your password.';
            if (v != _password.text) return 'Passwords do not match.';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAccountTypeStep(AppStore store) {
    final scheme = Theme.of(context).colorScheme;

    Widget card({
      required AccountRole role,
      required IconData icon,
      required String title,
      required String subtitle,
      bool invitationOnly = false,
    }) {
      final selected = _role == role;
      void onTap() => setState(() {
            _role = role;
          });

      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (!_submitting && !store.isLoading) ? onTap : null,
        child: Card(
          color: selected ? scheme.primary.withAlpha(18) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (invitationOnly) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Invitation code required',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card(
          role: AccountRole.user,
          icon: Icons.shopping_bag_outlined,
          title: 'I want to order food',
          subtitle: 'User / Buyer',
        ),
        const SizedBox(height: 12),
        card(
          role: AccountRole.seller,
          icon: Icons.storefront_outlined,
          title: 'I want to sell on Food Hub',
          subtitle: 'Seller',
        ),
        const SizedBox(height: 12),
        card(
          role: AccountRole.rider,
          icon: Icons.delivery_dining_outlined,
          title: 'I want to deliver orders',
          subtitle: 'Rider',
        ),
        const SizedBox(height: 12),
        card(
          role: AccountRole.admin,
          icon: Icons.admin_panel_settings_outlined,
          title: 'Admin',
          subtitle: 'Invitation-only',
          invitationOnly: true,
        ),
        if (_role == AccountRole.admin) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _adminInvitationCode,
            enabled: !_submitting && !store.isLoading,
            decoration: const InputDecoration(
              labelText: 'Admin invitation code',
            ),
            maxLength: _adminInviteCodeLength,
            textInputAction: TextInputAction.done,
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.isEmpty) return 'Invitation code is required.';
              if (text.length != _adminInviteCodeLength) {
                return 'Enter $_adminInviteCodeLength characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Get this code from an existing admin.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Note: Admin accounts require an invitation code.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection({
    required String addressLabel,
    required TextEditingController addressController,
    required _LocationDraft draft,
    required bool canEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: !canEdit
              ? null
              : () async => _useDeviceLocation(
                    draft: draft,
                    addressController: addressController,
                  ),
          icon: const Icon(Icons.my_location_rounded),
          label: const Text('Use device location'),
        ),
        const SizedBox(height: 12),
        FutureBuilder<void>(
          future: _phLocationsLoad,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Location list unavailable. You can still use device location.',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }

            final regions = PhLocations.regions;
            final cities = draft.regionCode == null
                ? const <PhCityMunicipality>[]
                : PhLocations.citiesForProvinceOrRegion(draft.regionCode!);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('region_${draft.regionCode ?? 'none'}'),
                  initialValue: draft.regionCode,
                  items: [
                    for (final r in regions)
                      DropdownMenuItem(value: r.code, child: Text(r.label)),
                  ],
                  onChanged: !canEdit
                      ? null
                      : (v) {
                          setState(() {
                            draft.latitude = null;
                            draft.longitude = null;
                            draft.regionCode = v;
                            draft.cityCode = null;
                            draft.barangayCode = null;
                            draft.barangays = const <PhBarangay>[];
                            draft.loadingBarangays = false;
                          });
                          _syncAddressFromDraft(addressController, draft);
                        },
                  validator: (v) {
                    final hasGps =
                        draft.latitude != null && draft.longitude != null;
                    if (hasGps) return null;
                    if ((v ?? '').trim().isEmpty) return 'Region is required.';
                    return null;
                  },
                  decoration: const InputDecoration(labelText: 'Region'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'city_${draft.regionCode ?? 'none'}_${draft.cityCode ?? 'none'}',
                  ),
                  initialValue: draft.cityCode,
                  items: [
                    for (final c in cities)
                      DropdownMenuItem(value: c.code, child: Text(c.name)),
                  ],
                  onChanged: (!canEdit || draft.regionCode == null)
                      ? null
                      : (v) {
                          setState(() {
                            draft.latitude = null;
                            draft.longitude = null;
                            draft.cityCode = v;
                            draft.barangayCode = null;
                            draft.barangays = const <PhBarangay>[];
                            draft.loadingBarangays = false;
                          });
                          _syncAddressFromDraft(addressController, draft);
                          if (v != null && v.trim().isNotEmpty) {
                            unawaited(_loadBarangaysForCity(draft, v));
                          }
                        },
                  validator: (v) {
                    final hasGps =
                        draft.latitude != null && draft.longitude != null;
                    if (hasGps) return null;
                    if ((v ?? '').trim().isEmpty) {
                      return 'Municipality is required.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Municipality / City',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'brgy_${draft.cityCode ?? 'none'}_${draft.barangayCode ?? 'none'}',
                  ),
                  initialValue: draft.barangayCode,
                  items: [
                    for (final b in draft.barangays)
                      DropdownMenuItem(value: b.code, child: Text(b.name)),
                  ],
                  onChanged: (!canEdit || draft.cityCode == null)
                      ? null
                      : (v) {
                          setState(() {
                            draft.latitude = null;
                            draft.longitude = null;
                            draft.barangayCode = v;
                          });
                          _syncAddressFromDraft(addressController, draft);
                        },
                  validator: (v) {
                    final hasGps =
                        draft.latitude != null && draft.longitude != null;
                    if (hasGps) return null;
                    if ((v ?? '').trim().isEmpty) {
                      return 'Barangay is required.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    suffixIcon: draft.loadingBarangays
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: draft.street,
                  enabled: canEdit,
                  decoration: const InputDecoration(labelText: 'Street name'),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final hasGps =
                        draft.latitude != null && draft.longitude != null;
                    if (hasGps) return null;
                    if ((v ?? '').trim().isEmpty) {
                      return 'Street name is required.';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (draft.latitude != null || draft.longitude != null) {
                      setState(() {
                        draft.latitude = null;
                        draft.longitude = null;
                      });
                    }
                    _syncAddressFromDraft(addressController, draft);
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: addressController,
          enabled: canEdit,
          readOnly: true,
          decoration: InputDecoration(labelText: addressLabel),
          validator: (v) {
            final text = v?.trim() ?? '';
            if (text.isEmpty) return 'Location is required.';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleDetailsStep(AppStore store) {
    final canEdit = !_submitting && !store.isLoading;

    if (_role == AccountRole.admin) {
      return const Text('No additional details required.');
    }

    Widget filePickerField({
      required TextEditingController controller,
      required String label,
      bool required = true,
    }) {
      return TextFormField(
        controller: controller,
        enabled: canEdit,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.attach_file_rounded),
          suffixIcon: IconButton(
            onPressed: !canEdit ? null : () => _pickFileInto(controller),
            icon: const Icon(Icons.folder_open_rounded),
          ),
        ),
        onTap: !canEdit ? null : () => _pickFileInto(controller),
        validator: (v) {
          if (!required) return null;
          return (v == null || v.trim().isEmpty) ? 'Required.' : null;
        },
      );
    }

    if (_role == AccountRole.user) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLocationSection(
            addressLabel: 'Location / delivery address',
            addressController: _deliveryAddress,
            draft: _deliveryLocation,
            canEdit: canEdit,
          ),
          const SizedBox(height: 12),
          filePickerField(
            controller: _profilePhotoRef,
            label: 'Profile photo (optional)',
            required: false,
          ),
          const SizedBox(height: 12),
          FormField<DateTime>(
            validator: (_) => null,
            builder: (field) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Birthday (optional for loyalty perks)',
                  errorText: field.errorText,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _birthday == null
                            ? 'Select date'
                            : _birthday!.toIso8601String().substring(0, 10),
                      ),
                    ),
                    TextButton(
                      onPressed: !canEdit
                          ? null
                          : () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(1900),
                                lastDate: now,
                                initialDate: _birthday ??
                                    DateTime(now.year - 18, now.month, now.day),
                              );
                              if (!mounted) return;
                              if (picked == null) return;
                              setState(() => _birthday = picked);
                              field.didChange(picked);
                            },
                      child: const Text('Pick'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    }

    if (_role == AccountRole.seller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _storeName,
            enabled: canEdit,
            decoration: const InputDecoration(labelText: 'Store name'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Store name is required.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cuisineType,
            enabled: canEdit,
            decoration: const InputDecoration(labelText: 'Cuisine type'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Cuisine type is required.'
                : null,
          ),
          const SizedBox(height: 12),
          _buildLocationSection(
            addressLabel: 'Store address',
            addressController: _storeAddress,
            draft: _storeLocation,
            canEdit: canEdit,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _operatingHours,
            enabled: canEdit,
            focusNode: _operatingHoursFocus,
            decoration: const InputDecoration(labelText: 'Operating hours'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Operating hours are required.'
                : null,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('9am – 6pm'),
                selected: _operatingHours.text.trim() == '9am – 6pm',
                onSelected: !canEdit
                    ? null
                    : (_) => setState(() => _operatingHours.text = '9am – 6pm'),
              ),
              ChoiceChip(
                label: const Text('10am – 10pm'),
                selected: _operatingHours.text.trim() == '10am – 10pm',
                onSelected: !canEdit
                    ? null
                    : (_) =>
                        setState(() => _operatingHours.text = '10am – 10pm'),
              ),
              ChoiceChip(
                label: const Text('24/7'),
                selected: _operatingHours.text.trim() == '24/7',
                onSelected: !canEdit
                    ? null
                    : (_) => setState(() => _operatingHours.text = '24/7'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: !canEdit
                ? null
                : () {
                    setState(() => _operatingHours.text = '');
                    FocusScope.of(context).requestFocus(_operatingHoursFocus);
                  },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Custom operating hours'),
          ),
          const SizedBox(height: 16),
          filePickerField(
            controller: _storeLogoRef,
            label: 'Upload: store logo',
          ),
          const SizedBox(height: 12),
          filePickerField(
            controller: _businessPermitRef,
            label: 'Upload: business permit',
          ),
          const SizedBox(height: 12),
          filePickerField(controller: _ownerIdRef, label: 'Upload: owner ID'),
        ],
      );
    }

    // Rider
    final fullName = _fullName().trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: fullName,
          enabled: false,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _riderNameConfirmed,
          onChanged: !canEdit
              ? null
              : (v) => setState(() => _riderNameConfirmed = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text('I confirm my full name is correct'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('vehicle_${_vehicleType ?? 'none'}'),
          initialValue: _vehicleType,
          items: const [
            DropdownMenuItem(value: 'Motorcycle', child: Text('Motorcycle')),
            DropdownMenuItem(value: 'Bicycle', child: Text('Bicycle')),
            DropdownMenuItem(value: 'Car', child: Text('Car')),
          ],
          onChanged: canEdit ? (v) => setState(() => _vehicleType = v) : null,
          validator: (v) => (v == null || v.isEmpty)
              ? 'Vehicle type is required.'
              : null,
          decoration: const InputDecoration(labelText: 'Vehicle type'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _plateNumber,
          enabled: canEdit,
          decoration: const InputDecoration(labelText: 'Plate number'),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Plate number is required.'
              : null,
        ),
        const SizedBox(height: 16),
        filePickerField(
          controller: _driversLicenseRef,
          label: "Upload: driver's license",
        ),
        const SizedBox(height: 12),
        filePickerField(
          controller: _vehicleRegistrationRef,
          label: 'Upload: vehicle registration photo',
        ),
      ],
    );
  }

  Widget _buildWelcomeStep() {
    final scheme = Theme.of(context).colorScheme;

    final ({String title, String subtitle, String cta, IconData icon}) copy =
        switch (_role) {
      AccountRole.user => (
          title: 'Welcome to Food Hub',
          subtitle: 'Your account is ready to go.',
          cta: 'Start exploring',
          icon: Icons.explore_rounded,
        ),
      AccountRole.seller => (
          title: 'Under review',
          subtitle: 'We\'ll email you within 24–48 hrs once approved.',
          cta: 'Set up your store',
          icon: Icons.storefront_rounded,
        ),
      AccountRole.rider => (
          title: 'Under review',
          subtitle: 'We\'ll email you within 24–48 hrs once approved.',
          cta: 'Go online',
          icon: Icons.delivery_dining_rounded,
        ),
      AccountRole.admin => (
          title: 'Welcome',
          subtitle: '',
          cta: 'Continue',
          icon: Icons.verified_rounded,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withAlpha(16),
                border: Border.all(color: scheme.outline),
              ),
              child: Icon(copy.icon, size: 38, color: scheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          copy.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 28,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          copy.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(copy.cta),
        ),
      ],
    );
  }

  Widget _buildBody(AppStore store) {
    return switch (_stepIndex) {
      0 => _buildBasicsStep(store),
      1 => _buildAccountTypeStep(store),
      2 => _buildRoleDetailsStep(store),
      _ => _buildWelcomeStep(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return AuthScaffold(
      heroTitle: 'Food Hub',
      heroSubtitle: 'Fresh, fast, and familiar — your community food hub.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepHeader(),
            const SizedBox(height: 16),
            _buildBody(store),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: (_submitting || store.isLoading) ? null : _back,
                  child: Text(_stepIndex == 0 ? 'Cancel' : 'Back'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: (_submitting || store.isLoading)
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          await _next(store);
                        },
                  child: Text(
                    switch (_stepIndex) {
                      0 => _awaitingEmailOtp ? 'Verify' : 'Send code',
                      2 => 'Continue',
                      3 => 'Done',
                      _ => 'Continue',
                    },
                  ),
                ),
              ],
            ),
            if (_submitting || store.isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (!_canUseSupabase(store) && _stepIndex <= 2) ...[
              const SizedBox(height: 12),
              Text(
                'Supabase is not configured for this build.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
