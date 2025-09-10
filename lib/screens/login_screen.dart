import 'package:flutter/material.dart';
import 'CompleteProfileScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  final _supabase = Supabase.instance.client;

  void _switchAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
    });
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (_passwordController.text.trim() ==
          _confirmPasswordController.text.trim()) {
        final response = await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {'name': _nameController.text.trim()},
        );

        if (response.user != null) {
          print('Signed up: ${response.user!.id}');
          final profile =
              await _supabase
                  .from('profiles')
                  .select()
                  .eq('id', response.user!.id)
                  .maybeSingle();

          if (profile == null || profile['name'] == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You are registered in Routex!')),
            );
            Navigator.pushReplacementNamed(
              context,
              '/login-screen',
            ); // Go to complete profile screen
          } else {
            Navigator.pushReplacementNamed(
              context,
              '/home',
            ); // Go to home screen
          }
        } else {
          setState(() {
            _errorMessage = 'Signup failed. Please try again.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Passwords do not match.';
        });
      }
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      print(error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user != null) {
        print('Logged in: ${response.user!.id}');

        // Check if the user's profile exists and is complete
        final profile =
            await _supabase
                .from('profiles')
                .select()
                .eq('id', response.user!.id)
                .maybeSingle();

        if (profile == null || profile['name'] == null) {
          // If profile is incomplete, navigate to Complete Profile screen
          Navigator.pushReplacementNamed(context, '/complete-profile');
        } else {
          // If profile is complete, navigate to Home screen
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      print(error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submit() {
    if (_isLogin) {
      _signIn();
    } else {
      _signUp();
    }
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade100,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueAccent, width: 2),
      ),
      errorStyle: TextStyle(color: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // App Logo or Icon (can add your own image/logo here)
              Icon(
                Icons.local_taxi_rounded,
                size: 80,
                color: Colors.blueAccent,
              ),
              SizedBox(height: 20),
              Text(
                'RouteX',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _isLogin ? 'Welcome Back!' : 'Create your Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 25),
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _errorMessage = '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              if (!_isLogin)
                TextFormField(
                  key: ValueKey('name'),
                  controller: _nameController,
                  decoration: _inputDecoration('Full Name', icon: Icons.person),
                  textInputAction: TextInputAction.next,
                ),
              if (!_isLogin) SizedBox(height: 15),
              TextFormField(
                key: ValueKey('email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  'Email Address',
                  icon: Icons.email,
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 15),
              TextFormField(
                key: ValueKey('password'),
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration('Password', icon: Icons.lock),
                textInputAction:
                    _isLogin ? TextInputAction.done : TextInputAction.next,
              ),
              if (!_isLogin) SizedBox(height: 15),
              if (!_isLogin)
                TextFormField(
                  key: ValueKey('confirmPassword'),
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration(
                    'Confirm Password',
                    icon: Icons.lock,
                  ),
                  textInputAction: TextInputAction.done,
                ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.blueAccent)
                  : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _isLogin ? 'Login' : 'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              SizedBox(height: 20),
              TextButton(
                onPressed: _switchAuthMode,
                child: Text(
                  _isLogin
                      ? 'Don\'t have an account? Create one'
                      : 'Already have an account? Log in',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
