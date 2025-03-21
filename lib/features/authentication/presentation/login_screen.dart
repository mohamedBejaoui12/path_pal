import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/shared/widgets/loading_overlay.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';
import '../../../shared/widgets/custom_text_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(authProvider.notifier).login(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        final authState = ref.read(authProvider);

        switch (authState.status) {
          case AuthStatus.authenticated:
            context.go('/');
            break;
          case AuthStatus.emailUnverified:
            context.go('/verify-email', extra: authState.user?.email);
            break;
          case AuthStatus.unauthenticated:
            setState(() {
              _errorMessage = 'Login failed. Please check your credentials.';
            });
            break;
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Login failed: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode
    final isDarkMode = ref.watch(themeProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: 'Logging in...',
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDarkMode ? Colors.grey[900]! : AppColors.primaryColor,
                isDarkMode ? Colors.grey[850]! : AppColors.backgroundColor
              ],
              stops: const [0.3, 0.3],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(
                  isDarkMode ? Colors.grey[800]! : AppColors.primaryColor,
                  isDarkMode ? Colors.grey[600]! : AppColors.secondaryColor),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[850]
                        : AppColors.backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isDarkMode ? Colors.black : AppColors.primaryColor)
                                .withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: (isDarkMode
                                        ? Colors.redAccent
                                        : AppColors.primaryColor)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: isDarkMode
                                          ? Colors.redAccent
                                          : AppColors.primaryColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.redAccent
                                            : AppColors.primaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Theme(
                            data: Theme.of(context).copyWith(
                              textTheme: Theme.of(context).textTheme.apply(
                                    bodyColor: Colors.black,
                                    displayColor: Colors.black,
                                  ),
                            ),
                            child: CustomTextFormField(
                              controller: _emailController,
                              labelText: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!EmailValidator.validate(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Theme(
                            data: Theme.of(context).copyWith(
                              textTheme: Theme.of(context).textTheme.apply(
                                    bodyColor: Colors.black,
                                    displayColor: Colors.black,
                                  ),
                            ),
                            child: CustomTextFormField(
                              controller: _passwordController,
                              labelText: 'Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: !_isPasswordVisible,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
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
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? Colors.blueGrey[700]
                                    : AppColors.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                                shadowColor: isDarkMode
                                    ? Colors.blueGrey[700]!.withOpacity(0.3)
                                    : AppColors.primaryColor.withOpacity(0.3),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => context.go('/signup'),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.blue[300]!
                                      : AppColors.primaryColor,
                                  fontSize: 14,
                                ),
                                children: const [
                                  TextSpan(text: 'New here? '),
                                  TextSpan(
                                    text: 'Create an account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildFooter(isDarkMode
                              ? Colors.blue[300]!
                              : AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      child: Column(
        children: [
          Text(
            'Aslama',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
              shadows: const [
                Shadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Taste of Tunisia',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 2,
            width: 100,
            color: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color primaryColor) {
    final isDarkMode = ref.watch(themeProvider);
    final textColor =
        isDarkMode ? Colors.grey[400]! : primaryColor.withOpacity(0.8);
    final linkColor = isDarkMode ? Colors.blue[300]! : primaryColor;

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          const Divider(height: 30),
          Text(
            'By continuing, you agree to our',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => context.go('/terms'),
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('•', style: TextStyle(color: Colors.grey)),
              ),
              GestureDetector(
                onTap: () => context.go('/privacy'),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('•', style: TextStyle(color: Colors.grey)),
              ),
              GestureDetector(
                onTap: () => context.go('/contact'),
                child: Text(
                  'Contact Us',
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '© 2024 Tunisian Traditions. All rights reserved',
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
