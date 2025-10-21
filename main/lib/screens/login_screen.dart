import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import 'admin_dashboard_screen.dart';
import 'user_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLogin = true;
  bool _obscurePassword = true;

  late AnimationController loginController;
  late Animation<double> loginSize;

  final Duration animationDuration = const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    loginController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
  }

  @override
  void dispose() {
    loginController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString('accounts');

    if (accountsJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No accounts found. Please sign up first.')),
      );
      return;
    }

    final List accounts = jsonDecode(accountsJson);
    final user = accounts.firstWhere(
      (acc) => acc['username'] == username && acc['password'] == password,
      orElse: () => null,
    );

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome, ${user['username']}!')),
    );

    if (user['role'] == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              UserDashboardScreen(username: _usernameController.text),
        ),
      );
    }
  }

  Future<void> _goToSignup() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SignupScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildLoginHeader() {
    return AnimatedBuilder(
      animation: loginController,
      builder: (context, child) {
        final double curvedHeight = Tween<double>(
          begin: MediaQuery.of(context).size.height / 1.6,
          end: 220,
        ).evaluate(CurvedAnimation(parent: loginController, curve: Curves.easeInOut));

        return Container(
          padding: const EdgeInsets.only(bottom: 62, top: 16),
          width: MediaQuery.of(context).size.width,
          height: curvedHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(190),
              bottomRight: Radius.circular(190),
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: isLogin
                  ? null
                  : () {
                      loginController.reverse();
                      setState(() {
                        isLogin = !isLogin;
                      });
                    },
              child: const Text(
                'LOG IN',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Visibility(
          visible: isLogin,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Column(
              children: <Widget>[
                // 🧑 Username field
                TextField(
                  controller: _usernameController,
                  textCapitalization: TextCapitalization.none, // ✅ disables caps
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.black, height: 0.5),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔒 Password field
                TextField(
                  controller: _passwordController,
                  textCapitalization: TextCapitalization.none, // ✅ disables caps
                  textInputAction: TextInputAction.done,
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.black, height: 0.5),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.vpn_key),
                    hintText: 'Password',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
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
                ),
                Container(
                  width: 200,
                  height: 40,
                  margin: const EdgeInsets.only(top: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                  child: InkWell(
                    onTap: _login,
                    child: const Center(
                      child: Text(
                        'LOG IN',
                        style: TextStyle(
                          color: Color(0XFF2a3ed7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: isLogin && !loginController.isAnimating
            ? Colors.white
            : Colors.transparent,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height / 3.5,
        child: Visibility(
          visible: isLogin,
          child: GestureDetector(
            onTap: () {
              loginController.forward();
              setState(() {
                isLogin = !isLogin;
              });
              Future.delayed(animationDuration, _goToSignup);
            },
            child: const Center(
              child: Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF2a3ed7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          _buildLoginHeader(),
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2,
              child: Center(child: _buildLoginForm()),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }
}
