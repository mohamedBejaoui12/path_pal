import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/custom_text_form_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(authProvider.notifier).signup(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim());

        context.go('/verify-email', extra: _emailController.text.trim());
      } catch (e) {
        setState(() {
          _errorMessage = 'Signup failed: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildHeader(Color primaryColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      child: Column(
        children: [
          // const SizedBox(height: 25),
          Text(
            'Ahlan wa Sahlan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
              shadows: [
                const Shadow(
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

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: 'Creating account...',
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryColor, AppColors.backgroundColor],
              stops: const [0.3, 0.3],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(AppColors.primaryColor, AppColors.secondaryColor),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: AppColors.primaryColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: AppColors.primaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          CustomTextFormField(
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
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _passwordController,
                            labelText: 'Password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm Password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isConfirmPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                                shadowColor:
                                    AppColors.primaryColor.withOpacity(0.3),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(
                                    text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      context.go('/login');
                                    },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                color: AppColors.backgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  children: [
                    const Divider(height: 30, color: Colors.grey),
                    Text(
                      'By continuing, you agree to our',
                      style: TextStyle(
                        color: AppColors.primaryColor.withOpacity(0.8),
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
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child:
                              Text('•', style: TextStyle(color: Colors.grey)),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/privacy'),
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child:
                              Text('•', style: TextStyle(color: Colors.grey)),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/contact'),
                          child: Text(
                            'Contact Us',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ' 2024 Tunisian Traditions. All rights reserved',
                      style: TextStyle(
                        color: AppColors.primaryColor.withOpacity(0.6),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
