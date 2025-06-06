import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightGreen,
          primary: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const OnboardingPages(),
    );
  }
}

class OnboardingPages extends StatefulWidget {
  const OnboardingPages({super.key});

  @override
  State<OnboardingPages> createState() => _OnboardingPagesState();
}

class _OnboardingPagesState extends State<OnboardingPages> {
  final PageController _controller = PageController();

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  bool _obscureSignupPassword = true;
  bool _obscureLoginPassword = true;
  int _currentPage = 0;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final signupEmailController = TextEditingController();
  final signupPasswordController = TextEditingController();
  String? LoginerrorMessage;
  String? SignuperrorMessage;

  bool isOffline = false;
  bool showBackOnlineBanner = false;
  final Connectivity _connectivity = Connectivity();

  final List<String> backgroundImages = [
    'images/frontpage/ebook.jpg',
    'images/frontpage/ebook2.jpg',
    'images/frontpage/ebook3.jpg',
  ];

  @override
  void initState() {
    super.initState();

    _connectivity.onConnectivityChanged.listen((result) {
      bool offlineNow = result == ConnectivityResult.none;
      if (!offlineNow && isOffline) {
        setState(() {
          isOffline = false;
          showBackOnlineBanner = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => showBackOnlineBanner = false);
        });
      } else {
        setState(() => isOffline = offlineNow);
      }
    });

    _connectivity.checkConnectivity().then((result) {
      setState(() => isOffline = result == ConnectivityResult.none);
    });
  }

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      setState(() => LoginerrorMessage = null); // Clear error on success
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            LoginerrorMessage = 'No user found for that email.';
            break;
          case 'wrong-password':
            LoginerrorMessage = 'Incorrect password.';
            break;
          case 'invalid-email':
            LoginerrorMessage = 'Invalid email address.';
            break;
          case 'user-disabled':
            LoginerrorMessage = 'This account has been disabled.';
            break;
          default:
            LoginerrorMessage = 'Login failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() => LoginerrorMessage = 'An unexpected error occurred: $e');
    }
  }

  Future<void> signup() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: signupEmailController.text.trim(),
        password: signupPasswordController.text,
      );
      setState(() => SignuperrorMessage = null); // Clear error on success
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            SignuperrorMessage = 'The email address is already registered.';
            break;
          case 'invalid-email':
            SignuperrorMessage = 'The email address is not valid.';
            break;
          case 'operation-not-allowed':
            SignuperrorMessage = 'Email/password sign-up is not enabled.';
            break;
          case 'weak-password':
            SignuperrorMessage = 'The password is too weak.';
            break;
          default:
            SignuperrorMessage = 'Signup failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() => SignuperrorMessage = 'An unexpected error occurred: $e');
    }
  }

    Widget modernTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool obscure = false,
    void Function()? toggleVisibility,
    IconData? icon,
    String? errorText,
      }) {
        return TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon != null ? Icon(icon) : null,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: toggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            errorText: errorText,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.lightGreen, width: 2),
            ),
          ),
        );
      }

  Widget buildBackgroundImage(String imagePath) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.black), // placeholder background
        ),
        Positioned.fill(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 600),
                  child: child,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // Page 1: Welcome
      Stack(
        fit: StackFit.expand,
        children: [
          buildBackgroundImage(backgroundImages[0]),
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "eBook Haven",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Read anywhere, anytime. Your portable digital library. Discover, read, and enjoy eBooks on the go.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Page 2: Sign In
      Stack(
        fit: StackFit.expand,
        children: [
          buildBackgroundImage(backgroundImages[1]),
          Container(color: Colors.black.withOpacity(0.3)),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 10),
            child: Form(
              key: _loginFormKey,
              child: Column(
                children: [
                  const Text(
                    "Sign In",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  if (LoginerrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(LoginerrorMessage!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.white,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                        return null;
                      },
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscureLoginPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.white,
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureLoginPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_loginFormKey.currentState!.validate()) {
                          login(); // Call your login logic
                        }
                      },
                      child: const Text('Login', 
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Page 3: Sign Up
      Stack(
        fit: StackFit.expand,
        children: [
          buildBackgroundImage(backgroundImages[2]),
          Container(color: Colors.black.withOpacity(0.3)),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 10),
            child: Form(
              key: _signupFormKey,
              child: Column(
                children: [
                  const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  if (SignuperrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(SignuperrorMessage!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  TextFormField(
                    controller: signupEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white,
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: signupPasswordController,
                    obscureText: _obscureSignupPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSignupPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureSignupPassword = !_obscureSignupPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password is required';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_signupFormKey.currentState!.validate()) {
                          signup();
                        }
                      },
                      child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => pages[index],
          ),

          // Connectivity indicator
          if (isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: const EdgeInsets.all(10),
                child: const SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Internet Connection Lost',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          if (showBackOnlineBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.green,
                padding: const EdgeInsets.all(10),
                child: const SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi, color: Colors.white),
                      SizedBox(width: 10),
                      Text("You're back online",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

          // Smooth Page Indicator
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: pages.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  spacing: 8,
                  expansionFactor: 3,
                  activeDotColor: Colors.lightGreen,
                  dotColor: Colors.lightGreen.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}