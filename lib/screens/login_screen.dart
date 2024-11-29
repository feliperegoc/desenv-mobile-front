import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'cadastro_screen.dart';
import 'recuperar_senha_screen.dart';
import 'home_screen.dart';
import '../auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? emailError;
  String? passwordError;

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        emailError = email.isEmpty ? 'Email deve ser preenchido' : null;
        passwordError = password.isEmpty ? 'Senha deve ser preenchida' : null;
      });
      return;
    }

    try {
      final response = await AuthService.login(email, password);

      if (!mounted) return;

      if (response.statusCode == 200) {
        bool loginSuccess =
            await Provider.of<AuthProvider>(context, listen: false)
                .login(email, password);
        if (loginSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          _showErrorDialog('Erro ao fazer login');
        }
      } else if (response.statusCode == 404) {
        _showErrorDialog('Email não cadastrado');
      } else if (response.statusCode == 401) {
        _showErrorDialog('Senha incorreta. Tente novamente');
      } else {
        _showErrorDialog('Erro ao fazer login');
      }
    } catch (e) {
      _showErrorDialog(
          'Erro de conexão. Verifique sua conexão com a internet e tente novamente.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 50),
              Image.asset(
                'assets/logo_unifor.png',
                height: 120,
              ),
              const SizedBox(height: 20),
              Text(
                'Biblioteca Yolanda Queiroz',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 50),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: emailError,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  errorText: passwordError,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  login(emailController.text, passwordController.text);
                },
                child: const Text('ENTRAR'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RecuperarSenhaScreen()),
                      );
                    },
                    child: const Text('Esqueci a senha'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CadastroScreen()),
                      );
                    },
                    child: const Text('Cadastre-se'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
