import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeContext {
  const EmployeeContext({
    required this.uid,
    required this.companyId,
    required this.displayName,
  });

  final String uid;
  final String companyId;
  final String displayName;
}

class AttendanceQrPayload {
  const AttendanceQrPayload({
    required this.companyId,
    required this.locationId,
    required this.qrToken,
  });

  final String companyId;
  final String locationId;
  final String qrToken;
}

class AttendanceService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  static Future<EmployeeContext> loadEmployeeContext() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'You must be logged in.',
      );
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? const <String, dynamic>{};

    final companyId = (data['company_id'] as String?)?.trim() ?? '';
    final firstName = (data['first_name'] as String?)?.trim() ?? '';
    final lastName = (data['last_name'] as String?)?.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();

    if (companyId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-company',
        message: 'No company assigned to this account.',
      );
    }

    return EmployeeContext(
      uid: user.uid,
      companyId: companyId,
      displayName: fullName.isEmpty ? user.email ?? 'Employee' : fullName,
    );
  }

  static AttendanceQrPayload? parseAttendanceQr(String value) {
    if (!value.startsWith('AE_ATTEND:')) return null;
    final rawPayload = value.substring('AE_ATTEND:'.length).trim();
    if (rawPayload.isEmpty) return null;

    try {
      final decoded = Uri.decodeComponent(rawPayload);
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final companyId = map['companyId'] as String?;
      final locationId = map['locationId'] as String?;
      final qrToken = map['qrToken'] as String?;
      if (companyId == null || locationId == null || qrToken == null) {
        return null;
      }
      return AttendanceQrPayload(
        companyId: companyId,
        locationId: locationId,
        qrToken: qrToken,
      );
    } catch (_) {
      return null;
    }
  }

  static Query<Map<String, dynamic>> attendanceQuery(EmployeeContext ctx) {
    return _db
        .collection('companies')
        .doc(ctx.companyId)
        .collection('attendance')
        .where('user_id', isEqualTo: ctx.uid);
  }

  static Future<void> checkIn({
    required AttendanceQrPayload payload,
    required double latitude,
    required double longitude,
    required double accuracyM,
    required bool isMockLocation,
  }) async {
    final callable = _functions.httpsCallable('checkIn');
    await callable.call(<String, dynamic>{
      'companyId': payload.companyId,
      'locationId': payload.locationId,
      'qrToken': payload.qrToken,
      'latitude': latitude,
      'longitude': longitude,
      'accuracyM': accuracyM,
      'isMockLocation': isMockLocation,
    });
  }

  static Future<void> checkOut({required String companyId}) async {
    final callable = _functions.httpsCallable('checkOut');
    await callable.call(<String, dynamic>{'companyId': companyId});
  }
}

DateTime? asDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
