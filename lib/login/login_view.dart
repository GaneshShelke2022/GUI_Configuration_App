import 'package:flutter/material.dart';
import 'login_controller.dart';
import '../ui/pages/customer_info_page.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final LoginController _controller = LoginController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onController);
  }

  void _onController() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    _controller.setEmail(_emailCtrl.text.trim());
    _controller.setPassword(_pwCtrl.text);

    final ok = await _controller.login();
    if (ok) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const CustomerInfoPage(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 243, 242, 243),Color.fromARGB(255, 242, 243, 243) ],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 700 : 420),
              child: Card(
                elevation: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                SizedBox(height: 6),
                                Text('Sign in to continue', style: TextStyle(fontSize: 16, color: Colors.black54)),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color.fromARGB(255, 129, 128, 131),
                            child: Icon(Icons.person, color: Colors.white, size: 30),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: _controller.validateEmail,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pwCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: _controller.validatePassword,
                            ),
                            const SizedBox(height: 6),
                            // Align(
                            //   alignment: Alignment.centerRight,
                            //   child: TextButton(
                            //     onPressed: () {},
                            //     child: const Text('Forgot password?'),
                            //   ),
                            // ),

                            if (_controller.error != null) ...[
                              const SizedBox(height: 6),
                              Text(_controller.error!, style: const TextStyle(color: Colors.red)),
                            ],

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: const Color.fromARGB(255, 108, 88, 170),
                                ),
                                onPressed: _controller.loading ? null : _submit,
                                child: _controller.loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Sign In', style: TextStyle(fontSize: 20, color:Colors.white)),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     const Text('Don\'t have an account? '),
                            //     TextButton(onPressed: () {}, child: const Text('Sign up')),
                            //   ],
                            // ),

                            const SizedBox(height: 6),

                            // Social row
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     _socialButton(Icons.g_mobiledata, 'Google'),
                            //     const SizedBox(width: 12),
                            //     _socialButton(Icons.apple, 'Apple'),
                            //     const SizedBox(width: 12),
                            //     _socialButton(Icons.facebook, 'Facebook'),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  

  // Widget _socialButton(IconData icon, String label) {
  //   return OutlinedButton.icon(
  //     onPressed: () {},
  //     icon: Icon(icon, color: Colors.deepPurple),
  //     label: Text(label),
  //     style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
  //   );
  // }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome! You are logged in.', style: TextStyle(fontSize: 20))),
    );
  }
}
