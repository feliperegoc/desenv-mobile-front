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

class BibliotecaScreen extends StatefulWidget {
  const BibliotecaScreen({Key? key}) : super(key: key);

  @override
  _BibliotecaScreenState createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  bool _isSidebarOpen = false;
  List<dynamic> _todosLivros = []; // Todos os livros carregados
  List<dynamic> _livrosFiltrados = []; // Livros filtrados (resultado atual)
  bool _isLoading = true;
  String _error = '';
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10; // Limite de livros por página
  String _searchQuery = ''; // Palavra pesquisada
  Set<String> _selectedAuthors = {}; // Autores selecionados no filtro
  String _sortOrder = 'ASC'; // Ordem do ano de lançamento
  bool? _disponibilidade; // Disponibilidade filtrada

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
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _todosLivros = data; // Carrega todos os livros
          _livrosFiltrados = List.from(_todosLivros);
          _totalPages = (_livrosFiltrados.length / _limit).ceil();
          _carregarLivrosDaPagina();
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

  void _carregarLivrosDaPagina() {
    setState(() {
      int startIndex = (_currentPage - 1) * _limit;
      int endIndex = startIndex + _limit;
      _livrosFiltrados = _todosLivros
          .where((livro) => livro['titulo']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
      _livrosFiltrados.sort((a, b) => _sortOrder == 'ASC'
          ? a['dataPublicacao'].compareTo(b['dataPublicacao'])
          : b['dataPublicacao'].compareTo(a['dataPublicacao']));
      if (_disponibilidade != null) {
        _livrosFiltrados = _livrosFiltrados
            .where((livro) => livro['disponivel'] == _disponibilidade)
            .toList();
      }
      if (_selectedAuthors.isNotEmpty) {
        _livrosFiltrados = _livrosFiltrados
            .where((livro) => _selectedAuthors.contains(livro['autor']))
            .toList();
      }
      _livrosFiltrados = _livrosFiltrados.sublist(
        startIndex,
        endIndex > _livrosFiltrados.length ? _livrosFiltrados.length : endIndex,
      );
    });
  }

  void _filterLivros(String query) {
    setState(() {
      _searchQuery = query;
      _carregarLivrosDaPagina();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Filtros'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Text('Disponível'),
                    value: _disponibilidade ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        _disponibilidade = value;
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: _sortOrder,
                    items: ['ASC', 'DESC']
                        .map((order) => DropdownMenuItem(
                              value: order,
                              child: Text(order == 'ASC'
                                  ? 'Ano Ascendente'
                                  : 'Ano Descendente'),
                            ))
                        .toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _sortOrder = value!;
                      });
                    },
                  ),
                  // Simular lista de autores
                  Wrap(
                    children: ['Autor 1', 'Autor 2', 'Autor 3']
                        .map(
                          (autor) => CheckboxListTile(
                            title: Text(autor),
                            value: _selectedAuthors.contains(autor),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedAuthors.add(autor);
                                } else {
                                  _selectedAuthors.remove(autor);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Aplicar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _carregarLivrosDaPagina();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Funções para controlar a abertura e fechamento da sidebar
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

  // Funções de navegação entre páginas
  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _carregarLivrosDaPagina();
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _carregarLivrosDaPagina();
      });
    }
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
                // Mudado de SingleChildScrollView para Column
                children: [
                  Expanded(
                    // Adicionado Expanded
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Pesquisar livros...',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: _filterLivros,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.filter_list),
                                  onPressed: _showFilterDialog,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? CircularProgressIndicator()
                              : _error.isNotEmpty
                                  ? Text(_error,
                                      style: TextStyle(color: Colors.red))
                                  : Column(
                                      children: [
                                        _buildLivrosGrid(),
                                        const SizedBox(height: 20),
                                        _buildPaginationControls(),
                                      ],
                                    ),
                        ],
                      ),
                    ),
                  ),
                  // Copyright fixo na parte inferior
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

  Widget _buildLivrosGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.65,
        ),
        itemCount: _livrosFiltrados.length,
        itemBuilder: (context, index) {
          final livro = _livrosFiltrados[index];
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
                width: 120,
                height: 180,
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
                  color:
                      livro['disponivel'] == true ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentPage > 1)
            TextButton(
              onPressed: _goToPreviousPage,
              child: Row(
                children: [
                  Icon(Icons.arrow_back, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${_currentPage - 1}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_currentPage',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (_currentPage < _totalPages)
            TextButton(
              onPressed: _goToNextPage,
              child: Row(
                children: [
                  Text(
                    '${_currentPage + 1}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
