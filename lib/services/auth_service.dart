import 'dart:io'; // Adicionado para detectar a plataforma
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  // static const String baseUrl = 'http://localhost:6543';
  // static const String baseUrl = 'http://192.168.23.6:6543'; // ip Trabalho

  static String get baseUrl {
    String host = Platform.isAndroid ? '10.0.2.2' : 'localhost'; // IP padrão para emuladores Android
    return 'http://$host:6543';
  }

  static Future<http.Response> login(String email, String password) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users'));

    if (response.statusCode == 200) {
      final List<dynamic> users = jsonDecode(response.body);
      for (var user in users) {
        if (user['email'] == email) {
          if (user['senha'] == password) {
            return http.Response(jsonEncode(user), 200);
          } else {
            return http.Response('Senha incorreta', 401);
          }
        }
      }
      return http.Response('Email não cadastrado', 404);
    } else {
      throw Exception('Falha ao verificar email');
    }
  }

  static Future<http.Response> cadastrar(String nome, String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users'),
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    return response;
  }

  static Future<bool> verificarEmail(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users'));

    if (response.statusCode == 200) {
      final List<dynamic> users = jsonDecode(response.body);
      for (var user in users) {
        if (user['email'] == email) {
          return true;
        }
      }
      return false;
    } else {
      throw Exception('Falha ao verificar email');
    }
  }

  static Future<void> enviarEmailRecuperacao(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/recuperar-senha'),
      body: jsonEncode({'email': email}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao enviar email de recuperação');
    }
  }
}
