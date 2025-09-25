import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudScanHistory {
  CloudScanHistory._();
  static final CloudScanHistory instance = CloudScanHistory._();

  final _db = FirebaseFirestore.instance;

  Future<void> addScan({
    required List<String> ingredientNames,
    String? imageUrl,
    String? rawText,
    DateTime? localTime,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = _db.collection('users').doc(uid).collection('scans').doc();
    await ref.set({
      'timestamp': FieldValue.serverTimestamp(),
      'localTime': (localTime ?? DateTime.now()).toIso8601String(),
      'ingredients': ingredientNames,
      'imageUrl': imageUrl,
      'rawText': rawText,
    });
  }

  // KULLANICIYA GÖRE TÜM KAYITLARI TEK SEFERDE GETİR
  Future<List<CloudScan>> fetchAllOnce() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return CloudScan(
        id: d.id,
        ingredients: List<String>.from(data['ingredients'] ?? const []),
        imageUrl: data['imageUrl'] as String?,
        rawText: data['rawText'] as String?,
        // timestamp null olabilir; localTime string’i her zaman var
        localTime: DateTime.tryParse((data['localTime'] as String?) ?? ''),
      );
    }).toList();
  }

  // İstersen ekranda canlı dinlemek için stream:
  Stream<List<Map<String, dynamic>>> streamScans() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> deleteScan(String scanId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('scans').doc(scanId).delete();
  }
}

class CloudScan {
  final String id;
  final List<String> ingredients; // isim listesi
  final String? imageUrl;
  final String? rawText;
  final DateTime? localTime;
  CloudScan({
    required this.id,
    required this.ingredients,
    this.imageUrl,
    this.rawText,
    this.localTime,
  });
}