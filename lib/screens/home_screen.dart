import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../auth_provider.dart';
import 'login_screen.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/navbar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSidebarOpen = false;
  List<dynamic> _livros = [];
  bool _isLoading = true;
  String _error = '';

  String get baseUrl {
    String host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3000';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        _fetchLivros();
      }
    });
  }

  Future<void> _fetchLivros() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/livros'));

      if (response.statusCode == 200) {
        final List<dynamic> livros = json.decode(response.body);
        setState(() {
          _livros = livros.take(4).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar os livros');
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar livros: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _closeSidebar() {
    setState(() {
      _isSidebarOpen = false;
    });
  }

  Widget _buildLivrosGrid() {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemCount: _livros.length,
      itemBuilder: (context, index) {
        final livro = _livros[index];
        Uint8List? imageBytes;
        try {
          if (livro['imagem'] != null && livro['imagem']['data'] != null) {
            imageBytes =
                Uint8List.fromList(List<int>.from(livro['imagem']['data']));
          }
        } catch (e) {
          print('Erro ao processar imagem: $e');
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: imageBytes != null
                    ? DecorationImage(
                        fit: BoxFit.cover,
                        image: MemoryImage(imageBytes),
                      )
                    : null,
              ),
              child: imageBytes == null
                  ? Icon(Icons.book, size: 50, color: Colors.grey[600])
                  : null,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                livro['titulo'] ?? 'Título desconhecido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                livro['autor'] ?? 'Autor desconhecido',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Ano: ${livro['dataPublicacao'] ?? 'Desconhecido'}',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              livro['disponivel'] == true ? 'Disponível' : 'Indisponível',
              style: TextStyle(
                fontSize: 12,
                color: livro['disponivel'] == true ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: NavbarWidget(
        isSidebarOpen: _isSidebarOpen,
        toggleSidebar: _toggleSidebar,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _isSidebarOpen ? _closeSidebar : null,
            child: AbsorbPointer(
              absorbing: _isSidebarOpen,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            'Bem-vindo à Biblioteca Yolanda Queiroz',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Últimos livros adicionados:',
                            style: TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? CircularProgressIndicator()
                              : _error.isNotEmpty
                                  ? Text(_error,
                                      style: TextStyle(color: Colors.red))
                                  : _buildLivrosGrid(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    color: Colors.grey[100],
                    child: Text(
                      '© Biblioteca Yolanda Queiroz',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSidebarOpen)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: GestureDetector(
                onTap: () {},
                child: SidebarWidget(closeSidebar: _closeSidebar),
              ),
            ),
        ],
      ),
    );
  }
}
