import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../app_routes.dart';

class LoginScreen extends StatefulWidget {
  final FirebaseService? firebaseService;
  const LoginScreen({super.key, this.firebaseService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'Student';
  bool _obscurePassword = true;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _emailError = '';
  String _passwordError = '';
  bool _isFormValid = false;
  bool _isLoading = false;
  late final FirebaseService _firebaseService;
  
  final List<_RoleItem> roles = [
    _RoleItem('Student', Colors.blue),
    _RoleItem('Committee Member', Colors.purple),
    _RoleItem('President', Colors.orange),
    _RoleItem('Treasurer', Colors.green),
    _RoleItem('Admin', Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    _firebaseService = widget.firebaseService ?? FirebaseService();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Field must be filled';
      } else if (!email.endsWith('@graduate.utm.my')) {
        _emailError = 'Email must be @graduate.utm.my';
      } else {
        _emailError = '';
      }
      _checkFormValidity();
    });
  }

  void _validatePassword() {
    setState(() {
      final password = _passwordController.text;
      if (password.isEmpty) {
        _passwordError = 'Field must be filled';
      } else {
        _passwordError = '';
      }
      _checkFormValidity();
    });
  }

  void _checkFormValidity() {
    setState(() {
      _isFormValid = _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _emailError.isEmpty &&
          _passwordError.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7ED56F), Color(0xFF54B36B)],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 28),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Image.asset(
                      'assets/ieee_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.school,
                        size: 72,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Workshop Wizard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2))
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0B1A3A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              'Select your role to access dashboard',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: const [
                              Icon(Icons.shield_outlined, color: Color(0xFF4CAF50)),
                              SizedBox(width: 8),
                              Text('Select Role', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: selectedRole,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF5F6F8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                            items: roles.map((r) {
                              return DropdownMenuItem<String>(
                                value: r.label,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(r.label),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => selectedRole = val);
                            },
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'UTM Email Address',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFF5F6F8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _emailError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                  width: _emailError.isNotEmpty ? 2 : 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _emailError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                  width: _emailError.isNotEmpty ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _emailError.isNotEmpty ? Colors.red : const Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4CAF50)),
                              errorText: _emailError.isNotEmpty ? _emailError : null,
                              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'App Password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFF5F6F8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _passwordError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                  width: _passwordError.isNotEmpty ? 2 : 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _passwordError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                  width: _passwordError.isNotEmpty ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _passwordError.isNotEmpty ? Colors.red : const Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4CAF50)),
                              errorText: _passwordError.isNotEmpty ? _passwordError : null,
                              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                child: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.forgotPassword);
                              },
                              child: const Text('Forgot Password?', style: TextStyle(color: Colors.blue, fontSize: 13)),
                            ),
                          ),
                          // Large rounded login button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFormValid && !_isLoading ? const Color(0xFF3FA34D) : Colors.grey[400],
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                              elevation: _isFormValid && !_isLoading ? 8 : 0,
                              shadowColor: Colors.black54,
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            onPressed: (_isFormValid && !_isLoading) ? () async {
                              setState(() => _isLoading = true);
                              
                              final result = await _firebaseService.login(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              );

                              if (!mounted) return;
                              setState(() => _isLoading = false);

                              if (result['success']) {
                                if (!context.mounted) return;
                                
                                // NEW: Verify the Role against the Database
                                final user = result['user'];
                                final actualRole = await _firebaseService.getUserRole(user.uid);
                                
                                if (!context.mounted) return;
                                
                                // If Data Connect is enabled and we found a role, verify it
                                if (actualRole != null && actualRole != selectedRole) {
                                  await _firebaseService.signOut();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Access Denied: You are registered as $actualRole, not $selectedRole.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  setState(() => _isLoading = false);
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
                                );
                                
                                // ROLE-BASED ROUTING
                                if (selectedRole == 'Committee Member') {
                                  Navigator.pushReplacementNamed(context, AppRoutes.committeeHome);
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context, 
                                    AppRoutes.dashboard,
                                    arguments: selectedRole,
                                  );
                                }
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
                                );
                              }
                            } : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text('Login as $selectedRole', style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text("Don't have an account? "),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, AppRoutes.createAccount);
                                  },
                                  child: const Text('Create an account', style: TextStyle(decoration: TextDecoration.underline)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleItem {
  final String label;
  final Color color;
  const _RoleItem(this.label, this.color);
}

class ForgotPasswordScreen extends StatefulWidget {
  final FirebaseService? firebaseService;
  const ForgotPasswordScreen({super.key, this.firebaseService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  String _emailError = '';
  bool _isEmailValid = false;
  bool _isLoading = false;
  late final FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    _firebaseService = widget.firebaseService ?? FirebaseService();
    _emailController = TextEditingController();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Field must be filled';
        _isEmailValid = false;
      } else if (!email.endsWith('@graduate.utm.my')) {
        _emailError = 'Email must be @graduate.utm.my';
        _isEmailValid = false;
      } else {
        _emailError = '';
        _isEmailValid = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7ED56F), Color(0xFF54B36B)],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'FORGOT\nPASSWORD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF4CAF50),
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                size: 40,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Center(
                            child: Text(
                              'Trouble Logging in?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0B1A3A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              "Check your email and we'll send you a link to reset your password.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFF5F6F8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _emailError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                  width: _emailError.isNotEmpty ? 2 : 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _emailError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                  width: _emailError.isNotEmpty ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _emailError.isNotEmpty ? Colors.red : const Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              errorText: _emailError.isNotEmpty ? _emailError : null,
                              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_isEmailValid && !_isLoading) ? const Color(0xFF3FA34D) : Colors.grey[400],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                              elevation: (_isEmailValid && !_isLoading) ? 8 : 0,
                              shadowColor: Colors.black54,
                            ),
                            onPressed: (_isEmailValid && !_isLoading) ? () async {
                              setState(() => _isLoading = true);

                              final result = await _firebaseService.resetPassword(
                                email: _emailController.text.trim(),
                              );

                              if (!mounted) return;
                              setState(() => _isLoading = false);

                              if (result['success']) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Account created successfully! Please log in.'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                Navigator.pop(context); // Return to login
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
                                );
                              }
                            } : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Reset Password',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Return to Login Page',
                                style: TextStyle(
                                  color: Color(0xFF3FA34D),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  final FirebaseService? firebaseService;
  const CreateAccountScreen({super.key, this.firebaseService});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _passwordController;
  late TextEditingController _repeatPasswordController;
  
  String _emailError = '';
  String _fullNameError = '';
  String _passwordError = '';
  String _repeatPasswordError = '';
  bool _isFormValid = false;
  bool _isLoading = false;
  late final FirebaseService _firebaseService;

  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;

  @override
  void initState() {
    super.initState();
    _firebaseService = widget.firebaseService ?? FirebaseService();
    _emailController = TextEditingController();
    _fullNameController = TextEditingController();
    _passwordController = TextEditingController();
    _repeatPasswordController = TextEditingController();

    _emailController.addListener(_validateForm);
    _fullNameController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _repeatPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Field must be filled';
      } else if (!email.endsWith('@graduate.utm.my')) {
        _emailError = 'Email must be @graduate.utm.my';
      } else {
        _emailError = '';
      }

      if (_fullNameController.text.isEmpty) {
        _fullNameError = 'Field must be filled';
      } else {
        _fullNameError = '';
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'Field must be filled';
      } else {
        _passwordError = '';
      }

      if (_repeatPasswordController.text.isEmpty) {
        _repeatPasswordError = 'Field must be filled';
      } else if (_repeatPasswordController.text != _passwordController.text) {
        _repeatPasswordError = 'Passwords do not match';
      } else {
        _repeatPasswordError = '';
      }

      _isFormValid = _emailError.isEmpty &&
          _fullNameError.isEmpty &&
          _passwordError.isEmpty &&
          _repeatPasswordError.isEmpty &&
          _emailController.text.isNotEmpty &&
          _fullNameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _repeatPasswordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7ED56F), Color(0xFF54B36B)],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'CREATE YOUR\nACCOUNT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email (@graduate.utm.my)',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFF5F6F8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _emailError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                  width: _emailError.isNotEmpty ? 2 : 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _emailError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                  width: _emailError.isNotEmpty ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _emailError.isNotEmpty ? Colors.red : const Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              errorText: _emailError.isNotEmpty ? _emailError : null,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFF5F6F8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _fullNameError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _fullNameError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _fullNameError.isNotEmpty ? Colors.red : const Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              errorText: _fullNameError.isNotEmpty ? _fullNameError : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFF5F6F8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _passwordError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _passwordError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _passwordError.isNotEmpty ? Colors.red : const Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              errorText: _passwordError.isNotEmpty ? _passwordError : null,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _repeatPasswordController,
                            obscureText: _obscureRepeatPassword,
                            decoration: InputDecoration(
                              hintText: 'Repeat Password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFF5F6F8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _repeatPasswordError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _repeatPasswordError.isNotEmpty ? Colors.red : Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: _repeatPasswordError.isNotEmpty ? Colors.red : const Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              errorText: _repeatPasswordError.isNotEmpty ? _repeatPasswordError : null,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _obscureRepeatPassword = !_obscureRepeatPassword),
                                child: Icon(
                                  _obscureRepeatPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_isFormValid && !_isLoading) ? const Color(0xFF3FA34D) : Colors.grey[400],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                              elevation: (_isFormValid && !_isLoading) ? 8 : 0,
                              shadowColor: Colors.black54,
                            ),
                            onPressed: (_isFormValid && !_isLoading) ? () async {
                              setState(() => _isLoading = true);
                              
                              final result = await _firebaseService.signUp(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                                fullName: _fullNameController.text.trim(),
                                username: '', // Field removed, sending empty for backward compatibility
                              );

                              if (!mounted) return;
                              setState(() => _isLoading = false);

                              if (result['success']) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Account created successfully! Please log in.'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                Navigator.pop(context); // Return to login
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
                                );
                              }
                            } : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  color: Color(0xFF3FA34D),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
