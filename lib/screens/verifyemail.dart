import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isVerifying = false;
  bool _canResend = true;
  int _resendCooldown = 30;
  Timer? _cooldownTimer;

  late final Map<String, dynamic> userData;
  User? _user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _canResend = false;
      _resendCooldown = 30;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _resendCooldown--);
      if (_resendCooldown == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _checkEmailVerifiedAndSaveData() async {
    setState(() => _isVerifying = true);
    await _user?.reload();
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null && _user!.emailVerified) {
      // Save data to Firestore after email verification
      await FirebaseFirestore.instance.collection("JourneyMate").doc(_user!.uid).set({
        "name": userData['name'],
        "username": userData['username'],
        "email": userData['email'],
        "phone": userData['phone'],
        "bio": "Hi, I am New Here!",
        "isVerified": true,
        "joinedAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),
        "photoUrl": "",
        "role": "user",
        "location": {
          "City": "",
          "State": "",
          "country": "",
        },
        "preferences": {
          "language": "en",
          "notifications": true,
          "theme": "dark",
          "units": "km"
        }
      });

      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Email verified. Please login again.")),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Email not verified yet.")),
      );
    }
    setState(() => _isVerifying = false);
  }

  Future<void> _resendVerification() async {
    try {
      await _user?.sendEmailVerification();
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📧 Verification email resent.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/JourneyMate_Logo.png',
                  height: 100,
                ),
                const SizedBox(height: 20),
                Text(
                  "Verify Your Email",
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "We sent a verification email to your inbox. Please verify your email to activate your account.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  onPressed: _isVerifying ? null : _checkEmailVerifiedAndSaveData,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("I have verified"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _canResend ? _resendVerification : null,
                  child: Text(
                    _canResend ? "Resend Verification Email" : "Wait $_resendCooldown seconds",
                    style: TextStyle(color: theme.primaryColor),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
