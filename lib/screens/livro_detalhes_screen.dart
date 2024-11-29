import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:provider/provider.dart';
import '../auth_provider.dart';

class LivroDetalhesScreen extends StatefulWidget {
  final int livroId;

  const LivroDetalhesScreen({Key? key, required this.livroId})
      : super(key: key);

  @override
  _LivroDetalhesScreenState createState() => _LivroDetalhesScreenState();
}

class _LivroDetalhesScreenState extends State<LivroDetalhesScreen> {
  Map<String, dynamic>? _livroDetalhes;
  bool _isLoading = true;
  String _error = '';
  bool _isProcessing = false;
  bool _isLocated = false;
  int? _userId;
  // int? _emprestimoId;

  String get baseUrl {
    String host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3000';
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchUserId();
    await _fetchLivroDetalhes();
    await _checkEmprestimoStatus();
  }

  Future<void> _fetchUserId() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.userEmail;

      if (userEmail == null) return;

      final response = await http.get(Uri.parse('$baseUrl/api/users'));

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        final user = users.firstWhere(
          (user) => user['email'] == userEmail,
          orElse: () => null,
        );

        if (user != null) {
          _userId = user['id'];
        }
      }
    } catch (e) {
      print('Erro ao buscar ID do usuário: $e');
    }
  }

  Future<void> _checkEmprestimoStatus() async {
    if (_userId == null) return;

    try {
      final response = await http.get(Uri.parse('$baseUrl/emprestimos'));

      if (response.statusCode == 200) {
        final List<dynamic> emprestimos = json.decode(response.body);

        final currentEmprestimo = emprestimos.firstWhere(
          (emp) =>
              emp['usuarioId'] == _userId &&
              emp['livroId'] == widget.livroId &&
              emp['locado'] == true &&
              emp['dataDevolucao'] == null,
          orElse: () => null,
        );

        setState(() {
          _isLocated = currentEmprestimo != null;
          // _emprestimoId = currentEmprestimo?['id'];
        });
      }
    } catch (e) {
      print('Erro ao verificar status do empréstimo: $e');
    }
  }

  Future<void> _fetchLivroDetalhes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/livros/${widget.livroId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _livroDetalhes = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar detalhes do livro');
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar detalhes do livro: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLoanAction() async {
    if (_isProcessing || _userId == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final String endpoint = _isLocated
          ? '/emprestimos/devolver/$_userId/${widget.livroId}'
          : '/emprestimos/alugar/$_userId/${widget.livroId}';

      final response = await http.post(Uri.parse('$baseUrl$endpoint'));

      if (response.statusCode == 201) {
        final bool wasLocated = _isLocated;

        await Future.wait([
          _fetchLivroDetalhes(),
          _checkEmprestimoStatus(),
        ]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasLocated
                ? 'Livro devolvido com sucesso!'
                : 'Livro reservado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Falha na operação');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na operação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_livroDetalhes?['titulo'] ?? 'Detalhes do Livro'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 200,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            image: _livroDetalhes?['imagem'] != null
                                ? DecorationImage(
                                    fit: BoxFit.cover,
                                    image: MemoryImage(
                                      Uint8List.fromList(
                                        List<int>.from(
                                          _livroDetalhes!['imagem']['data'],
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          child: _livroDetalhes?['imagem'] == null
                              ? Icon(Icons.book,
                                  size: 50, color: Colors.grey[600])
                              : null,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Título: ${_livroDetalhes?['titulo'] ?? 'Não informado'}',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Autor: ${_livroDetalhes?['autor'] ?? 'Não informado'}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Ano: ${_livroDetalhes?['ano'] ?? 'Não informado'}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Quantidade disponível: ${_livroDetalhes?['quantidade'] ?? 0}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Status: ${_livroDetalhes?['disponivel'] == true ? 'Disponível' : 'Indisponível'}',
                        style: TextStyle(
                          fontSize: 18,
                          color: _livroDetalhes?['disponivel'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      SizedBox(height: 30),
                      if (_livroDetalhes?['disponivel'] == true || _isLocated)
                        Center(
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _handleLoanAction,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                              backgroundColor:
                                  _isLocated ? Colors.red : Colors.blue[800],
                              foregroundColor: Colors.white,
                            ),
                            child: _isProcessing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLocated
                                        ? 'Devolver Livro'
                                        : 'Reservar Livro',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
