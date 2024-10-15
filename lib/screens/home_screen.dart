import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_provider.dart';
import 'login_screen.dart';
import 'biblioteca.dart';
import 'chamada.dart';
import 'turmas.dart';
import 'perfil.dart';
import '../utils/string_extension.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSidebarOpen = false;
  List<dynamic> _livros = [];

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
    final response =
        await http.get(Uri.parse('http://192.168.23.6:6543/livros'));

    if (response.statusCode == 200) {
      final List<dynamic> livros = json.decode(response.body);
      setState(() {
        _livros = livros.reversed.take(3).toList();
      });
    } else {
      // Tratar erro de requisição
      print('Erro ao buscar livros: ${response.statusCode}');
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

  void _logout(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firstName = authProvider.getFirstName()?.capitalize() ?? 'Usuário';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: Icon(_isSidebarOpen ? Icons.close : Icons.menu),
          onPressed: _toggleSidebar,
          color: Colors.white,
        ),
        title: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
          child: Image.asset(
            'assets/logo_unifor.png',
            height: 40,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _isSidebarOpen ? _closeSidebar : null,
            child: AbsorbPointer(
              absorbing: _isSidebarOpen,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Bem-vindo à Biblioteca Yolanda Queiroz',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildLivrosList(),
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
                child: Container(
                  width: 250,
                  color: Colors.blue[800],
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Olá, $firstName',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildSidebarButton('Home', Icons.home, () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                        );
                      }),
                      _buildSidebarButton('Biblioteca', Icons.book, () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const BibliotecaScreen()),
                        );
                      }),
                      _buildSidebarButton('Chamada', Icons.checklist_rounded,
                          () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const ChamadaScreen()),
                        );
                      }),
                      _buildSidebarButton('Turmas', Icons.people_outline, () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const TurmasScreen()),
                        );
                      }),
                      _buildSidebarButton('Perfil', Icons.person, () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const PerfilScreen()),
                        );
                      }),
                      Spacer(),
                      _buildSidebarButton('Sair', Icons.exit_to_app, () {
                        _logout(context);
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLivrosList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _livros.map((livro) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 120,
                  color: Colors.grey[300],
                  child: Center(child: Text('Imagem')),
                ),
                const SizedBox(height: 8),
                Text(
                  livro['titulo'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  livro['autor'],
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                Text(
                  livro['disponivel'] ? 'Disponível' : 'Indisponível',
                  style: TextStyle(
                      fontSize: 12,
                      color: livro['disponivel'] ? Colors.green : Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSidebarButton(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
}
