import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/assignment.dart';

/// Bulk Operations Widget
///
/// Provides multi-selection capabilities for documents:
/// - Select multiple documents/assignments
/// - Bulk assign to digitizer
/// - Bulk status update
/// - Bulk delete/archive
/// - Visual feedback for selected items
class BulkOperationsWidget<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, bool, ValueChanged<bool>) itemBuilder;
  final String itemTypeName;
  final Future<void> Function(List<T>)? onBulkAssign;
  final Future<void> Function(List<T>)? onBulkStatusChange;
  final Future<void> Function(List<T>)? onBulkDelete;
  final Future<void> Function(List<T>)? onBulkExport;

  const BulkOperationsWidget({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemTypeName = 'items',
    this.onBulkAssign,
    this.onBulkStatusChange,
    this.onBulkDelete,
    this.onBulkExport,
  });

  @override
  State<BulkOperationsWidget<T>> createState() => _BulkOperationsWidgetState<T>();
}

class _BulkOperationsWidgetState<T> extends State<BulkOperationsWidget<T>> {
  final Set<T> _selectedItems = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isSelectionMode) _buildSelectionToolbar(),
        Expanded(
          child: ListView.builder(
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isSelected = _selectedItems.contains(item);

              return widget.itemBuilder(
                context,
                item,
                isSelected,
                (selected) => _toggleSelection(item, selected),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionToolbar() {
    final selectedCount = _selectedItems.length;
    final totalCount = widget.items.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.teal.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _exitSelectionMode,
            tooltip: 'Cancelar selección',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$selectedCount de $totalCount seleccionados',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildActionButton(
            icon: Icons.select_all,
            label: 'Todos',
            onPressed: _selectAll,
            tooltip: 'Seleccionar todos',
          ),
          const SizedBox(width: 8),
          PopupMenuButton<BulkAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Acciones masivas',
            onSelected: _handleBulkAction,
            itemBuilder: (context) => [
              if (widget.onBulkAssign != null)
                const PopupMenuItem(
                  value: BulkAction.assign,
                  child: Row(
                    children: [
                      Icon(Icons.person_add, size: 20),
                      SizedBox(width: 12),
                      Text('Asignar'),
                    ],
                  ),
                ),
              if (widget.onBulkStatusChange != null)
                const PopupMenuItem(
                  value: BulkAction.changeStatus,
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Cambiar estado'),
                    ],
                  ),
                ),
              if (widget.onBulkExport != null)
                const PopupMenuItem(
                  value: BulkAction.export,
                  child: Row(
                    children: [
                      Icon(Icons.file_download, size: 20),
                      SizedBox(width: 12),
                      Text('Exportar'),
                    ],
                  ),
                ),
              if (widget.onBulkDelete != null)
                const PopupMenuItem(
                  value: BulkAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _toggleSelection(T item, bool selected) {
    HapticFeedback.selectionClick();

    setState(() {
      if (selected) {
        _selectedItems.add(item);
        if (!_isSelectionMode) {
          _isSelectionMode = true;
        }
      } else {
        _selectedItems.remove(item);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      }
    });
  }

  void _selectAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedItems.clear();
      _selectedItems.addAll(widget.items);
      _isSelectionMode = true;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _handleBulkAction(BulkAction action) async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un elemento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedList = _selectedItems.toList();

    switch (action) {
      case BulkAction.assign:
        await _executeBulkAction(
          action: () => widget.onBulkAssign!(selectedList),
          successMessage: 'Asignación masiva exitosa',
          confirmMessage:
              '¿Asignar ${selectedList.length} ${widget.itemTypeName}?',
        );
        break;

      case BulkAction.changeStatus:
        await _showStatusChangeDialog(selectedList);
        break;

      case BulkAction.export:
        await _executeBulkAction(
          action: () => widget.onBulkExport!(selectedList),
          successMessage: 'Exportación iniciada',
          confirmMessage:
              '¿Exportar ${selectedList.length} ${widget.itemTypeName}?',
        );
        break;

      case BulkAction.delete:
        await _executeBulkAction(
          action: () => widget.onBulkDelete!(selectedList),
          successMessage: 'Eliminación masiva exitosa',
          confirmMessage:
              '¿ELIMINAR ${selectedList.length} ${widget.itemTypeName}? Esta acción no se puede deshacer.',
          isDangerous: true,
        );
        break;
    }
  }

  Future<void> _executeBulkAction({
    required Future<void> Function() action,
    required String successMessage,
    required String confirmMessage,
    bool isDangerous = false,
  }) async {
    final confirmed = await _showConfirmDialog(
      message: confirmMessage,
      isDangerous: isDangerous,
    );

    if (!confirmed) return;

    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Procesando...'),
                ],
              ),
            ),
          ),
        ),
      );

      await action();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      HapticFeedback.heavyImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(successMessage),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      _exitSelectionMode();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog({
    required String message,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDangerous ? Icons.warning : Icons.info,
              color: isDangerous ? Colors.red : Colors.teal,
            ),
            const SizedBox(width: 8),
            const Text('Confirmar acción'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? Colors.red : Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _showStatusChangeDialog(List<T> selectedItems) async {
    AssignmentStatus? newStatus;

    final result = await showDialog<AssignmentStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el nuevo estado para ${selectedItems.length} elementos:'),
            const SizedBox(height: 16),
            ...AssignmentStatus.values.map(
              (status) => RadioListTile<AssignmentStatus>(
                title: Text(_getStatusLabel(status)),
                value: status,
                groupValue: newStatus,
                onChanged: (value) {
                  newStatus = value;
                  Navigator.pop(context, value);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (result != null && widget.onBulkStatusChange != null) {
      await _executeBulkAction(
        action: () => widget.onBulkStatusChange!(selectedItems),
        successMessage: 'Estado actualizado',
        confirmMessage:
            '¿Cambiar estado de ${selectedItems.length} elementos a ${_getStatusLabel(result)}?',
      );
    }
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
}

/// Bulk action types
enum BulkAction {
  assign,
  changeStatus,
  export,
  delete,
}

/// Selectable List Tile for bulk operations
class SelectableListTile extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SelectableListTile({
    super.key,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.teal.withOpacity(0.1),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              if (value != null) {
                onSelectionChanged(value);
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          leading,
        ],
      ),
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: () {
        onSelectionChanged(!isSelected);
        onTap?.call();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onSelectionChanged(!isSelected);
      },
    );
  }
}
