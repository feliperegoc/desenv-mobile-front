import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({Key? key}) : super(key: key);

  @override
  _RecuperarSenhaScreenState createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final TextEditingController emailController = TextEditingController();

  Future<void> enviarRecuperacao(String email) async {
    try {
      // Verifica se o email está cadastrado
      final emailCadastrado = await AuthService.verificarEmail(email);

      if (emailCadastrado) {
        // Se o email estiver cadastrado, envia o email de recuperação
        await AuthService.enviarEmailRecuperacao(email);

        // Mostra mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail de recuperação enviado!')),
        );
      } else {
        // Se o email não estiver cadastrado, mostra mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail informado não cadastrado')),
        );
      }
    } catch (e) {
      // Em caso de erro na requisição
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao processar a solicitação. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                enviarRecuperacao(emailController.text);
              },
              child: const Text('ENVIAR'),
            ),
          ],
        ),
      ),
    );
  }
}