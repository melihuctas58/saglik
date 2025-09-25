class Ingredient {
  final String id;
  final String slug;
  final Core core;
  final Identifiers identifiers;
  final Classification classification;
  final Risk risk;
  final Health health;
  final Allergen allergen;
  final Dietary dietary;
  final Usage usage;
  final Consumer consumer;
  final Regulatory regulatory;
  final List<Source> sources;

  Ingredient({
    required this.id,
    required this.slug,
    required this.core,
    required this.identifiers,
    required this.classification,
    required this.risk,
    required this.health,
    required this.allergen,
    required this.dietary,
    required this.usage,
    required this.consumer,
    required this.regulatory,
    required this.sources,
  });

  // ---- Helpers (esnek anahtar okuma + slugify) ----
  static String _firstString(Map json, List<String> keys, {String def = ''}) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return def;
  }

  static int _firstInt(Map json, List<String> keys, {int def = 0}) {
    for (final k in keys) {
      final v = json[k];
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) {
        final p = int.tryParse(v);
        if (p != null) return p;
      }
    }
    return def;
  }

  static bool _firstBool(Map json, List<String> keys, {bool def = false}) {
    for (final k in keys) {
      final v = json[k];
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'true' || s == 'yes' || s == '1' || s == 'evet') return true;
        if (s == 'false' || s == 'no' || s == '0' || s == 'hayir' || s == 'hayır') return false;
      }
      if (v is num) return v != 0;
    }
    return def;
  }

  static List<String> _asStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.map((e) => e.toString()).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return const [];
      if (s.contains(',')) {
        return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [s];
    }
    return const [];
  }

  static Map<String, dynamic> _asMap(dynamic v, String field) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    throw FormatException('$field Map değil: ${v.runtimeType}');
  }

  static String _slugify(String s) {
    var x = s.trim().toLowerCase();
    x = x
        .replaceAll(RegExp(r'[çÇ]'), 'c')
        .replaceAll(RegExp(r'[ğĞ]'), 'g')
        .replaceAll(RegExp(r'[ıİ]'), 'i')
        .replaceAll(RegExp(r'[öÖ]'), 'o')
        .replaceAll(RegExp(r'[şŞ]'), 's')
        .replaceAll(RegExp(r'[üÜ]'), 'u');
    x = x.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'-+'), '-');
    x = x.replaceAll(RegExp(r'^-|-$'), '');
    return x;
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    // Core’u önce oku
    final coreMap = _asMap(json['core'] ?? json['Core'] ?? json['CORE'] ?? {}, 'core');
    final core = Core.fromJson(coreMap);

    // id / slug esnek okuma
    var id = _firstString(json, ['id', '_id', 'uuid']);
    var slug = _firstString(json, ['slug', 'key', 'code']);

    if (id.isEmpty && slug.isNotEmpty) id = slug;
    if (slug.isEmpty && id.isNotEmpty) slug = id;
    if (id.isEmpty && core.primaryName.isNotEmpty) id = core.primaryName;
    if (slug.isEmpty && core.primaryName.isNotEmpty) slug = _slugify(core.primaryName);

    if (id.isEmpty && slug.isEmpty) {
      if (core.primaryName.isNotEmpty) {
        id = core.primaryName;
        slug = _slugify(core.primaryName);
      } else {
        throw const FormatException('id/slug/core.primaryName hiçbiri yok');
      }
    }

    final identifiers = (json['identifiers'] is Map)
        ? Identifiers.fromJson(json['identifiers'] as Map)
        : Identifiers.empty();

    final classification = (json['classification'] is Map)
        ? Classification.fromJson(json['classification'] as Map)
        : Classification.empty();

    // risk esnek
    final riskMap = _asMap(json['risk'] ?? json['Risk'] ?? json['RISK'] ?? {}, 'risk');
    final risk = Risk.fromJson(riskMap);

    final health = (json['health'] is Map) ? Health.fromJson(json['health']) : Health.empty();
    final allergen = (json['allergen'] is Map) ? Allergen.fromJson(json['allergen']) : Allergen.empty();
    final dietary = (json['dietary'] is Map) ? Dietary.fromJson(json['dietary']) : Dietary.empty();
    final usage = (json['usage'] is Map) ? Usage.fromJson(json['usage']) : Usage.empty();
    final consumer = (json['consumer'] is Map) ? Consumer.fromJson(json['consumer']) : Consumer.empty();
    final regulatory = (json['regulatory'] is Map) ? Regulatory.fromJson(json['regulatory']) : Regulatory.empty();

    final sources = (json['sources'] is List)
        ? (json['sources'] as List)
            .where((e) => e is Map)
            .map((e) => Source.fromJson((e as Map).cast<String, dynamic>()))
            .toList()
        : <Source>[];

    return Ingredient(
      id: id,
      slug: slug,
      core: core,
      identifiers: identifiers,
      classification: classification,
      risk: risk,
      health: health,
      allergen: allergen,
      dietary: dietary,
      usage: usage,
      consumer: consumer,
      regulatory: regulatory,
      sources: sources,
    );
  }
}

class Core {
  final String primaryName;
  final Map<String, dynamic> names;
  final String category;
  final String subcategory;
  final String shortSummary;
  final String userFriendlySummary;
  final String iconHint;
  Core({
    required this.primaryName,
    required this.names,
    required this.category,
    required this.subcategory,
    required this.shortSummary,
    required this.userFriendlySummary,
    required this.iconHint,
  });
  factory Core.fromJson(Map<String, dynamic> json) => Core(
        primaryName: Ingredient._firstString(
          json,
          ['primary_name', 'primaryName', 'name', 'title', 'label'],
        ),
        names: (json['names'] is Map) ? json['names'] as Map<String, dynamic> : <String, dynamic>{},
        category: Ingredient._firstString(json, ['category', 'category_name']),
        subcategory: Ingredient._firstString(json, ['subcategory', 'sub_category', 'subCategory']),
        shortSummary: Ingredient._firstString(json, ['short_summary', 'summary', 'shortSummary']),
        userFriendlySummary: Ingredient._firstString(
          json,
          ['user_friendly_summary', 'description', 'desc', 'long_summary', 'longSummary'],
        ),
        iconHint: Ingredient._firstString(json, ['icon_hint', 'iconHint', 'icon']),
      );
}

class Identifiers {
  final String? eNumber;
  Identifiers({this.eNumber});
  factory Identifiers.fromJson(Map json) =>
      Identifiers(eNumber: Ingredient._firstString(json.cast<String, dynamic>(), ['e_number', 'eNumber', 'e-code', 'ecode', 'eCode'], def: '').isEmpty
          ? null
          : Ingredient._firstString(json.cast<String, dynamic>(), ['e_number', 'eNumber', 'e-code', 'ecode', 'eCode']));
  factory Identifiers.empty() => Identifiers();
}

class Classification {
  final bool isAdditive;
  final String originType;
  Classification({required this.isAdditive, required this.originType});
  factory Classification.fromJson(Map json) => Classification(
        isAdditive: Ingredient._firstBool(json.cast<String, dynamic>(), ['is_additive', 'isAdditive', 'additive']),
        originType: Ingredient._firstString(json.cast<String, dynamic>(), ['origin_type', 'originType', 'origin', 'source'], def: 'bilinmiyor'),
      );
  factory Classification.empty() =>
      Classification(isAdditive: false, originType: 'bilinmiyor');
}

class Risk {
  final int riskScore;                 // 0..1000
  final String riskLevel;              // green/yellow/red
  final String labelColor;
  final List<dynamic> riskFactors;     // String veya Map destekler
  final String riskExplanation;
  Risk({
    required this.riskScore,
    required this.riskLevel,
    required this.labelColor,
    required this.riskFactors,
    required this.riskExplanation,
  });
  factory Risk.fromJson(Map<String, dynamic> json) => Risk(
        riskScore: Ingredient._firstInt(json, ['risk_score', 'score', 'riskScore'], def: 0),
        riskLevel: Ingredient._firstString(json, ['risk_level', 'level', 'riskLevel'], def: 'green'),
        labelColor: Ingredient._firstString(
          json,
          ['label_color', 'color', 'labelColor'],
          def: Ingredient._firstString(json, ['risk_level', 'level', 'riskLevel'], def: 'green'),
        ),
        riskFactors: (json['risk_factors'] is List)
            ? (json['risk_factors'] as List).map((e) {
                if (e is Map) return e.cast<String, dynamic>();
                return e.toString();
              }).toList()
            : <dynamic>[],
        riskExplanation: Ingredient._firstString(json, ['risk_explanation', 'explanation', 'note']),
      );
}

class Health {
  final List<String> healthFlags;
  final List<MythFact> claims; // claims burada MythFact değil ama sade bırakıyoruz
  final String safetyNotes;
  Health({
    required this.healthFlags,
    required this.claims,
    required this.safetyNotes,
  });
  factory Health.fromJson(Map json) => Health(
        healthFlags: (json['health_flags'] is List)
            ? (json['health_flags'] as List).map((e) => e.toString()).toList()
            : <String>[],
        claims: const [], // sade
        safetyNotes: (json['safety_notes'] ?? '').toString(),
      );
  factory Health.empty() => Health(healthFlags: const [], claims: const [], safetyNotes: '');
}

class Allergen {
  final List<String> allergenFlags;
  final String note;
  Allergen({required this.allergenFlags, required this.note});
  factory Allergen.fromJson(Map json) => Allergen(
        allergenFlags: (json['allergen_flags'] is List)
            ? (json['allergen_flags'] as List).map((e) => e.toString()).toList()
            : <String>[],
        note: (json['note'] ?? '').toString(),
      );
  factory Allergen.empty() => Allergen(allergenFlags: const [], note: '');
}

class Dietary {
  final bool vegan;
  final bool vegetarian;
  final String halal;
  final bool kosher;
  final bool glutenFree;
  final bool lactoseFree;
  Dietary({
    required this.vegan,
    required this.vegetarian,
    required this.halal,
    required this.kosher,
    required this.glutenFree,
    required this.lactoseFree,
  });
  factory Dietary.fromJson(Map json) => Dietary(
        vegan: json['vegan'] == true,
        vegetarian: json['vegetarian'] == true,
        halal: (json['halal'] ?? '').toString(),
        kosher: json['kosher'] == true,
        glutenFree: json['gluten_free'] == true,
        lactoseFree: json['lactose_free'] == true,
      );
  factory Dietary.empty() => Dietary(
        vegan: false,
        vegetarian: false,
        halal: '',
        kosher: false,
        glutenFree: false,
        lactoseFree: false,
      );
}

class Usage {
  final List<String> whereUsed;
  final List<String> commonRoles;
  Usage({required this.whereUsed, required this.commonRoles});
  factory Usage.fromJson(Map json) => Usage(
        whereUsed: (json['where_used'] is List)
            ? (json['where_used'] as List).map((e) => e.toString()).toList()
            : <String>[],
        commonRoles: (json['common_roles'] is List)
            ? (json['common_roles'] as List).map((e) => e.toString()).toList()
            : <String>[],
      );
  factory Usage.empty() => Usage(whereUsed: const [], commonRoles: const []);
}

class Consumer {
  final List<MythFact> myths;
  final List<String> labelNamesAlt;
  Consumer({required this.myths, required this.labelNamesAlt});
  factory Consumer.fromJson(Map json) => Consumer(
        myths: (json['myths'] is List)
            ? (json['myths'] as List)
                .whereType<Map>()
                .map(MythFact.fromJson)
                .toList()
            : <MythFact>[],
        labelNamesAlt: (json['label_names_alt'] is List)
            ? (json['label_names_alt'] as List).map((e) => e.toString()).toList()
            : <String>[],
      );
  factory Consumer.empty() => Consumer(myths: const [], labelNamesAlt: const []);
}

class MythFact {
  final String myth;
  final String fact;
  MythFact({required this.myth, required this.fact});
  factory MythFact.fromJson(Map json) =>
      MythFact(myth: (json['myth'] ?? '').toString(), fact: (json['fact'] ?? '').toString());
}

class Regulatory {
  final String trStatus;
  final String euStatus;
  final String usStatus;
  final num? adiMgPerKgBw;
  Regulatory({
    required this.trStatus,
    required this.euStatus,
    required this.usStatus,
    required this.adiMgPerKgBw,
  });
  factory Regulatory.fromJson(Map json) => Regulatory(
        trStatus: (json['tr_status'] ?? '').toString(),
        euStatus: (json['eu_status'] ?? '').toString(),
        usStatus: (json['us_status'] ?? '').toString(),
        adiMgPerKgBw: json['adi_mg_per_kg_bw'],
      );
  factory Regulatory.empty() =>
      Regulatory(trStatus: '', euStatus: '', usStatus: '', adiMgPerKgBw: null);
}

class Source {
  final String name;
  final String? url;
  final String? note;
  Source({required this.name, this.url, this.note});
  factory Source.fromJson(Map json) => Source(
        name: (json['name'] ?? '').toString(),
        url: json['url']?.toString(),
        note: json['note']?.toString(),
      );
}