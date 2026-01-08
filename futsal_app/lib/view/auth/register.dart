import 'package:flutter/material.dart';
import 'package:ui/core/app_theme.dart';
import 'package:ui/view/auth/login.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import '../../core/dimension.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStage = 0;

  // Form keys for each stage
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextStage() {
    bool isValid = false;

    switch (_currentStage) {
      case 0:
        isValid = _emailFormKey.currentState?.validate() ?? false;
        break;
      case 1:
        isValid = _passwordFormKey.currentState?.validate() ?? false;
        break;
      case 2:
        isValid = _phoneFormKey.currentState?.validate() ?? false;
        break;
    }

    if (isValid) {
      if (_currentStage < 2) {
        setState(() {
          _currentStage++;
        });
        _pageController.animateToPage(
          _currentStage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _completeRegistration();
      }
    }
  }

  void _previousStage() {
    if (_currentStage > 0) {
      setState(() {
        _currentStage--;
      });
      _pageController.animateToPage(
        _currentStage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeRegistration() {
    // Handle registration completion
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Registration Complete!')));
    // Navigate to next screen or perform registration logic
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Register',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: Dimension.font(18),
          ),
        ),
        leading: _currentStage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _previousStage,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: EdgeInsets.all(Dimension.width(16)),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: Dimension.width(4),
                      ),
                      height: Dimension.height(3),
                      decoration: BoxDecoration(
                        color: index <= _currentStage
                            ? AppTheme.primaryDark
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(Dimension.width(2)),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Stage Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildEmailStage(),
                  _buildPasswordStage(),
                  _buildPhoneStage(),
                ],
              ),
            ),
            // Sign In Link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(
                      fontSize: Dimension.font(14),
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimension.width(8),
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: Dimension.font(14),
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primary,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Dimension.height(8)),
            // Next Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimension.width(16)),
              child: SizedBox(
                width: double.infinity,
                height: Dimension.height(54),
                child: ElevatedButton(
                  onPressed: _nextStage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimension.width(12)),
                    ),
                  ),
                  child: Text(
                    _currentStage < 2 ? 'Next' : 'Complete Registration',
                    style: TextStyle(
                      fontSize: Dimension.font(16),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: Dimension.height(16)),
            // Google Sign-In Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimension.width(16)),
              child: SizedBox(
                width: double.infinity,
                height: Dimension.height(52),
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Dispatch Google login event via Bloc
                    // You may need to wrap RegisterScreen with BlocProvider if not already done
                    // (Assuming AuthBloc is available in context)
                    context.read<AuthBloc>().add(
                      const LoginWithGoogleRequested(),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.grey[300]!,
                      width: Dimension.width(1.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimension.width(14)),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  icon: Icon(
                    Icons.g_mobiledata,
                    color: Colors.grey[800],
                    size: Dimension.width(28),
                  ),
                  label: Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: Dimension.font(15),
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimension.width(24)),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Dimension.height(20)),
            Text(
              'STEP 1 OF 3',
              style: TextStyle(
                fontSize: Dimension.font(12),
                color: Colors.black,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: Dimension.height(16)),
            Text(
              'What\'s your\nemail?',
              style: TextStyle(
                fontSize: Dimension.font(32),
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                height: 1.2,
              ),
            ),
            SizedBox(height: Dimension.height(12)),
            Text(
              'We\'ll use this to keep your account secure',
              style: TextStyle(
                fontSize: Dimension.font(15),
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: Dimension.height(48)),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                fontSize: Dimension.font(16),
                color: Colors.black,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Dimension.font(14),
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelStyle: TextStyle(
                  color: Colors.black,
                  fontSize: Dimension.font(14),
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'your.email@example.com',
                hintStyle: TextStyle(
                  color: Colors.grey[350],
                  fontSize: Dimension.font(15),
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.only(right: Dimension.width(12)),
                  child: Icon(
                    Icons.email_outlined,
                    color: Colors.grey[600],
                    size: Dimension.width(22),
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimension.width(20),
                  vertical: Dimension.height(18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: Dimension.width(2.5),
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[700]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: Dimension.width(2.5),
                  ),
                ),
                errorStyle: TextStyle(
                  color: Colors.grey[800],
                  fontSize: Dimension.font(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimension.width(24)),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Dimension.height(20)),
            Text(
              'STEP 2 OF 3',
              style: TextStyle(
                fontSize: Dimension.font(12),
                color: Colors.black,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: Dimension.height(16)),
            Text(
              'Create a\npassword',
              style: TextStyle(
                fontSize: Dimension.font(32),
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                height: 1.2,
              ),
            ),
            SizedBox(height: Dimension.height(12)),
            Text(
              'Use at least 8 characters with a mix of letters and numbers',
              style: TextStyle(
                fontSize: Dimension.font(15),
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: Dimension.height(48)),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(
                fontSize: Dimension.font(16),
                color: Colors.black,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Dimension.font(14),
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelStyle: TextStyle(
                  color: Colors.black,
                  fontSize: Dimension.font(14),
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'Min. 8 characters',
                hintStyle: TextStyle(
                  color: Colors.grey[350],
                  fontSize: Dimension.font(15),
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.only(right: Dimension.width(12)),
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.grey[600],
                    size: Dimension.width(22),
                  ),
                ),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: Dimension.width(4)),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[600],
                      size: Dimension.width(22),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimension.width(20),
                  vertical: Dimension.height(18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: Dimension.width(2.5),
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[700]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: Dimension.width(2.5),
                  ),
                ),
                errorStyle: TextStyle(
                  color: Colors.grey[800],
                  fontSize: Dimension.font(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
                  return 'Password must contain letters and numbers';
                }
                return null;
              },
            ),
            SizedBox(height: Dimension.height(20)),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: TextStyle(
                fontSize: Dimension.font(16),
                color: Colors.black,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Dimension.font(14),
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelStyle: TextStyle(
                  color: Colors.black,
                  fontSize: Dimension.font(14),
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'Re-enter password',
                hintStyle: TextStyle(
                  color: Colors.grey[350],
                  fontSize: Dimension.font(15),
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.only(right: Dimension.width(12)),
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.grey[600],
                    size: Dimension.width(22),
                  ),
                ),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: Dimension.width(4)),
                  child: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[600],
                      size: Dimension.width(22),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimension.width(20),
                  vertical: Dimension.height(18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: Dimension.width(2.5),
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[700]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: Dimension.width(2.5),
                  ),
                ),
                errorStyle: TextStyle(
                  color: Colors.grey[800],
                  fontSize: Dimension.font(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimension.width(24)),
      child: Form(
        key: _phoneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Dimension.height(20)),
            Text(
              'STEP 3 OF 3',
              style: TextStyle(
                fontSize: Dimension.font(12),
                color: Colors.black,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: Dimension.height(16)),
            Text(
              'What\'s your\nphone number?',
              style: TextStyle(
                fontSize: Dimension.font(32),
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                height: 1.2,
              ),
            ),
            SizedBox(height: Dimension.height(12)),
            Text(
              'We\'ll send you updates and verification codes',
              style: TextStyle(
                fontSize: Dimension.font(15),
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: Dimension.height(48)),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                fontSize: Dimension.font(16),
                color: Colors.black,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Dimension.font(14),
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelStyle: TextStyle(
                  color: Colors.black,
                  fontSize: Dimension.font(14),
                  fontWeight: FontWeight.w600,
                ),
                hintText: '555 123 4567',
                hintStyle: TextStyle(
                  color: Colors.grey[350],
                  fontSize: Dimension.font(15),
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.only(right: Dimension.width(12)),
                  child: Icon(
                    Icons.phone_outlined,
                    color: Colors.grey[600],
                    size: Dimension.width(22),
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimension.width(20),
                  vertical: Dimension.height(18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: Dimension.width(2.5),
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.grey[700]!,
                    width: Dimension.width(1.5),
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimension.width(14)),
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: Dimension.width(2.5),
                  ),
                ),
                errorStyle: TextStyle(
                  color: Colors.grey[800],
                  fontSize: Dimension.font(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            SizedBox(height: Dimension.height(48)),
            Container(
              padding: EdgeInsets.all(Dimension.width(18)),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(Dimension.width(12)),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Colors.grey[800],
                    size: Dimension.width(24),
                  ),
                  SizedBox(width: Dimension.width(14)),
                  Expanded(
                    child: Text(
                      'Your information is secure and will never be shared with third parties',
                      style: TextStyle(
                        fontSize: Dimension.font(13),
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
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
}
