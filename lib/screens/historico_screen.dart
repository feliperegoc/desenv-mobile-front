import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../auth_provider.dart';
import 'login_screen.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/navbar_widget.dart';
import 'livro_detalhes_screen.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({Key? key}) : super(key: key);

  @override
  _HistoricoScreenState createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  bool _isSidebarOpen = false;
  List<Map<String, dynamic>> _emprestimos = [];
  bool _isLoading = true;
  String _error = '';
  int? _userId;
  String? _userName;

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }
    await _fetchUserInfo(authProvider.userEmail);
  }

  Future<void> _fetchUserInfo(String? email) async {
    if (email == null) return;

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/users'));

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        final user = users.firstWhere(
          (user) =>
              user['email'].toString().toLowerCase() == email.toLowerCase(),
          orElse: () => null,
        );

        if (user != null) {
          setState(() {
            _userId = user['id'];
            _userName = user['nome'];
          });
          await _fetchEmprestimos();
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar informações do usuário: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEmprestimos() async {
    if (_userId == null || _userName == null) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Fetch both active and historical loans
      final activeResponse = await http.get(Uri.parse('$baseUrl/emprestimos'));
      final historyResponse =
          await http.get(Uri.parse('$baseUrl/emprestimos/historico'));

      if (activeResponse.statusCode == 200 &&
          historyResponse.statusCode == 200) {
        final List<dynamic> activeEmprestimos =
            json.decode(activeResponse.body);
        final List<dynamic> historyEmprestimos =
            json.decode(historyResponse.body);

        // Get complete loan information by combining both APIs
        final allEmprestimos = historyEmprestimos
            .where((emp) => emp['usuarioNome'] == _userName)
            .map((emp) {
          // Find corresponding active loan to get livroId if available
          final activeLoan = activeEmprestimos.firstWhere(
            (active) => active['id'] == emp['id'],
            orElse: () => null,
          );

          return {
            'id': emp['id'],
            'livroId': activeLoan?['livroId'],
            'livroTitulo': emp['livroTitulo'],
            'livroAutor': emp['livroAutor'],
            'dataEmprestimo': emp['dataEmprestimo'],
            'dataDevolucao': emp['dataDevolucao'],
            'isActive': emp['dataDevolucao'] == null,
          };
        }).toList();

        // Sort: active loans first, then by date
        allEmprestimos.sort((a, b) {
          if (a['dataDevolucao'] == null && b['dataDevolucao'] != null)
            return -1;
          if (a['dataDevolucao'] != null && b['dataDevolucao'] == null)
            return 1;
          return DateTime.parse(b['dataEmprestimo'])
              .compareTo(DateTime.parse(a['dataEmprestimo']));
        });

        setState(() {
          _emprestimos = allEmprestimos;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar histórico de empréstimos: $e';
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

  void _navigateToLivroDetalhes(String titulo) {
    // Encontra o empréstimo ativo correspondente ao título
    final activeEmprestimo = _emprestimos.firstWhere(
      (emp) => emp['livroTitulo'] == titulo && emp['dataDevolucao'] == null,
      orElse: () => {},
    );

    if (activeEmprestimo['livroId'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LivroDetalhesScreen(livroId: activeEmprestimo['livroId']),
        ),
      ).then((_) => _fetchEmprestimos());
    }
  }

  Widget _buildHistoricoContent() {
    if (_emprestimos.isEmpty) {
      return Center(
        child: Text(
          'Este usuário ainda não alugou livros',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: Table(
          border: TableBorder.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          columnWidths: const {
            0: FlexColumnWidth(2), // Livro
            1: FlexColumnWidth(1), // Data de Aluguel
            2: FlexColumnWidth(1), // Data de Devolução
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.blue[800]!.withOpacity(0.1),
              ),
              children: [
                _buildHeaderCell('Livro'),
                _buildHeaderCell('Data de Aluguel'),
                _buildHeaderCell('Data de Devolução'),
              ],
            ),
            ..._emprestimos
                .map((emprestimo) => TableRow(
                      children: [
                        _buildBookCell(emprestimo),
                        _buildDateCell(emprestimo['dataEmprestimo']),
                        _buildDateCell(emprestimo['dataDevolucao']),
                      ],
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildBookCell(Map<String, dynamic> emprestimo) {
    final bool isActive = emprestimo['dataDevolucao'] == null;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: InkWell(
        onTap: isActive
            ? () => _navigateToLivroDetalhes(emprestimo['livroTitulo'])
            : null,
        child: Text(
          emprestimo['livroTitulo'] ?? '',
          style: TextStyle(
            color: isActive ? Colors.blue[800] : Colors.black,
            decoration: isActive ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDateCell(String? date) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        date != null ? _formatDate(date) : '',
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
                            'Histórico de Aluguel',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.blue[800],
                                    ),
                                  )
                                : _error.isNotEmpty
                                    ? Text(_error,
                                        style: TextStyle(color: Colors.red))
                                    : _buildHistoricoContent(),
                          ),
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
