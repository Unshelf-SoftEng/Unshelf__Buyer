import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/home_view.dart';
import 'package:unshelf_buyer/profile_view.dart';
import 'package:unshelf_buyer/register_view.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _Login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in successful')),
        );

        // Redirect to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileView()),
        );
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided.';
        } else {
          message = 'Sign in failed. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Image.network(
                'https://firebasestorage.googleapis.com/v0/b/unshelf-d4567.appspot.com/o/Unshelf.png?alt=media&token=ea449292-f36d-4dfe-a90a-2bef5c341694',
                height: 100,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onFieldSubmitted: (value) => _Login(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _Login,
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 20),
              const Text("Don't have an account?"),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterView()));
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
