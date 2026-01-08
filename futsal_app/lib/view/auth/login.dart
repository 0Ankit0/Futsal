import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/view/auth/register.dart';
import 'package:ui/view/profile/bloc/profile_bloc.dart';
import 'package:ui/view/profile/bloc/profile_event.dart';
import '../../core/dimension.dart';
import '../../core/app_theme.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import '../home/home.dart';
import '../home/bloc/all_futsal/all_futsal_bloc.dart';
import '../home/bloc/all_futsal/all_futsal_event.dart';
import '../home/bloc/trending_futsal/trending_futsal_bloc.dart';
import '../home/bloc/trending_futsal/trending_futsal_event.dart';
import '../home/bloc/top_reviewed_futsal/top_reviewed_futsal_bloc.dart';
import '../home/bloc/top_reviewed_futsal/top_reviewed_futsal_event.dart';
import '../favorite/bloc/favorite_bloc.dart';
import '../favorite/bloc/favorite_event.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      // Trigger login event
      context.read<AuthBloc>().add(
        LoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Preload all futsal data before navigating to home
          context.read<AllFutsalBloc>().add(const LoadAllFutsals());
          context.read<TrendingFutsalBloc>().add(const LoadTrendingFutsals());
          context.read<TopReviewedFutsalBloc>().add(
            const LoadTopReviewedFutsals(),
          );
          context.read<FavoriteBloc>().add(const LoadFavorites());
          context.read<ProfileBloc>().add(const LoadUserInfo());

          // Navigate to home on successful login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Home()),
          );
        } else if (state is AuthError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.all(Dimension.width(24)),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: Dimension.height(20)),
                            // Welcome Back Text
                            Text(
                              'Welcome\nback',
                              style: TextStyle(
                                fontSize: Dimension.font(40),
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: Dimension.height(8)),
                            Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: Dimension.font(16),
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: Dimension.height(30)),
                            // Email Fieldmail Field
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
                                  color: AppTheme.textSecondary,
                                  fontSize: Dimension.font(14),
                                  fontWeight: FontWeight.w500,
                                ),
                                floatingLabelStyle: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: Dimension.font(14),
                                  fontWeight: FontWeight.w600,
                                ),
                                hintText: 'your.email@example.com',
                                hintStyle: TextStyle(
                                  color: Colors.grey[350],
                                  fontSize: Dimension.font(15),
                                ),
                                prefixIcon: Container(
                                  margin: EdgeInsets.only(
                                    right: Dimension.width(12),
                                  ),
                                  child: Icon(
                                    Icons.email_outlined,
                                    color: AppTheme.textSecondary,
                                    size: Dimension.width(22),
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primary,
                                    width: 2.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey[700]!,
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primary,
                                    width: 2.5,
                                  ),
                                ),
                                errorStyle: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 12,
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
                            SizedBox(height: Dimension.height(16)),
                            // Password Field
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
                                  color: AppTheme.textSecondary,
                                  fontSize: Dimension.font(14),
                                  fontWeight: FontWeight.w500,
                                ),
                                floatingLabelStyle: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: Dimension.font(14),
                                  fontWeight: FontWeight.w600,
                                ),
                                hintText: 'Enter your password',
                                hintStyle: TextStyle(
                                  color: Colors.grey[350],
                                  fontSize: Dimension.font(15),
                                ),
                                prefixIcon: Container(
                                  margin: EdgeInsets.only(
                                    right: Dimension.width(12),
                                  ),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: AppTheme.textSecondary,
                                    size: Dimension.width(22),
                                  ),
                                ),
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(
                                    right: Dimension.width(4),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary,
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
                                  borderRadius: BorderRadius.circular(
                                    Dimension.width(14),
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: Dimension.width(1.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    Dimension.width(14),
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: Dimension.width(1.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    Dimension.width(14),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.primary,
                                    width: Dimension.width(2.5),
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    Dimension.width(14),
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.grey[700]!,
                                    width: Dimension.width(1.5),
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    Dimension.width(14),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.primary,
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
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: Dimension.height(12)),
                            // Remember Me and Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.9,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: AppTheme.primary,
                                        checkColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.grey[400]!,
                                          width: Dimension.width(1.5),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            Dimension.width(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: Dimension.font(14),
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Handle forgot password
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: Dimension.font(14),
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Dimension.height(24)),
                            // Login Button
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return SizedBox(
                                  width: double.infinity,
                                  height: Dimension.height(54),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: isLoading
                                          ? null
                                          : AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(
                                        Dimension.width(14),
                                      ),
                                      boxShadow: isLoading
                                          ? null
                                          : [AppTheme.buttonShadow],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isLoading
                                            ? Colors.grey[400]
                                            : Colors.transparent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            Dimension.width(14),
                                          ),
                                        ),
                                      ),
                                      child: isLoading
                                          ? SizedBox(
                                              height: Dimension.height(20),
                                              width: Dimension.height(20),
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                            )
                                          : Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: Dimension.font(16),
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: Dimension.height(20)),
                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Dimension.width(16),
                                  ),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      fontSize: Dimension.font(12),
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Dimension.height(16)),
                            // Social Login Buttons
                            SizedBox(
                              width: double.infinity,
                              height: Dimension.height(52),
                              child: OutlinedButton.icon(
                                onPressed: () {
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
                                    borderRadius: BorderRadius.circular(
                                      Dimension.width(14),
                                    ),
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
                            const Spacer(),
                            // Sign Up Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Don\'t have an account?',
                                    style: TextStyle(
                                      fontSize: Dimension.font(14),
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to register screen
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: Dimension.width(8),
                                      ),
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Sign Up',
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
                            SizedBox(height: Dimension.height(16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
