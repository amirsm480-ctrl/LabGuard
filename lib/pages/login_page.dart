import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool busy = false;
  bool hidePassword = true;
  String message = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { busy = true; message = ''; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(), password: passwordController.text);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          message = error.code == 'network-request-failed'
            ? 'Check your internet connection.'
            : error.code == 'too-many-requests'
              ? 'Too many attempts. Please try again later.'
              : 'Login failed. Check your email and password.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => message = 'Unable to log in. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    if (!emailController.text.contains('@')) {
      setState(() => message = 'Enter your account email first.');
      return;
    }
    setState(() { busy = true; message = ''; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      if (mounted) {
        setState(() => message = 'If an account exists, password reset instructions will be emailed.');
      }
    } catch (_) {
      if (mounted) setState(() => message = 'Unable to request a password reset.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Safety Monitor')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.security, size: 60, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('Login', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  onFieldSubmitted: (_) { if (!busy) login(); },
                  decoration: InputDecoration(
                    labelText: 'Password', border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: hidePassword ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                      icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (value) => value != null && value.isNotEmpty ? null : 'Enter your password',
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: busy ? null : login,
                  child: Text(busy ? 'Please wait...' : 'Login')),
                TextButton(onPressed: busy ? null : resetPassword, child: const Text('Forgot password?')),
                if (message.isNotEmpty) Text(message, textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
