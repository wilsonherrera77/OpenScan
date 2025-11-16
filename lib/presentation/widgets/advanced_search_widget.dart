import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/assignment.dart';

/// Advanced Search Widget
///
/// Provides enhanced search capabilities:
/// - Fuzzy search for name/document matching
/// - Advanced filters (date range, status, type)
/// - Multi-criteria filtering
/// - Search history
/// - Filter presets
/// - Real-time results
class AdvancedSearchWidget extends StatefulWidget {
  final Function(SearchCriteria) onSearch;
  final List<String> searchHistory;
  final VoidCallback? onClearHistory;

  const AdvancedSearchWidget({
    super.key,
    required this.onSearch,
    this.searchHistory = const [],
    this.onClearHistory,
  });

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _showFilters = false;
  AssignmentStatus? _selectedStatus;
  DateTimeRange? _dateRange;
  String? _selectedDocumentType;
  bool _fuzzySearch = true;

  final List<String> _documentTypes = [
    'Cédula',
    'Registro Civil',
    'Tarjeta de Identidad',
    'Certificado',
    'Acta',
    'Diploma',
    'Otro',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (_showFilters) ...[
          const SizedBox(height: 12),
          _buildFiltersPanel(),
        ],
        if (widget.searchHistory.isNotEmpty && _searchController.text.isEmpty)
          _buildSearchHistory(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: const InputDecoration(
                hintText: 'Buscar personas, documentos...',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length >= 2 || value.isEmpty) {
                  _performSearch();
                }
              },
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {});
                _performSearch();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _hasActiveFilters() ? Colors.teal : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Filtros avanzados',
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Filtros Avanzados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_hasActiveFilters())
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Limpiar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Status filter
            _buildFilterSection(
              title: 'Estado',
              child: Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'Todos',
                    isSelected: _selectedStatus == null,
                    onSelected: () {
                      setState(() {
                        _selectedStatus = null;
                      });
                      _performSearch();
                    },
                  ),
                  ...AssignmentStatus.values.map(
                    (status) => _buildFilterChip(
                      label: _getStatusLabel(status),
                      isSelected: _selectedStatus == status,
                      onSelected: () {
                        setState(() {
                          _selectedStatus = status;
                        });
                        _performSearch();
                      },
                      color: _getStatusColor(status),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Document type filter
            _buildFilterSection(
              title: 'Tipo de Documento',
              child: Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'Todos',
                    isSelected: _selectedDocumentType == null,
                    onSelected: () {
                      setState(() {
                        _selectedDocumentType = null;
                      });
                      _performSearch();
                    },
                  ),
                  ..._documentTypes.map(
                    (type) => _buildFilterChip(
                      label: type,
                      isSelected: _selectedDocumentType == type,
                      onSelected: () {
                        setState(() {
                          _selectedDocumentType = type;
                        });
                        _performSearch();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date range filter
            _buildFilterSection(
              title: 'Rango de Fechas',
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _dateRange == null
                            ? 'Seleccionar fechas'
                            : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  if (_dateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _dateRange = null;
                        });
                        _performSearch();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search options
            SwitchListTile(
              title: const Text(
                'Búsqueda difusa',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Permite errores de escritura',
                style: TextStyle(fontSize: 12),
              ),
              value: _fuzzySearch,
              onChanged: (value) {
                setState(() {
                  _fuzzySearch = value;
                });
                _performSearch();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 12),

            // Quick filter presets
            _buildQuickPresets(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey[100],
      selectedColor: (color ?? Colors.teal).withOpacity(0.2),
      checkmarkColor: color ?? Colors.teal,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? (color ?? Colors.teal) : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildQuickPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros Rápidos',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildPresetChip(
              label: 'Pendientes hoy',
              icon: Icons.today,
              onTap: () {
                setState(() {
                  _selectedStatus = AssignmentStatus.pending;
                  _dateRange = DateTimeRange(
                    start: DateTime.now(),
                    end: DateTime.now(),
                  );
                });
                _performSearch();
              },
            ),
            _buildPresetChip(
              label: 'Última semana',
              icon: Icons.calendar_week,
              onTap: () {
                setState(() {
                  _dateRange = DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  );
                });
                _performSearch();
              },
            ),
            _buildPresetChip(
              label: 'Completados',
              icon: Icons.check_circle,
              onTap: () {
                setState(() {
                  _selectedStatus = AssignmentStatus.completed;
                });
                _performSearch();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onPressed: onTap,
      backgroundColor: Colors.teal.withOpacity(0.1),
      labelStyle: const TextStyle(fontSize: 11, color: Colors.teal),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildSearchHistory() {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Búsquedas recientes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onClearHistory,
                  child: const Text(
                    'Limpiar',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...widget.searchHistory.take(5).map(
                (query) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.search, size: 18, color: Colors.grey),
                  title: Text(
                    query,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    _searchController.text = query;
                    _performSearch();
                  },
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _performSearch();
    }
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
        _selectedDocumentType != null ||
        _dateRange != null;
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDocumentType = null;
      _dateRange = null;
      _fuzzySearch = true;
    });
    _performSearch();
  }

  void _performSearch() {
    final criteria = SearchCriteria(
      query: _searchController.text,
      status: _selectedStatus,
      documentType: _selectedDocumentType,
      dateRange: _dateRange,
      fuzzySearch: _fuzzySearch,
    );

    widget.onSearch(criteria);
  }

  String _getStatusLabel(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return 'Pendiente';
      case AssignmentStatus.inProgress:
        return 'En Progreso';
      case AssignmentStatus.completed:
        return 'Completado';
      case AssignmentStatus.reviewed:
        return 'Revisado';
    }
  }

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return Colors.orange;
      case AssignmentStatus.inProgress:
        return Colors.blue;
      case AssignmentStatus.completed:
        return Colors.green;
      case AssignmentStatus.reviewed:
        return Colors.purple;
    }
  }
}

/// Search criteria model
class SearchCriteria {
  final String query;
  final AssignmentStatus? status;
  final String? documentType;
  final DateTimeRange? dateRange;
  final bool fuzzySearch;

  SearchCriteria({
    required this.query,
    this.status,
    this.documentType,
    this.dateRange,
    this.fuzzySearch = true,
  });

  bool get hasFilters =>
      status != null || documentType != null || dateRange != null;

  bool get isEmpty => query.isEmpty && !hasFilters;
}
