<<<<<<< HEAD
//lib/screens/forgetpassword.dart
=======
>>>>>>> 53f304c196b69b67df568d758e51ad9b92d61f99
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = true;
  int _secondsRemaining = 0;
  Timer? _resendTimer;

  void _startCooldown() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _canResend = true;
          _resendTimer?.cancel();
        }
      });
    });
  }

  void _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
        _startCooldown();
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Failed to send email')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Reset Password"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/JourneyMate_Logo.png',
                  height: 140,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enter your email to receive a password reset link.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || !value.contains('@') ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading || !_canResend ? null : _sendResetEmail,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_canResend
                      ? 'Send Reset Email'
                      : 'Resend in $_secondsRemaining s'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
