import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSidebarOpen = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Cor de fundo cinza claro
      appBar: AppBar(
        backgroundColor: Colors.blue[800], // Cor da AppBar azul
        leading: IconButton(
          icon: Icon(_isSidebarOpen ? Icons.close : Icons.menu),
          onPressed: _toggleSidebar,
          color: Colors.white, // Cor do ícone branco para melhor contraste
        ),
        title: Image.asset(
          'assets/logo_unifor.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: Row(
        children: [
          if (_isSidebarOpen)
            Container(
              width: 250,
              color: Colors.blue[800],
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSidebarButton('Home', Icons.home),
                  _buildSidebarButton('Teste', Icons.article),
                  _buildSidebarButton('Teste 2', Icons.folder),
                  _buildSidebarButton('Perfil', Icons.person),
                  _buildSidebarButton('Sair', Icons.exit_to_app),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: Text(
                'Bem-vindo à Biblioteca Yolanda Queiroz',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
      onTap: () {
        // Implementar a navegação para as telas correspondentes
        print('Clicou em $label');
      },
    );
  }
}
