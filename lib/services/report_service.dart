import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  final _db = FirebaseFirestore.instance;

  String _keyForName(String name) {
    final lower = name.trim().toLowerCase();
    final ascii = lower
        .replaceAll(RegExp(r'[çÇ]'), 'c')
        .replaceAll(RegExp(r'[ğĞ]'), 'g')
        .replaceAll(RegExp(r'[ıİ]'), 'i')
        .replaceAll(RegExp(r'[öÖ]'), 'o')
        .replaceAll(RegExp(r'[şŞ]'), 's')
        .replaceAll(RegExp(r'[üÜ]'), 'u');
    return ascii
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> submitIngredientReport({
    required String ingredientName,
    String? message,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Bildirimi göndermek için lütfen giriş yap.');

    final ingKey = _keyForName(ingredientName);
    final metaRef = _db.collection('users').doc(uid).collection('report_meta').doc(ingKey);
    final reports = _db.collection('ingredient_reports');
    final now = DateTime.now();

    await _db.runTransaction((tx) async {
      final metaSnap = await tx.get(metaRef);
      if (metaSnap.exists) {
        final last = metaSnap.data()?['lastSubmittedAt'];
        if (last is Timestamp) {
          final diffSec = now.difference(last.toDate()).inSeconds;
          if (diffSec < 120) {
            throw Exception('Bu malzeme için 2 dakika içinde tekrar bildirim gönderemezsin.');
          }
        }
      }

      final reportRef = reports.doc();
      tx.set(reportRef, {
        'ingredientName': ingredientName,
        'ingredientKey': ingKey,
        'message': (message ?? '').trim().isEmpty ? null : message!.trim(),
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      tx.set(metaRef, {
        'lastSubmittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}