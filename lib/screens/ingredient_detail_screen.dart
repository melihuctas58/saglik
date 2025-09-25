import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../utils/risk_colors.dart';
import '../utils/risk_labels.dart';
import '../widgets/ui_components.dart';
import '../widgets/pretty_section.dart';
import '../widgets/risk_gauge.dart';
import '../utils/text_format.dart';
import '../services/report_service.dart';
import '../widgets/summary_renderer.dart';

class IngredientDetailScreen extends StatelessWidget {
  final dynamic ingredient;
  const IngredientDetailScreen({super.key, required this.ingredient});

  Ingredient? get ingSafe => ingredient is Ingredient ? ingredient as Ingredient : null;

  String get _safeName {
    try {
      final i = ingSafe;
      final n = (i?.core.primaryName ?? '').toString().trim();
      return n.isEmpty ? 'Detay' : n;
    } catch (_) {
      return 'Detay';
    }
  }

  String _safeStr(dynamic v) => (v ?? '').toString().trim();
  bool _safeBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) {
      final x = v.toLowerCase();
      return x == 'true' || x == 'yes' || x == 'evet' || x == '1' || x == 'helal' || x == 'halal';
    }
    return false;
  }
  int _safeInt(dynamic v) => v is int ? v : (v is double ? v.toInt() : (int.tryParse('$v') ?? 0));
  double _safeDouble(dynamic v) => v is double ? v : (v is int ? v.toDouble() : (double.tryParse('$v') ?? 0.0));
  List<String> _listStr(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => _safeStr(e)).where((s) => s.isNotEmpty).toList();
    if (v is String) return _safeStr(v).isEmpty ? const [] : [_safeStr(v)];
    return const [];
  }

  // Yeni skala
  String _levelFromScore(int? score) {
    if (score == null) return 'other';
    if (score >= 400) return 'red';
    if (score >= 250) return 'yellow';
    return 'green';
  }

  List<String> _dietBadges(bool vegan, bool vegetarian, bool glutenFree, bool lactoseFree, bool kosher, String halal) {
    final out = <String>[];
    if (vegan) {
      out.add('Vegan');
    } else if (vegetarian) {
      out.add('Vejetaryen');
    }
    if (_isHalalPositive(halal)) out.add('Helal');
    if (kosher) out.add('Kosher');
    if (glutenFree) out.add('Glutensiz');
    if (lactoseFree) out.add('Laktozsuz');
    return out;
  }

  Future<void> _openReportSheet(BuildContext context, String ingredientName) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final ctrl = TextEditingController();
        String? error;
        bool sending = false;

        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> _send() async {
              if (sending) return;
              setSheet(() { sending = true; error = null; });
              try {
                await ReportService.instance.submitIngredientReport(
                  ingredientName: ingredientName,
                  message: ctrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                setSheet(() {
                  error = e.toString().replaceFirst('Exception: ', '');
                });
              } finally {
                setSheet(() { sending = false; });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yanlış/Eksik Bilgi Bildir', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Malzeme: $ingredientName', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'İstersen kısaca notunu yaz...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 6),
                    Text(error!, style: TextStyle(color: cs.error)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: sending ? null : () => Navigator.pop(ctx, false),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: sending ? null : _send,
                          icon: sending
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send),
                          label: Text(sending ? 'Gönderiliyor...' : 'Gönder'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (success == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teşekkürler! Bildirimin alındı. En kısa sürede değerlendireceğiz.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = ingSafe;
    final cs = Theme.of(context).colorScheme;

    final score = _safeInt(i?.risk.riskScore);
    final riskColor = riskColorFromScore(score);
    final riskText = riskLabelFromScore(score);
    final riskLevelForGauge = _levelFromScore(score);

    final vegan = _safeBool(i?.dietary.vegan);
    final vegetarian = _safeBool(i?.dietary.vegetarian);
    final glutenFree = _safeBool(i?.dietary.glutenFree);
    final lactoseFree = _safeBool(i?.dietary.lactoseFree);
    final kosher = _safeBool(i?.dietary.kosher);
    final halal = _safeStr(i?.dietary.halal);

    final originType = _safeStr(i?.classification.originType).toLowerCase();
    final isPlantBased = originType == 'bitkisel' || originType.contains('plant');

    final dietBadges = _dietBadges(vegan, vegetarian, glutenFree, lactoseFree, kosher, halal);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: cs.surface,
            foregroundColor: cs.onSurface,
            pinned: true,
            expandedHeight: 200,
            actions: [
              IconButton(
                tooltip: 'Bildir',
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => _openReportSheet(context, _safeName),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
              title: Text(_safeName, maxLines: 1, overflow: TextOverflow.ellipsis),
              background: _HeaderDecor(
                gradient1: cs.primaryContainer,
                gradient2: cs.secondaryContainer,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            sliver: SliverList.list(children: [
              if (_safeStr(i?.core.shortSummary).isNotEmpty)
                CardBlock(
                  title: 'Özet',
                  child: Text(_safeStr(i?.core.shortSummary), style: const TextStyle(fontSize: 15)),
                ),

              CardBlock(
                title: 'Önemli Etiketler',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TinyPill(label: riskText, color: riskColor),
                    if (_safeBool(i?.classification.isAdditive)) const TinyPill(label: 'Katkı', color: Colors.indigo),
                    if (isPlantBased) const TinyPill(label: 'Bitkisel', color: Colors.teal),
                    if (_safeStr(i?.identifiers.eNumber).isNotEmpty)
                      TinyPill(label: 'E-${_safeStr(i?.identifiers.eNumber)}', color: Colors.brown),
                    for (final b in dietBadges) TinyPill(label: b, color: Colors.teal),
                  ],
                ),
              ),

              PrettySection(
                title: 'Risk',
                icon: Icons.health_and_safety_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiskGauge(score: score, level: riskLevelForGauge),
                    const SizedBox(height: 10),
                    MetricBar(
                      label: 'Risk Skoru',
                      value: _safeDouble(i?.risk.riskScore),
                      max: 1000,
                      color: riskColor,
                      suffix: '${_safeInt(i?.risk.riskScore)}/1000',
                    ),
                    const SizedBox(height: 10),
                    if (_safeStr(i?.risk.riskExplanation).isNotEmpty) Text(_safeStr(i?.risk.riskExplanation)),
                    const SizedBox(height: 10),
                    // Esnek risk_factors render
                    if ((i?.risk.riskFactors ?? []) is List && (i?.risk.riskFactors as List).isNotEmpty)
                      _riskFactorsBlock(i!.risk.riskFactors, cs),
                  ],
                ),
              ),

              if (_safeStr(i?.core.userFriendlySummary).isNotEmpty)
                PrettySection(
                  title: 'Detaylı Açıklama',
                  child: SummaryRenderer(text: _safeStr(i?.core.userFriendlySummary)),
                ),

              if (_listStr(i?.health.healthFlags).isNotEmpty || _safeStr(i?.health.safetyNotes).isNotEmpty)
                PrettySection(
                  title: 'Sağlık',
                  icon: Icons.favorite_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_listStr(i?.health.healthFlags).isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _listStr(i?.health.healthFlags).map((e) => TinyTag(prettifyLabel(e, titleCase: true))).toList(),
                        ),
                      if (_safeStr(i?.health.safetyNotes).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_safeStr(i?.health.safetyNotes)),
                      ],
                    ],
                  ),
                ),

              PrettySection(
                title: 'Diyet',
                icon: Icons.restaurant_outlined,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final b in dietBadges) TinyTag(b),
                  ],
                ),
              ),

              if (_listStr(i?.allergen.allergenFlags).isNotEmpty || _safeStr(i?.allergen.note).isNotEmpty)
                PrettySection(
                  title: 'Alerjen',
                  icon: Icons.warning_amber_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_listStr(i?.allergen.allergenFlags).isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _listStr(i?.allergen.allergenFlags).map((e) => TinyTag(prettifyLabel(e, titleCase: true))).toList(),
                        ),
                      if (_safeStr(i?.allergen.note).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_safeStr(i?.allergen.note)),
                      ],
                    ],
                  ),
                ),

              if (_listStr(i?.usage.whereUsed).isNotEmpty || _listStr(i?.usage.commonRoles).isNotEmpty)
                PrettySection(
                  title: 'Kullanım',
                  icon: Icons.tips_and_updates_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_listStr(i?.usage.whereUsed).isNotEmpty) ...[
                        const Text('Nerede Kullanılır?', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _listStr(i?.usage.whereUsed).map((e) => TinyTag(prettifyLabel(e, titleCase: true))).toList(),
                        ),
                      ],
                      if (_listStr(i?.usage.whereUsed).isNotEmpty && _listStr(i?.usage.commonRoles).isNotEmpty)
                        const SizedBox(height: 10),
                      if (_listStr(i?.usage.commonRoles).isNotEmpty) ...[
                        const Text('Roller', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _listStr(i?.usage.commonRoles).map((e) => TinyTag(prettifyLabel(e, titleCase: true))).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

              if (_safeStr(i?.regulatory.trStatus).isNotEmpty ||
                  _safeStr(i?.regulatory.euStatus).isNotEmpty ||
                  _safeStr(i?.regulatory.usStatus).isNotEmpty ||
                  i?.regulatory.adiMgPerKgBw != null)
                PrettySection(
                  title: 'Regülasyon',
                  icon: Icons.gavel_outlined,
                  child: Column(
                    children: [
                      KVRow(label: 'TR', value: _dashIfEmpty(_safeStr(i?.regulatory.trStatus))),
                      KVRow(label: 'EU', value: _dashIfEmpty(_safeStr(i?.regulatory.euStatus))),
                      KVRow(label: 'US', value: _dashIfEmpty(_safeStr(i?.regulatory.usStatus))),
                      KVRow(label: 'ADI (mg/kg bw)', value: (i?.regulatory.adiMgPerKgBw?.toString() ?? '-')),
                    ],
                  ),
                ),

              if (_listStr(i?.sources).isNotEmpty)
                PrettySection(
                  title: 'Kaynaklar',
                  icon: Icons.link_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _srcList(i?.sources)
                        .map((s) => SourceTile(name: s.name, url: s.url, note: s.note))
                        .toList(),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  bool _isHalalPositive(String v) {
    final x = v.toLowerCase();
    return x == 'helal' || x == 'halal' || x == 'yes' || x == 'true' || x == 'evet';
  }

  String _dashIfEmpty(String s) => s.isEmpty ? '-' : s;
}

// Risk faktörleri (string liste veya Map liste) için esnek render
Widget _riskFactorsBlock(dynamic listAny, ColorScheme cs) {
  if (listAny is! List || listAny.isEmpty) return const SizedBox.shrink();

  // Map ise: detaylı kartlar
  if (listAny.first is Map) {
    final items = listAny.cast<Map>();
    List<Widget> cards = [];

    String lab(String key) {
      switch (key) {
        case 'title':
          return 'Başlık';
        case 'condition':
          return 'Koşul';
        case 'groups_affected':
          return 'Etkilenen Gruplar';
        case 'mechanism':
          return 'Mekanizma';
        case 'evidence':
          return 'Kanıt';
        case 'mitigation':
          return 'Önlem';
        case 'score':
          return 'Skor';
        default:
          return key;
      }
    }

    for (final m in items) {
      final title = (m['title'] ?? '').toString().trim();
      final condition = (m['condition'] ?? '').toString().trim();
      final groups = m['groups_affected'];
      final mechanism = (m['mechanism'] ?? '').toString().trim();
      final evidence = (m['evidence'] ?? '').toString().trim();
      final mitigation = (m['mitigation'] ?? '').toString().trim();
      final score = (m['score'] ?? '').toString().trim();

      String groupsText = '';
      if (groups is List) {
        groupsText = groups.map((e) => e.toString()).where((e) => e.isNotEmpty).join(', ');
      } else if (groups != null) {
        groupsText = groups.toString();
      }

      Widget row(String key, String val) {
        if (val.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 130, child: Text(lab(key), style: TextStyle(color: cs.onSurfaceVariant))),
              const SizedBox(width: 6),
              Expanded(child: Text(val, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        );
      }

      cards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (title.isNotEmpty) const SizedBox(height: 6),
              row('condition', condition),
              row('groups_affected', groupsText),
              row('mechanism', mechanism),
              row('evidence', evidence),
              row('mitigation', mitigation),
              row('score', score),
            ],
          ),
        ),
      );
    }

    return Column(children: cards);
  }

  // String list: etiketler
  final items = listAny.cast<dynamic>().map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
  if (items.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: items.map((e) => TinyTag(prettifyLabel(e, titleCase: true))).toList(),
  );
}

class _HeaderDecor extends StatelessWidget {
  final Color gradient1;
  final Color gradient2;
  const _HeaderDecor({
    required this.gradient1,
    required this.gradient2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradient1, gradient2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _Src {
  final String name;
  final String? url;
  final String? note;
  _Src({required this.name, this.url, this.note});
}

List<_Src> _srcList(dynamic v) {
  final out = <_Src>[];
  if (v is List) {
    for (final e in v) {
      if (e is Map) {
        final name = (e['name'] ?? '').toString().trim();
        final url = (e['url'] ?? '').toString().trim();
        final note = (e['note'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          out.add(_Src(name: name, url: url.isEmpty ? null : url, note: note.isEmpty ? null : note));
        }
      } else {
        try {
          final dyn = e as dynamic;
          final name = (dyn.name ?? '').toString().trim();
          final url = (dyn.url ?? '').toString().trim();
          final note = (dyn.note ?? '').toString().trim();
          if (name.isNotEmpty) {
            out.add(_Src(name: name, url: url.isEmpty ? null : url, note: note.isEmpty ? null : note));
          }
        } catch (_) {}
      }
    }
  }
  return out;
}