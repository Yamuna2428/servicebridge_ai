import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/customer_model.dart';
import '../models/worker_model.dart';

class SignUpScreen extends StatefulWidget {
  final String userType;

  const SignUpScreen({
    super.key,
    this.userType = 'User',
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _locationController = TextEditingController();

  // Worker specific controllers
  final _serviceController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    _serviceController.dispose();
    _experienceController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTER USER
  // ============================================================

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Create Firebase Authentication account
        final userCredential = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        final uid = userCredential.user!.uid;

        // ======================================================
        // WORKER REGISTRATION
        // ======================================================

        if (widget.userType == 'Worker') {
          final worker = WorkerModel(
            id: uid,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _mobileController.text.trim(),
            service: _serviceController.text.trim(),
            location: _locationController.text.trim(),
            rating: 0.0,
            reviews: 0,
            isAvailable: true,
            experience: _experienceController.text.trim(),
            experienceYears:
                int.tryParse(_experienceController.text.trim()) ?? 0,
            description: 'New professional joining ServiceBridge AI',
            skills: [
              _serviceController.text.trim(),
            ],
            createdAt: DateTime.now(),
          );

          await _firestoreService.saveUserProfile(
            uid,
            worker.toMap(),
          );
        }

        // ======================================================
        // CUSTOMER REGISTRATION
        // ======================================================

        else {
          final customer = CustomerModel(
            id: uid,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _mobileController.text.trim(),
            location: _locationController.text.trim(),
            createdAt: DateTime.now(),
          );

          await _firestoreService.saveUserProfile(
            uid,
            customer.toMap(),
          );
        }

        // ======================================================
        // REGISTRATION SUCCESS
        // ======================================================

        if (mounted) {
          setState(() => _isLoading = false);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registration Successful! Please Login.',
                ),
              ),
            );

            Navigator.of(context).pop();
          }
        }
      }

      // ========================================================
      // ERROR HANDLING
      // ========================================================

      catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,

      // IMPORTANT:
      // Allows the screen to resize when the keyboard opens.
      resizeToAvoidBottomInset: true,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.blue,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          // Allows scrolling even when content is almost
          // the same size as the screen.
          physics: const AlwaysScrollableScrollPhysics(),

          // Allows user to dismiss keyboard by dragging.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          child: Padding(
            // Standard horizontal padding for the form.
            // Added significant bottom padding (80) to ensure the 
            // Register button and Login link are fully reachable 
            // even with the system navigation bar or keyboard.
            padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 80.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Maximum width for larger screens.
                final double maxWidth =
                    constraints.maxWidth > 600 ? 500 : double.infinity;

                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ==================================================
                          // APP ICON
                          // ==================================================

                          const Center(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.handyman_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ==================================================
                          // TITLE
                          // ==================================================

                          Text(
                            'Sign Up as ${widget.userType}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ==================================================
                          // FULL NAME
                          // ==================================================

                          CustomTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ==================================================
                          // MOBILE NUMBER
                          // ==================================================

                          CustomTextField(
                            controller: _mobileController,
                            label: 'Mobile Number',
                            icon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.length < 10) {
                                return 'Enter a valid mobile number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ==================================================
                          // EMAIL
                          // ==================================================

                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email';
                              }

                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Enter a valid email';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ==================================================
                          // WORKER-SPECIFIC FIELDS
                          // ==================================================

                          if (widget.userType == 'Worker') ...[
                            // SERVICE / SKILL
                            CustomTextField(
                              controller: _serviceController,
                              label: 'Service/Skill (e.g. Plumber)',
                              icon: Icons.work_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your service';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // EXPERIENCE
                            CustomTextField(
                              controller: _experienceController,
                              label: 'Experience (Years)',
                              icon: Icons.history,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter experience';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),
                          ],

                          // ==================================================
                          // LOCATION
                          // ==================================================

                          CustomTextField(
                            controller: _locationController,
                            label: 'Location/City',
                            icon: Icons.location_on_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your location';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ==================================================
                          // PASSWORD
                          // ==================================================

                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be 6+ characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ==================================================
                          // CONFIRM PASSWORD
                          // ==================================================

                          CustomTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            icon: Icons.lock_reset_outlined,
                            obscureText: !_isConfirmPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.blue,
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

                          const SizedBox(height: 48),

                          // ==================================================
                          // REGISTER BUTTON
                          // ==================================================

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  // Loading indicator
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  // Register text
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // LOGIN LINK
                          // ==================================================

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
