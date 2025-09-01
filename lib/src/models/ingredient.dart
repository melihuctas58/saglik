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

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    // Zorunlu alan kontrolleri
    if (json['id'] == null) throw FormatException('id yok');
    if (json['slug'] == null) throw FormatException('slug yok');
    if (json['core'] == null) throw FormatException('core yok');
    if (json['risk'] == null) throw FormatException('risk yok');

    final coreMap = _asMap(json['core'], 'core');
    final riskMap = _asMap(json['risk'], 'risk');

    return Ingredient(
      id: json['id'].toString(),
      slug: json['slug'].toString(),
      core: Core.fromJson(coreMap),
      identifiers: (json['identifiers'] is Map)
          ? Identifiers.fromJson(json['identifiers'])
          : Identifiers.empty(),
      classification: (json['classification'] is Map)
          ? Classification.fromJson(json['classification'])
          : Classification.empty(),
      risk: Risk.fromJson(riskMap),
      health: (json['health'] is Map)
          ? Health.fromJson(json['health'])
          : Health.empty(),
      allergen: (json['allergen'] is Map)
          ? Allergen.fromJson(json['allergen'])
          : Allergen.empty(),
      dietary: (json['dietary'] is Map)
          ? Dietary.fromJson(json['dietary'])
          : Dietary.empty(),
      usage: (json['usage'] is Map)
          ? Usage.fromJson(json['usage'])
          : Usage.empty(),
      consumer: (json['consumer'] is Map)
          ? Consumer.fromJson(json['consumer'])
          : Consumer.empty(),
      regulatory: (json['regulatory'] is Map)
          ? Regulatory.fromJson(json['regulatory'])
          : Regulatory.empty(),
      sources: (json['sources'] is List)
          ? (json['sources'] as List)
              .whereType<Map>()
              .map(Source.fromJson)
              .toList()
          : <Source>[],
    );
  }

  static Map<String, dynamic> _asMap(dynamic val, String field) {
    if (val is Map<String, dynamic>) return val;
    throw FormatException('$field beklenen Map ama: ${val.runtimeType}');
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

  factory Core.fromJson(Map<String, dynamic> json) {
    return Core(
      primaryName: (json['primary_name'] ?? '').toString(),
      names: (json['names'] is Map) ? json['names'] : <String, dynamic>{},
      category: (json['category'] ?? '').toString(),
      subcategory: (json['subcategory'] ?? '').toString(),
      shortSummary: (json['short_summary'] ?? '').toString(),
      userFriendlySummary: (json['user_friendly_summary'] ?? '').toString(),
      iconHint: (json['icon_hint'] ?? '').toString(),
    );
  }
}

class Identifiers {
  final String? eNumber;
  Identifiers({this.eNumber});
  factory Identifiers.fromJson(Map json) =>
      Identifiers(eNumber: (json['e_number']?.toString()));
  factory Identifiers.empty() => Identifiers(eNumber: null);
}

class Classification {
  final bool isAdditive;
  final String originType;
  Classification({required this.isAdditive, required this.originType});
  factory Classification.fromJson(Map json) => Classification(
        isAdditive: json['is_additive'] == true,
        originType: (json['origin_type'] ?? 'bilinmiyor').toString(),
      );
  factory Classification.empty() =>
      Classification(isAdditive: false, originType: 'bilinmiyor');
}

class Risk {
  final int riskScore;
  final String riskLevel;
  final String labelColor;
  final List<String> riskFactors;
  final String riskExplanation;
  Risk({
    required this.riskScore,
    required this.riskLevel,
    required this.labelColor,
    required this.riskFactors,
    required this.riskExplanation,
  });
  factory Risk.fromJson(Map<String, dynamic> json) => Risk(
        riskScore: _toInt(json['risk_score'], 0),
        riskLevel: (json['risk_level'] ?? 'green').toString(),
        labelColor: (json['label_color'] ?? (json['risk_level'] ?? 'green'))
            .toString(),
        riskFactors:
            (json['risk_factors'] is List)
                ? (json['risk_factors'] as List)
                    .map((e) => e.toString())
                    .toList()
                : <String>[],
        riskExplanation: (json['risk_explanation'] ?? '').toString(),
      );
  static int _toInt(dynamic v, int def) {
    if (v is int) return v;
    if (v is String) {
      final p = int.tryParse(v);
      return p ?? def;
    }
    return def;
  }
}

class Health {
  final List<String> healthFlags;
  final List<Claim> claims;
  final String safetyNotes;
  Health({
    required this.healthFlags,
    required this.claims,
    required this.safetyNotes,
  });
  factory Health.fromJson(Map json) => Health(
        healthFlags: (json['health_flags'] is List)
            ? (json['health_flags'] as List)
                .map((e) => e.toString())
                .toList()
            : <String>[],
        claims: (json['claims'] is List)
            ? (json['claims'] as List)
                .whereType<Map>()
                .map(Claim.fromJson)
                .toList()
            : <Claim>[],
        safetyNotes: (json['safety_notes'] ?? '').toString(),
      );
  factory Health.empty() =>
      Health(healthFlags: const [], claims: const [], safetyNotes: '');
}

class Claim {
  final String text;
  final bool authorized;
  final String authority;
  final String evidenceLevel;
  final String note;
  Claim({
    required this.text,
    required this.authorized,
    required this.authority,
    required this.evidenceLevel,
    required this.note,
  });
  factory Claim.fromJson(Map json) => Claim(
        text: (json['text'] ?? '').toString(),
        authorized: json['authorized'] == true,
        authority: (json['authority'] ?? '').toString(),
        evidenceLevel: (json['evidence_level'] ?? 'Moderate').toString(),
        note: (json['note'] ?? '').toString(),
      );
}

class Allergen {
  final List<String> allergenFlags;
  final String note;
  Allergen({required this.allergenFlags, required this.note});
  factory Allergen.fromJson(Map json) => Allergen(
        allergenFlags: (json['allergen_flags'] is List)
            ? (json['allergen_flags'] as List)
                .map((e) => e.toString())
                .toList()
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
        halal: (json['halal'] ?? 'bilinmiyor').toString(),
        kosher: json['kosher'] == true,
        glutenFree: json['gluten_free'] == true,
        lactoseFree: json['lactose_free'] == true,
      );
  factory Dietary.empty() => Dietary(
        vegan: false,
        vegetarian: false,
        halal: 'bilinmiyor',
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
            ? (json['label_names_alt'] as List)
                .map((e) => e.toString())
                .toList()
            : <String>[],
      );
  factory Consumer.empty() => Consumer(myths: const [], labelNamesAlt: const []);
}

class MythFact {
  final String myth;
  final String fact;
  MythFact({required this.myth, required this.fact});
  factory MythFact.fromJson(Map json) => MythFact(
        myth: (json['myth'] ?? '').toString(),
        fact: (json['fact'] ?? '').toString(),
      );
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