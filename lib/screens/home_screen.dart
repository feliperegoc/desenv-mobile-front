import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
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
    final firstName = authProvider.getFirstName() ?? 'Usuário';

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
          Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'Bem-vindo à Biblioteca Yolanda Queiroz',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (_isSidebarOpen)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
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
                    _buildSidebarButton('Home', Icons.home),
                    _buildSidebarButton('Teste', Icons.article),
                    _buildSidebarButton('Teste 2', Icons.folder),
                    _buildSidebarButton('Perfil', Icons.person),
                    Spacer(),
                    _buildSidebarButton('Sair', Icons.exit_to_app),
                    const SizedBox(height: 20),
                  ],
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
        if (label == 'Sair') {
          _logout(context);
        } else {
          print('Clicou em $label');
        }
      },
    );
  }
}
