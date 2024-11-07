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

class BibliotecaScreen extends StatefulWidget {
  const BibliotecaScreen({Key? key}) : super(key: key);

  @override
  _BibliotecaScreenState createState() => _BibliotecaScreenState();
}

enum DisponibilidadeFilter {
  todos,
  sim,
  nao,
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  bool _isSidebarOpen = false;
  List<dynamic> _todosLivros = [];
  List<dynamic> _livrosFiltrados = [];
  bool _isLoading = true;
  String _error = '';
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;
  String _searchQuery = '';
  Set<String> _selectedAuthors = {};
  List<String> _availableAuthors = []; // Adicione aqui
  String _authorSearchQuery = '';
  List<String> _filteredAuthors = [];
  DisponibilidadeFilter _disponibilidadeFilter = DisponibilidadeFilter.todos;
  String _sortOrder = 'ASC';
  // bool? _disponibilidade;

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
      final totalResponse =
          await http.get(Uri.parse('$baseUrl/livros-teste?limit=2000'));

      if (totalResponse.statusCode == 200) {
        final List<dynamic> allData = json.decode(totalResponse.body);
        _todosLivros = allData;

        // Extrai a lista de autores únicos
        _availableAuthors = _todosLivros
            .map((livro) => livro['autor'].toString())
            .where((autor) => autor.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        // Aplica filtro de busca por título
        _livrosFiltrados = _todosLivros.where((livro) {
          return livro['titulo']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
        }).toList();

        // Aplica filtro de disponibilidade
        if (_disponibilidadeFilter != DisponibilidadeFilter.todos) {
          bool disponibilidadeValue =
              _disponibilidadeFilter == DisponibilidadeFilter.sim;
          _livrosFiltrados = _livrosFiltrados.where((livro) {
            return livro['disponivel'] == disponibilidadeValue;
          }).toList();
        }

        // Aplica filtro de autores selecionados
        if (_selectedAuthors.isNotEmpty) {
          _livrosFiltrados = _livrosFiltrados.where((livro) {
            return _selectedAuthors.contains(livro['autor']);
          }).toList();
        }

        // Aplica ordenação por ano (comentado para implementação futura)
        /*
      _livrosFiltrados.sort((a, b) {
        if (a['ano'] == null) return 1;
        if (b['ano'] == null) return -1;
        int comparison = a['ano'].compareTo(b['ano']);
        return _sortOrder == 'ASC' ? comparison : -comparison;
      });
      */

        // Calcula o total de páginas baseado nos livros filtrados
        _totalPages = (_livrosFiltrados.length / _limit).ceil();

        // Garante que a página atual é válida
        if (_currentPage > _totalPages) {
          _currentPage = _totalPages;
        }

        // Aplica a paginação nos resultados filtrados
        int startIndex = (_currentPage - 1) * _limit;
        int endIndex = startIndex + _limit;

        if (startIndex < _livrosFiltrados.length) {
          _livrosFiltrados = _livrosFiltrados.sublist(
            startIndex,
            endIndex > _livrosFiltrados.length
                ? _livrosFiltrados.length
                : endIndex,
          );
        } else {
          _livrosFiltrados = [];
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro detalhado: $e');
      setState(() {
        _error = 'Erro ao buscar livros: $e';
        _isLoading = false;
      });
    }
  }

  void _filterLivros(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _fetchLivros();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filtra os autores baseado na busca
            List<String> searchedAuthors = [];
            if (_authorSearchQuery.isNotEmpty) {
              searchedAuthors = _availableAuthors
                  .where((autor) => autor
                      .toLowerCase()
                      .contains(_authorSearchQuery.toLowerCase()))
                  .toList();
            } else {
              // Se não houver busca, mostra os autores da página atual
              Set<String> currentPageAuthors = _livrosFiltrados
                  .map((livro) => livro['autor'].toString())
                  .toSet();

              searchedAuthors = currentPageAuthors.toList()..sort();
            }

            // Limita a 10 autores
            _filteredAuthors = searchedAuthors.take(10).toList();

            return AlertDialog(
              title: Text('Filtros'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção de Disponibilidade
                    Text(
                      'Disponibilidade',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<DisponibilidadeFilter>(
                      value: _disponibilidadeFilter,
                      isExpanded: true,
                      items: DisponibilidadeFilter.values.map((filter) {
                        String label = filter == DisponibilidadeFilter.todos
                            ? 'Todos'
                            : filter == DisponibilidadeFilter.sim
                                ? 'Disponível'
                                : 'Indisponível';
                        return DropdownMenuItem(
                          value: filter,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (DisponibilidadeFilter? value) {
                        setState(() {
                          _disponibilidadeFilter = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Seção de Ordenação
                    Text(
                      'Ordem',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _sortOrder,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'DESC',
                          child: Text('Mais recentes'),
                        ),
                        DropdownMenuItem(
                          value: 'ASC',
                          child: Text('Mais antigos'),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _sortOrder = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Seção de Autores
                    Text(
                      'Autores',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Campo de busca de autores
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar autor...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _authorSearchQuery = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Lista de autores filtrados
                    if (_selectedAuthors.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedAuthors.clear();
                            });
                          },
                          child: Text('Limpar seleção de autores'),
                        ),
                      ),

                    ..._filteredAuthors.map(
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
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Limpar Filtros'),
                  onPressed: () {
                    setState(() {
                      _selectedAuthors.clear();
                      _disponibilidadeFilter = DisponibilidadeFilter.todos;
                      _sortOrder = 'DESC';
                      _authorSearchQuery = '';
                    });
                  },
                ),
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Aplicar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _currentPage = 1;
                    _fetchLivros();
                  },
                ),
              ],
            );
          },
        );
      },
    );
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

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _fetchLivros();
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _fetchLivros();
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
                children: [
                  Expanded(
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

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LivroDetalhesScreen(livroId: livro['id']),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/logo_livros.jpeg'),
                    ),
                  ),
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
            ),
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
          TextButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage = 1;
                      _fetchLivros();
                    });
                  }
                : null,
            child: Text('1'),
            style: TextButton.styleFrom(
              foregroundColor: _currentPage == 1 ? Colors.grey : null,
            ),
          ),
          if (_currentPage > 1)
            TextButton(
              onPressed: _goToPreviousPage,
              child: Row(
                children: [
                  Icon(Icons.arrow_back, size: 16),
                  SizedBox(width: 4),
                  Text('${_currentPage - 1}'),
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
                  Text('${_currentPage + 1}'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          if (_totalPages > 1)
            TextButton(
              onPressed: _currentPage < _totalPages
                  ? () {
                      setState(() {
                        _currentPage = _totalPages;
                        _fetchLivros();
                      });
                    }
                  : null,
              child: Text('$_totalPages'),
              style: TextButton.styleFrom(
                foregroundColor:
                    _currentPage == _totalPages ? Colors.grey : null,
              ),
            ),
        ],
      ),
    );
  }
}
