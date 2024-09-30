import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Importar a tela de login

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  Future<void> cadastrar(String nome, String email, String senha) async {
    try {
      final emailCadastrado = await AuthService.verificarEmail(email);

      if (!mounted) return;

      if (emailCadastrado) {
        // Exibir tela de "Email já cadastrado"
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro'),
            content: const Text('Email já cadastrado'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final response = await AuthService.cadastrar(nome, email, senha);

        if (response.statusCode == 201) {
          // Exibir tela de "Usuário criado com sucesso"
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sucesso'),
              content: Text('Usuário criado com sucesso. Bem-vindo, $nome!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fechar o diálogo
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) =>
                              LoginScreen()), // Navegar para a tela de login
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Exibir tela de erro genérico
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erro'),
              content: const Text('Erro ao criar usuário'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Erro: $e');
      // Exibir tela de erro genérico
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: const Text('Erro ao criar usuário'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
              ),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: senhaController,
              decoration: const InputDecoration(
                labelText: 'Senha',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                cadastrar(nomeController.text, emailController.text,
                    senhaController.text);
              },
              child: const Text('CADASTRAR'),
            ),
          ],
        ),
      ),
    );
  }
}
