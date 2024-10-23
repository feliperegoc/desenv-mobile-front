import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/biblioteca.dart';
import '../screens/chamada.dart';
import '../screens/turmas.dart';
import '../screens/perfil.dart';
import '../screens/login_screen.dart';

class SidebarWidget extends StatelessWidget {
  final Function closeSidebar;

  const SidebarWidget({Key? key, required this.closeSidebar}) : super(key: key);

  void _navigateTo(BuildContext context, Widget screen) {
    closeSidebar();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _logout(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firstName = authProvider.getFirstName()?.capitalize() ?? 'Usuário';

    return Container(
      width: 250,
      color: Colors.blue[800],
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Olá, $firstName',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSidebarButton(
              'Home', Icons.home, () => _navigateTo(context, HomeScreen())),
          _buildSidebarButton('Biblioteca', Icons.book,
              () => _navigateTo(context, BibliotecaScreen())),
          _buildSidebarButton('Chamada', Icons.checklist_rounded,
              () => _navigateTo(context, ChamadaScreen())),
          _buildSidebarButton('Turmas', Icons.people_outline,
              () => _navigateTo(context, TurmasScreen())),
          _buildSidebarButton('Perfil', Icons.person,
              () => _navigateTo(context, PerfilScreen())),
          Spacer(),
          _buildSidebarButton(
              'Sair', Icons.exit_to_app, () => _logout(context)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
