import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/otp_service.dart';
import '../../core/services/firestore_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  final _otpService = OtpService();
  final _firestoreService = FirestoreService();

  // 4 controllers + focus nodes for OTP boxes
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(4, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  // Resend timer
  int _resendSeconds = 60;
  bool _canResend = false;
  Timer? _timer;

  // Route args
  late String _email;
  late String _username;
  late bool _isSignUp;
  late String _uid;

  // Entry animation
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();
    _startResendTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = args?['email'] ?? '';
    _username = args?['username'] ?? '';
    _isSignUp = args?['isSignUp'] ?? false;
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ── Get the 4-digit code from boxes ────────────────────────────────────────
  String get _enteredCode =>
      _controllers.map((c) => c.text).join();

  // ── Verify ─────────────────────────────────────────────────────────────────
  Future<void> _verify() async {
    if (_enteredCode.length < 4) {
      setState(() => _errorMessage = 'Please enter all 4 digits.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final result = await _otpService.verifyOtp(
      uid: _uid,
      enteredCode: _enteredCode,
    );

    if (!mounted) return;

    if (result == OtpResult.success) {
      // Mark verified in Firestore
      await _firestoreService.markEmailVerified(_uid);
      // Clean up OTP record
      await _otpService.clearOtp(_uid);

      setState(() => _successMessage = 'Verified! Redirecting...');

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        // Navigate to home — replace entire stack
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/vpn',
          (route) => false,
        );
      }
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = result.message;
        // Clear the boxes on wrong code
        if (result == OtpResult.wrong || result == OtpResult.expired) {
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        }
      });
    }
  }

  // ── Resend ─────────────────────────────────────────────────────────────────
  Future<void> _resend() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final sent = await _otpService.resendOtp(
      uid: _uid,
      email: _email,
      username: _username,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (sent) {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _startResendTimer();
    } else {
      setState(
          () => _errorMessage = 'Failed to resend. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background — same gradient as Sign In ──────────────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF005b84),
                  Color(0xFF003655),
                  Color(0xFF000d28),
                  Color(0xFF000319),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // ── Blurred background overlay ─────────────────────────────────
          // Simulates the "blur the sign in page" effect from Figma
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),

          // ── Verification popup card ────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                      vertical: 24,
                    ),
                    child: _buildPopupCard(size),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupCard(Size size) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Glass card — same style as sign in card
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.06,
          vertical: size.height * 0.035,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── VERIFICATION title ───────────────────────────────────────
            const Text(
              'VERIFICATION',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'KdamThmorPro',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),

            // Cyan underline
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 20),
              width: 48,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF00B3FF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Subtitle ─────────────────────────────────────────────────
            Text(
              "Check your registered Email's inbox for\nthe verification code",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'KdamThmorPro',
                fontSize: 12,
                color: Colors.white.withOpacity(0.55),
                height: 1.6,
              ),
            ),

            SizedBox(height: size.height * 0.04),

            // ── 4 OTP input boxes ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => _buildOtpBox(i)),
            ),

            SizedBox(height: size.height * 0.022),

            // ── Not received / Resend ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Not received yet : ',
                  style: TextStyle(
                    fontFamily: 'KdamThmorPro',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
                GestureDetector(
                  onTap: _canResend && !_isResending ? _resend : null,
                  child: _isResending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFFEF5350),
                          ),
                        )
                      : Text(
                          _canResend
                              ? 'Resend'
                              : 'Resend (${_resendSeconds}s)',
                          style: TextStyle(
                            fontFamily: 'KdamThmorPro',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _canResend
                                ? const Color(0xFFEF5350)
                                : Colors.white.withOpacity(0.30),
                          ),
                        ),
                ),
              ],
            ),

            // ── Error / Success messages ──────────────────────────────────
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'KdamThmorPro',
                  fontSize: 11,
                  color: Color(0xFFEF5350),
                ),
              ),
            ],

            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _successMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'KdamThmorPro',
                  fontSize: 11,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],

            SizedBox(height: size.height * 0.032),

            // ── Verify button ─────────────────────────────────────────────
            GestureDetector(
              onTap: _isVerifying ? null : _verify,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      const Color(0xFF1A4A6E).withOpacity(0.90),
                      const Color(0xFF010C24).withOpacity(0.77),
                      const Color(0xFF000510).withOpacity(0.90),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                  border: Border.all(
                    color: const Color(0xFF00B3FF),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B3FF).withOpacity(0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontFamily: 'KdamThmorPro',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            SizedBox(height: size.height * 0.025),

            // ── Back to Sign In link ──────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(
                context,
                _isSignUp ? '/sign-up' : '/sign-in',
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 12,
                    color: Colors.white.withOpacity(0.40),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isSignUp ? 'Back to Sign Up' : 'Back to Sign In',
                    style: TextStyle(
                      fontFamily: 'KdamThmorPro',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Single OTP input box ───────────────────────────────────────────────────
  Widget _buildOtpBox(int index) {
    return Container(
      width: 52,
      height: 58,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        // Same glass style as input fields
        color: const Color(0xFFD8D9DB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontFamily: 'KdamThmorPro',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D2840),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          setState(() => _errorMessage = null);
          if (value.isNotEmpty) {
            // Move to next box
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last box — auto verify
              _focusNodes[index].unfocus();
              _verify();
            }
          } else {
            // Move to previous box on delete
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }
}