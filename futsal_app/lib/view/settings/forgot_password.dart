import 'package:flutter/material.dart';
import '../../core/dimension.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      // TODO: Implement forgot password request via existing repository/service
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset link sent (placeholder)')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Dimension.width(16)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your account email to receive a password reset link.',
                style: TextStyle(
                  fontSize: Dimension.font(13),
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: Dimension.height(16)),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                    return 'Invalid email';
                  }
                  return null;
                },
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: Dimension.height(24)),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, Dimension.height(50)),
                ),
                child: _loading
                    ? SizedBox(
                        width: Dimension.width(22),
                        height: Dimension.width(22),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Reset Link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
