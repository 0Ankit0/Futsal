import 'package:flutter/material.dart';
import '../../core/dimension.dart';
import '../profile/data/repository/profile_repository.dart';
import 'forgot_password.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int _passwordStrength(String value) {
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    return score; // 0-3
  }

  Color _strengthColor(int s, BuildContext context) {
    switch (s) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.amber;
      case 3:
        return Theme.of(context).primaryColor;
      default:
        return Colors.red;
    }
  }

  String _strengthLabel(int s) {
    switch (s) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Strong';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final repo = ProfileRepository();
      await repo.changePassword(
        oldPassword: _oldController.text.trim(),
        newPassword: _newController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _passwordRules(String? value, {bool isConfirm = false}) {
    if (value == null || value.isEmpty) return 'Required';
    if (!isConfirm) {
      if (value.length < 8) return 'Min 8 characters';
      if (!RegExp(r'[a-z]').hasMatch(value)) return 'Need lowercase letter';
      if (!RegExp(r'[0-9]').hasMatch(value)) return 'Need a digit';
    } else {
      if (value != _newController.text) return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    final strength = _passwordStrength(_newController.text);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            Text(
              'Change Password',
              style: TextStyle(
                fontSize: Dimension.font(18),
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Dimension.width(16),
              Dimension.height(16),
              Dimension.width(16),
              Dimension.height(100),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldCard(
                    child: _PasswordField(
                      label: 'Old Password',
                      controller: _oldController,
                      obscure: _obscureOld,
                      toggle: () => setState(() => _obscureOld = !_obscureOld),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      icon: Icons.lock_clock,
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimension.width(8),
                          vertical: Dimension.height(4),
                        ),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: Dimension.font(12),
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                  _FieldCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PasswordField(
                          label: 'New Password',
                          controller: _newController,
                          obscure: _obscureNew,
                          toggle: () =>
                              setState(() => _obscureNew = !_obscureNew),
                          validator: _passwordRules,
                          icon: Icons.lock_outline,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: Dimension.height(12)),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  minHeight: Dimension.height(8),
                                  value: strength / 3,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation(
                                    _strengthColor(strength, context),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: Dimension.width(12)),
                            Text(
                              _strengthLabel(strength),
                              style: TextStyle(
                                fontSize: Dimension.font(12),
                                fontWeight: FontWeight.w400,
                                color: _strengthColor(strength, context),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Dimension.height(14)),
                        _RuleChecklist(password: _newController.text),
                      ],
                    ),
                  ),
                  SizedBox(height: Dimension.height(16)),
                  _FieldCard(
                    child: _PasswordField(
                      label: 'Confirm New Password',
                      controller: _confirmController,
                      obscure: _obscureConfirm,
                      toggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) => _passwordRules(v, isConfirm: true),
                      icon: Icons.lock_reset,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(Dimension.width(16)),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, Dimension.height(52)),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimension.width(14)),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                        width: Dimension.width(22),
                        height: Dimension.width(22),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: Dimension.font(16),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final Widget child;
  const _FieldCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimension.width(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimension.width(16)),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback toggle;
  final String? Function(String?) validator;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.toggle,
    required this.validator,
    required this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }
}

class _RuleChecklist extends StatelessWidget {
  final String password;
  const _RuleChecklist({required this.password});
  @override
  Widget build(BuildContext context) {
    final rules = [
      _RuleItem(label: 'Minimum 8 characters', satisfied: password.length >= 8),
      _RuleItem(
        label: 'Contains lowercase letter',
        satisfied: RegExp(r'[a-z]').hasMatch(password),
      ),
      _RuleItem(
        label: 'Contains digit',
        satisfied: RegExp(r'[0-9]').hasMatch(password),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements',
          style: TextStyle(
            fontSize: Dimension.font(12),
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: Dimension.height(8)),
        ...rules.map(
          (r) => Padding(
            padding: EdgeInsets.only(bottom: Dimension.height(6)),
            child: Row(
              children: [
                Icon(
                  r.satisfied
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: Dimension.width(16),
                  color: r.satisfied
                      ? Theme.of(context).primaryColor
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                ),
                SizedBox(width: Dimension.width(8)),
                Expanded(
                  child: Text(
                    r.label,
                    style: TextStyle(
                      fontSize: Dimension.font(12),
                      color: r.satisfied
                          ? Theme.of(context).primaryColor
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleItem {
  final String label;
  final bool satisfied;
  _RuleItem({required this.label, required this.satisfied});
}
