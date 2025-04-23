import 'package:flutter/material.dart';
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
          data: {
            'name': _nameController.text.trim(),
          }, // Store additional user data
        );
        if (response.user != null) {
          print('Signed up: ${response.user!.id}');
          Navigator.pushReplacementNamed(context, '/home'); // Navigate to home
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
        Navigator.pushReplacementNamed(context, '/home'); // Navigate to home
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _isLogin ? 'Login' : 'Sign Up',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.0),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: TextStyle(color: Colors.red)),
              if (!_isLogin)
                TextFormField(
                  key: ValueKey('name'),
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
              if (!_isLogin) SizedBox(height: 10.0),
              TextFormField(
                key: ValueKey('email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 10.0),
              TextFormField(
                key: ValueKey('password'),
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              if (!_isLogin) SizedBox(height: 10.0),
              if (!_isLogin)
                TextFormField(
                  key: ValueKey('confirmPassword'),
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                ),
              SizedBox(height: 20.0),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? 'Login' : 'Sign Up'),
                ),
              SizedBox(height: 10.0),
              TextButton(
                onPressed: _switchAuthMode,
                child: Text(
                  _isLogin
                      ? 'Create an account'
                      : 'Already have an account? Log in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
