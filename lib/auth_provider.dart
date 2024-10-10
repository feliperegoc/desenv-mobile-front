import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  Future<bool> login(String email, String password) async {
    try {
      final response = await AuthService.login(email, password);
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _isAuthenticated = true;
        _userEmail = email;
        _userName = userData['nome'];
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Erro durante o login: $e');
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    notifyListeners();
  }

  String? getFirstName() {
    if (_userName == null || _userName!.isEmpty) return null;
    return _userName!.split(' ')[0];
  }

  Future<bool> cadastrar(String nome, String email, String senha) async {
    try {
      final response = await AuthService.cadastrar(nome, email, senha);
      return response.statusCode == 200;
    } catch (e) {
      print('Erro durante o cadastro: $e');
      return false;
    }
  }

  Future<bool> verificarEmail(String email) async {
    try {
      return await AuthService.verificarEmail(email);
    } catch (e) {
      print('Erro ao verificar email: $e');
      return false;
    }
  }

  Future<bool> enviarEmailRecuperacao(String email) async {
    try {
      await AuthService.enviarEmailRecuperacao(email);
      return true;
    } catch (e) {
      print('Erro ao enviar email de recuperação: $e');
      return false;
    }
  }
}
