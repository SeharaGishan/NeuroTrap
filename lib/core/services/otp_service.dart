import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  // ── EmailJS credentials ───────────────────────────────────────────────────
  static const String _serviceId = 'neuro_2026';
  static const String _templateId = 'neuro_temp';
  static const String _publicKey = 'kx1endTR1TAZKuv36';
  static const String _emailJsUrl =
      'https://api.emailjs.com/api/v1.0/email/send';

  // ── Firebase Realtime Database reference ──────────────────────────────────
  final DatabaseReference _db = FirebaseDatabase.instance.ref('otp');

  // ── Generate a random 4-digit OTP ─────────────────────────────────────────
  String _generateOtp() {
    final random = Random.secure();
    return (1000 + random.nextInt(9000)).toString();
  }

  // ── Send OTP — main method called from Sign In / Sign Up ──────────────────
  // Returns true if sent successfully, false otherwise
  Future<bool> sendOtp({
    required String uid,
    required String email,
    required String username,
  }) async {
    try {
      // 1 — Generate code
      final otp = _generateOtp();
      final expiry = DateTime.now().millisecondsSinceEpoch + (5 * 60 * 1000);
      final sentTime = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

      // 2 — Store in Firebase Realtime Database
      await _db.child(uid).set({
        'code': otp,
        'expiry': expiry,
        'verified': false,
        'email': email,
      });

      // 3 — Send via EmailJS
      final response = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_name': username,
            'to_email': email,
            'otp_code': otp,
            'sent_time': sentTime,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Verify OTP entered by user ─────────────────────────────────────────────
  // Returns OtpResult enum
  Future<OtpResult> verifyOtp({
    required String uid,
    required String enteredCode,
  }) async {
    try {
      final snapshot = await _db.child(uid).get();

      if (!snapshot.exists) return OtpResult.invalid;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final storedCode = data['code'] as String? ?? '';
      final expiry = data['expiry'] as int? ?? 0;
      final alreadyVerified = data['verified'] as bool? ?? false;

      if (alreadyVerified) return OtpResult.alreadyVerified;

      // Check expiry
      if (DateTime.now().millisecondsSinceEpoch > expiry) {
        return OtpResult.expired;
      }

      // Check code
      if (enteredCode.trim() != storedCode) {
        return OtpResult.wrong;
      }

      // Mark as verified in database
      await _db.child(uid).update({'verified': true});

      return OtpResult.success;
    } catch (e) {
      return OtpResult.error;
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────
  Future<bool> resendOtp({
    required String uid,
    required String email,
    required String username,
  }) async {
    // Delete old code first
    await _db.child(uid).remove();
    // Send new one
    return sendOtp(uid: uid, email: email, username: username);
  }

  // ── Clean up OTP record after successful verification ──────────────────────
  Future<void> clearOtp(String uid) async {
    await _db.child(uid).remove();
  }
}

// ── Result enum ───────────────────────────────────────────────────────────────
enum OtpResult {
  success,
  wrong,
  expired,
  invalid,
  alreadyVerified,
  error,
}

extension OtpResultMessage on OtpResult {
  String get message {
    switch (this) {
      case OtpResult.success:
        return 'Verified successfully';
      case OtpResult.wrong:
        return 'Incorrect code. Please try again.';
      case OtpResult.expired:
        return 'Code expired. Please request a new one.';
      case OtpResult.invalid:
        return 'No code found. Please request a new one.';
      case OtpResult.alreadyVerified:
        return 'Already verified.';
      case OtpResult.error:
        return 'An error occurred. Please try again.';
    }
  }
}