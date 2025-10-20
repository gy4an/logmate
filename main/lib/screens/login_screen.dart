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
  late Animation<double> loginSize;
  late AnimationController loginController;
  Duration animationDuration = const Duration(milliseconds: 270);

  @override
  void initState() {
    super.initState();

    // Hide status bar
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

    // ✅ Login successful → navigate based on stored role
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
        MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
      );
    }
  }

  Future<void> _goToSignup() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SignupScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // slide from bottom
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildLoginHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 62, top: 16),
      width: MediaQuery.of(context).size.width,
      height: loginSize.value,
      decoration: const BoxDecoration(
        color: Color(0XFF2a3ed7),
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
                TextField(
                  controller: _usernameController,
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
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black, height: 0.5),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.vpn_key),
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
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

  Widget _buildRegisterComponents() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(bottom: 32),
            child: Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0XFF2a3ed7),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0XFF2a3ed7),
              foregroundColor: Colors.white,
            ),
            onPressed: _goToSignup,
            child: const Text("Go to Sign Up"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double defaultLoginSize = MediaQuery.of(context).size.height / 1.6;

    loginSize = Tween<double>(
      begin: defaultLoginSize,
      end: 200,
    ).animate(CurvedAnimation(parent: loginController, curve: Curves.linear));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          // Blue arc header
          AnimatedBuilder(
            animation: loginController,
            builder: (context, child) => _buildLoginHeader(),
          ),

          // Login form (top half)
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2,
              child: Center(child: _buildLoginForm()),
            ),
          ),

          // Tap-to-open Sign Up (only when in login state)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: isLogin && !loginController.isAnimating
                  ? Colors.white
                  : Colors.transparent,
              width: MediaQuery.of(context).size.width,
              height: defaultLoginSize / 1.5,
              child: Visibility(
                visible: isLogin,
                child: GestureDetector(
                  onTap: () {
                    loginController.forward();
                    setState(() {
                      isLogin = !isLogin;
                    });
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
          ),

          // SIGN UP SLIDE — place LAST so it sits on TOP and receives taps
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              ignoring: isLogin, // don’t intercept taps when hidden
              child: AnimatedOpacity(
                opacity: isLogin ? 0.0 : 1.0,
                duration: animationDuration,
                child: _buildRegisterComponents(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
