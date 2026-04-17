import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class PhRegion {
  final String code;
  final String name;
  final String regionName;

  const PhRegion({
    required this.code,
    required this.name,
    required this.regionName,
  });

  factory PhRegion.fromJson(Map<String, dynamic> json) {
    return PhRegion(
      code: json['code'].toString(),
      name: json['name'].toString(),
      regionName: json['regionName'].toString(),
    );
  }

  String get label {
    final rn = regionName.trim();
    final n = name.trim();
    if (rn.isEmpty) return n;
    if (n.isEmpty) return rn;
    return '$rn — $n';
  }
}

class PhProvince {
  final String code;
  final String name;
  final String regionCode;

  const PhProvince({
    required this.code,
    required this.name,
    required this.regionCode,
  });

  factory PhProvince.fromJson(Map<String, dynamic> json) {
    return PhProvince(
      code: json['code'].toString(),
      name: json['name'].toString(),
      regionCode: json['regionCode'].toString(),
    );
  }
}

class PhCityMunicipality {
  final String code;
  final String name;
  final String regionCode;
  final String provinceCode;

  const PhCityMunicipality({
    required this.code,
    required this.name,
    required this.regionCode,
    required this.provinceCode,
  });

  factory PhCityMunicipality.fromJson(Map<String, dynamic> json) {
    return PhCityMunicipality(
      code: json['code'].toString(),
      name: json['name'].toString(),
      regionCode: json['regionCode'].toString(),
      provinceCode: json['provinceCode'].toString(),
    );
  }
}

class PhBarangay {
  final String code;
  final String name;

  const PhBarangay({required this.code, required this.name});

  factory PhBarangay.fromJson(Map<String, dynamic> json) {
    return PhBarangay(
      code: json['code'].toString(),
      name: json['name'].toString(),
    );
  }
}

/// Philippines address data backed by PSGC.
///
/// - Regions/Provinces/Cities are bundled offline via `psgc_picker` assets.
/// - Barangays are fetched on-demand from the public PSGC API.
class PhLocations {
  static const _regionsAsset =
      'packages/psgc_picker/lib/src/assets/region.json';
  static const _provincesAsset =
      'packages/psgc_picker/lib/src/assets/province.json';
  static const _citiesAsset = 'packages/psgc_picker/lib/src/assets/city.json';

  static Future<void>? _loadFuture;

  static List<PhRegion>? _regions;
  static List<PhProvince>? _provinces;
  static List<PhCityMunicipality>? _cities;

  static Object? _loadError;

  static Object? get loadError => _loadError;

  static bool get isLoaded =>
      _regions != null && _provinces != null && _cities != null;

  static Future<void> ensureLoaded({bool forceReload = false}) {
    if (forceReload) {
      _loadFuture = null;
      _regions = null;
      _provinces = null;
      _cities = null;
      _loadError = null;
    }
    return _loadFuture ??= _load();
  }

  static Future<void> _load() async {
    try {
      final regionsRaw = await rootBundle.loadString(_regionsAsset);
      final provincesRaw = await rootBundle.loadString(_provincesAsset);
      final citiesRaw = await rootBundle.loadString(_citiesAsset);

      final regionsJson = (jsonDecode(regionsRaw) as List)
          .cast<Map<String, dynamic>>();
      final provincesJson = (jsonDecode(provincesRaw) as List)
          .cast<Map<String, dynamic>>();
      final citiesJson = (jsonDecode(citiesRaw) as List)
          .cast<Map<String, dynamic>>();

      _regions = regionsJson.map(PhRegion.fromJson).toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      _provinces = provincesJson.map(PhProvince.fromJson).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _cities = citiesJson.map(PhCityMunicipality.fromJson).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _loadError = e;
      _loadFuture = null;
      rethrow;
    }
  }

  static List<PhRegion> get regions {
    return List.unmodifiable(_regions ?? const <PhRegion>[]);
  }

  static List<PhProvince> provincesForRegion(String regionCode) {
    final provinces = _provinces;
    if (provinces == null) return const <PhProvince>[];
    final filtered = provinces
        .where((p) => p.regionCode == regionCode)
        .toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  /// Returns cities/municipalities filtered by province code.
  ///
  /// For NCR (no provinces), this method is also compatible with passing the
  /// region code — it will match by `regionCode`.
  static List<PhCityMunicipality> citiesForProvinceOrRegion(
    String provinceOrRegionCode,
  ) {
    final cities = _cities;
    if (cities == null) return const <PhCityMunicipality>[];

    final filtered = cities
        .where(
          (c) =>
              c.provinceCode == provinceOrRegionCode ||
              c.regionCode == provinceOrRegionCode,
        )
        .toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  static PhRegion? regionByCode(String code) {
    final regions = _regions;
    if (regions == null) return null;
    for (final r in regions) {
      if (r.code == code) return r;
    }
    return null;
  }

  static PhProvince? provinceByCode(String code) {
    final provinces = _provinces;
    if (provinces == null) return null;
    for (final p in provinces) {
      if (p.code == code) return p;
    }
    return null;
  }

  static PhCityMunicipality? cityByCode(String code) {
    final cities = _cities;
    if (cities == null) return null;
    for (final c in cities) {
      if (c.code == code) return c;
    }
    return null;
  }
}

class PhBarangayApi {
  static const _base = 'https://psgc.gitlab.io/api';

  /// Fetch barangays for a given PSGC city/municipality code.
  static Future<List<PhBarangay>> fetchBarangays({
    required String cityOrMunicipalityCode,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse(
        '$_base/cities-municipalities/$cityOrMunicipalityCode/barangays/',
      );
      final resp = await httpClient.get(uri);
      if (resp.statusCode != 200) {
        throw StateError('Failed to load barangays (${resp.statusCode}).');
      }

      final data = jsonDecode(resp.body);
      if (data is! List) {
        throw const FormatException('Unexpected barangays response format.');
      }

      final barangays =
          data
              .whereType<Map<String, dynamic>>()
              .map(PhBarangay.fromJson)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      return barangays;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
