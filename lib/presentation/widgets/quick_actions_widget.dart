import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Quick Actions Widget
///
/// Provides keyboard shortcuts and gesture-based quick actions:
/// - Keyboard shortcuts for common operations
/// - Swipe gestures for navigation
/// - Long-press actions
/// - Quick capture from notification
class QuickActionsWidget extends StatefulWidget {
  final VoidCallback? onQuickCapture;
  final VoidCallback? onViewPending;
  final VoidCallback? onSync;
  final VoidCallback? onSearch;

  const QuickActionsWidget({
    super.key,
    this.onQuickCapture,
    this.onViewPending,
    this.onSync,
    this.onSearch,
  });

  @override
  State<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<QuickActionsWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onHorizontalDragEnd: _handleHorizontalDrag,
        child: _buildQuickActionsGrid(),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Ctrl/Cmd + N: Nueva captura
    if (event.logicalKey == LogicalKeyboardKey.keyN &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      widget.onQuickCapture?.call();
      _showToast(context, 'Captura rápida', Icons.camera_alt);
      return;
    }

    // Ctrl/Cmd + P: Ver pendientes
    if (event.logicalKey == LogicalKeyboardKey.keyP &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      widget.onViewPending?.call();
      _showToast(context, 'Pendientes', Icons.pending_actions);
      return;
    }

    // Ctrl/Cmd + R: Sincronizar
    if (event.logicalKey == LogicalKeyboardKey.keyR &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      widget.onSync?.call();
      _showToast(context, 'Sincronizando...', Icons.sync);
      return;
    }

    // Ctrl/Cmd + F: Búsqueda
    if (event.logicalKey == LogicalKeyboardKey.keyF &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      widget.onSearch?.call();
      _showToast(context, 'Buscar', Icons.search);
      return;
    }
  }

  void _handleHorizontalDrag(DragEndDetails details) {
    // Swipe right: Quick capture
    if (details.primaryVelocity! > 0) {
      widget.onQuickCapture?.call();
      HapticFeedback.mediumImpact();
      _showToast(context, 'Captura rápida', Icons.camera_alt);
    }
    // Swipe left: View pending
    else if (details.primaryVelocity! < 0) {
      widget.onViewPending?.call();
      HapticFeedback.mediumImpact();
      _showToast(context, 'Pendientes', Icons.pending_actions);
    }
  }

  Widget _buildQuickActionsGrid() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.help_outline, size: 20),
                  onPressed: () => _showShortcutsHelp(context),
                  tooltip: 'Ver atajos de teclado',
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionButton(
                  icon: Icons.camera_alt,
                  label: 'Capturar',
                  shortcut: 'Ctrl+N',
                  color: Colors.teal,
                  onTap: widget.onQuickCapture,
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    _showActionOptions(context, 'Capturar');
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.pending_actions,
                  label: 'Pendientes',
                  shortcut: 'Ctrl+P',
                  color: Colors.orange,
                  onTap: widget.onViewPending,
                ),
                _buildQuickActionButton(
                  icon: Icons.sync,
                  label: 'Sincronizar',
                  shortcut: 'Ctrl+R',
                  color: Colors.blue,
                  onTap: widget.onSync,
                ),
                _buildQuickActionButton(
                  icon: Icons.search,
                  label: 'Buscar',
                  shortcut: 'Ctrl+F',
                  color: Colors.purple,
                  onTap: widget.onSearch,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildGestureHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String shortcut,
    required Color color,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      shortcut,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.swipe, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Desliza → captura rápida | ← pendientes',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showShortcutsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: Colors.teal),
            SizedBox(width: 8),
            Text('Atajos de Teclado'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShortcutRow('Ctrl+N', 'Nueva captura', Icons.camera_alt),
              _buildShortcutRow('Ctrl+P', 'Ver pendientes', Icons.pending_actions),
              _buildShortcutRow('Ctrl+R', 'Sincronizar', Icons.sync),
              _buildShortcutRow('Ctrl+F', 'Buscar', Icons.search),
              const Divider(),
              const SizedBox(height: 8),
              _buildGestureRow('Deslizar →', 'Captura rápida'),
              _buildGestureRow('Deslizar ←', 'Ver pendientes'),
              _buildGestureRow('Mantener pulsado', 'Opciones'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String shortcut, String action, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(action)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureRow(String gesture, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.touch_app, color: Colors.blue, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(action, style: const TextStyle(fontSize: 13))),
          Text(
            gesture,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showActionOptions(BuildContext context, String actionType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Opciones de $actionType',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera, color: Colors.teal),
              title: const Text('Captura rápida'),
              subtitle: const Text('Abrir cámara directamente'),
              onTap: () {
                Navigator.pop(context);
                widget.onQuickCapture?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Desde galería'),
              subtitle: const Text('Seleccionar imagen existente'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement gallery selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner, color: Colors.orange),
              title: const Text('Escaneo múltiple'),
              subtitle: const Text('Capturar varios documentos'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement batch capture
              },
            ),
          ],
        ),
      ),
    );
  }
}
