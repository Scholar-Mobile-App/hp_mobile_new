import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0E7FF), // Light blue
              Color(0xFFF8FAFC), // Very light grey/blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Floating background shapes
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F172A).withOpacity(0.1),
                      const Color(0xFF1E2A78).withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.08),
                      const Color(0xFF8B5CF6).withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Back arrow
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF0F172A),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'Reset Password',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We'll send you a secure reset link",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Glassmorphism Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                                  hintText: 'Enter your email',
                                  hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.7),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F172A),
                                      width: 1.5,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              // Send Reset Link Button
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6A00), Color(0xFFFF8C42)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6A00).withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                   onPressed: _isLoading
                                       ? null
                                       : () async {
                                           if (_formKey.currentState!.validate()) {
                                             setState(() {
                                               _isLoading = true;
                                             });
                                             try {
                                               final apiService = ApiService();
                                               await apiService.forgotPassword(_emailController.text);
                                               setState(() {
                                                 _isLoading = false;
                                               });
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 SnackBar(
                                                   content: Text('Reset link sent to your email'),
                                                   backgroundColor: const Color(0xFF059669),
                                                   behavior: SnackBarBehavior.floating,
                                                   shape: RoundedRectangleBorder(
                                                     borderRadius: BorderRadius.circular(12),
                                                   ),
                                                   margin: const EdgeInsets.all(16),
                                                 ),
                                               );
                                               // Navigate back after success
                                               Future.delayed(const Duration(seconds: 2), () {
                                                 Navigator.pop(context);
                                               });
                                             } catch (e) {
                                               setState(() {
                                                 _isLoading = false;
                                               });
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 SnackBar(
                                                   content: Text('Failed to send reset email: ${e.toString()}'),
                                                   backgroundColor: const Color(0xFFDC2626),
                                                   behavior: SnackBarBehavior.floating,
                                                   shape: RoundedRectangleBorder(
                                                     borderRadius: BorderRadius.circular(12),
                                                   ),
                                                   margin: const EdgeInsets.all(16),
                                                 ),
                                               );
                                             }
                                           }
                                         },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          'Send Reset Link',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Back to Login link
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Back to Login',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}