import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fyp/main.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool showLogin = true;
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();
  final passwordController = TextEditingController();
  bool agreeToTerms = false;
  bool _obscurePassword = true; // Added for password visibility

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    contactController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validateContact(String? value) {
    if (value == null || value.isEmpty) return 'Contact number is required';
    if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
      return 'Must be 10 digits and start with 0';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Minimum 6 characters required';
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    return null;
  }

  void _toggleForm() {
    setState(() {
      showLogin = !showLogin;
      usernameController.clear();
      emailController.clear();
      contactController.clear();
      passwordController.clear();
      agreeToTerms = false;
      _obscurePassword = true; // Reset password visibility
      _formKey.currentState?.reset();
    });
  }

  // ---------------- RPC helpers ----------------

  Future<bool> _rpcUserExists(String email) async {
    try {
      final res = await _supabase.rpc(
        'auth_user_exists',
        params: {'p_email': email},
      );
      return res == true;
    } catch (_) {
      // If RPC fails, do not leak info; assume it exists to keep flow generic
      return true;
    }
  }

  Future<bool> _rpcIsLocked(String email) async {
    try {
      final res = await _supabase.rpc(
        'is_account_locked',
        params: {'p_email': email},
      );
      return (res is bool) ? res : false;
    } catch (_) {
      return false; // don't block if RPC fails
    }
  }

  /// Returns (failedAttempts, isLocked)
  Future<(int, bool)> _rpcIncrementFailed(String email) async {
    try {
      final res = await _supabase.rpc(
        'increment_failed_attempts',
        params: {'p_email': email},
      );

      int failed = 0;
      bool locked = false;

      if (res is Map) {
        failed = (res['failed_attempts'] as int?) ?? 0;
        locked = (res['is_locked'] as bool?) ?? false;
      } else if (res is List && res.isNotEmpty && res.first is Map) {
        final row = res.first as Map;
        failed = (row['failed_attempts'] as int?) ?? 0;
        locked = (row['is_locked'] as bool?) ?? false;
      }
      return (failed, locked);
    } catch (_) {
      return (0, false);
    }
  }

  Future<void> _rpcResetFailed(String userId) async {
    try {
      await _supabase.rpc(
        'reset_failed_attempts',
        params: {'p_user_id': userId},
      );
    } catch (_) {
      /* non-fatal */
    }
  }

  // --------------- Submit handler ---------------

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!showLogin) {
      // -------- Registration (anon allowed; DB trigger creates public.users row) --------
      if (!agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must agree to the terms')),
        );
        return;
      }
      try {
        await _supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          data: {
            'username': usernameController.text.trim(),
            'contact': contactController.text.trim(),
          },
        );

        // With email confirmation ON, user may be null until verified.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful. Check your email to verify your account.',
            ),
          ),
        );
        _toggleForm();
      } on AuthException catch (e) {
        String message = "Registration failed";
        if (e.message.contains('User already registered')) {
          message = "Email already in use";
        } else if (e.message.contains('Password should be at least')) {
          message = "Password too weak";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
      // ----------------------------------------------------------------------------------
    } else {
      // ------------- Login (requires verified email; 3-strike lockout) -------------
      final email = emailController.text.trim();
      final password = passwordController.text;

      // 0) Does this email exist? (You asked to show a specific message if not.)
      final exists = await _rpcUserExists(email);
      if (!exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No account found for this email. Please register first.',
            ),
          ),
        );
        return;
      }

      // 1) Pre-check: locked?
      final locked = await _rpcIsLocked(email);
      if (locked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account is locked. Contact admin.')),
        );
        return;
      }

      try {
        // 2) Attempt sign-in (will fail if email not confirmed)
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = response.user;
        if (user == null) {
          throw const AuthException('Invalid login credentials');
        }

        // 3) Success: reset failed attempts
        await _rpcResetFailed(user.id);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful')));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainDashboard()),
        );
      } on AuthException catch (e) {
        // Don't count unconfirmed-email errors toward lockout
        final m = e.message.toLowerCase();
        final unconfirmed =
            m.contains('confirm') ||
            m.contains('not confirmed') ||
            m.contains('verify');
        if (unconfirmed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your email before logging in.'),
            ),
          );
          return;
        }

        // Invalid credentials → increment and maybe lock
        final (failed, nowLocked) = await _rpcIncrementFailed(email);
        const maxAttempts = 3;
        final attemptsLeft = maxAttempts - failed; // use updated count

        final out =
            nowLocked
                ? 'Account locked after $failed failed attempts. Contact admin.'
                : (attemptsLeft > 0
                    ? 'Invalid email or password. Attempts left: $attemptsLeft'
                    : 'Invalid email or password.');

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(out)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
      // ------------------------------------------------------------------------------
    }
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(), // Force light theme here
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 188, 28, 124),
                Color.fromARGB(255, 145, 10, 148),
                Color(0xff5B0D85),
                Color(0xff19084C),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double maxWidth = 400;
              if (constraints.maxWidth > 1000) {
                maxWidth = 500;
              } else if (constraints.maxWidth > 600) {
                maxWidth = 450;
              }

              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/netstruct_logo.png",
                        width: constraints.maxWidth < 500 ? 250 : 350,
                        fit: BoxFit.contain,
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                showLogin ? 'Login' : 'Registration',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (!showLogin)
                                TextFormField(
                                  controller: usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  validator: _validateUsername,
                                ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 10),
                              if (!showLogin)
                                TextFormField(
                                  controller: contactController,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Number',
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: _validateContact,
                                ),
                              if (!showLogin) const SizedBox(height: 10),
                              TextFormField(
                                controller: passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 10),
                              if (!showLogin)
                                Row(
                                  children: [
                                    Checkbox(
                                      value: agreeToTerms,
                                      onChanged: (val) {
                                        setState(() {
                                          agreeToTerms = val ?? false;
                                        });
                                      },
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'Agree to terms & conditions',
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF162938),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(45),
                                ),
                                onPressed: _handleSubmit,
                                child: Text(showLogin ? 'Login' : 'Register'),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _toggleForm,
                                child: Text(
                                  showLogin
                                      ? "Don't have an account? Register"
                                      : "Already have an account? Login",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
