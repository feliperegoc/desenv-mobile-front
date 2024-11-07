import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:io';

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

  String get baseUrl {
    String host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3000';
  }

  @override
  void initState() {
    super.initState();
    _fetchLivroDetalhes();
  }

  Future<void> _fetchLivroDetalhes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/livros-teste/${widget.livroId}'),
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

  Future<void> _reservarLivro() async {
    // Implementar lógica de reserva
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Funcionalidade de reserva em desenvolvimento')),
    );
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
                        'Título: ${_livroDetalhes?['titulo']}',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Autor: ${_livroDetalhes?['autor']}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Ano: ${_livroDetalhes?['ano']}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Quantidade disponível: ${_livroDetalhes?['quantidade']}',
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
                      if (_livroDetalhes?['disponivel'] == true)
                        Center(
                          child: ElevatedButton(
                            onPressed: _reservarLivro,
                            child: Text('Reservar Livro'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
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
