import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assignment_provider.dart';

/// Session Indicator Widget
/// Shows active digitization session status
class SessionIndicatorWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const SessionIndicatorWidget({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentProvider>(
      builder: (context, provider, child) {
        if (!provider.hasActiveSession) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing indicator
                _PulsingDot(),
                const SizedBox(width: 8),
                const Text(
                  'Sesión activa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.access_time,
                  color: Colors.green,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pulsing dot animation
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Session Control Button Widget
/// Button to start/end digitization sessions
class SessionControlButton extends StatelessWidget {
  final int? assignmentId;

  const SessionControlButton({
    Key? key,
    this.assignmentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentProvider>(
      builder: (context, provider, child) {
        final hasActiveSession = provider.hasActiveSession;

        return ElevatedButton.icon(
          onPressed: () => _handleSessionToggle(context, provider),
          icon: Icon(hasActiveSession ? Icons.stop : Icons.play_arrow),
          label: Text(hasActiveSession ? 'Finalizar Sesión' : 'Iniciar Sesión'),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasActiveSession ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Future<void> _handleSessionToggle(
    BuildContext context,
    AssignmentProvider provider,
  ) async {
    if (provider.hasActiveSession) {
      // End session
      final confirm = await _showConfirmDialog(
        context,
        title: 'Finalizar Sesión',
        message: '¿Estás seguro de que quieres finalizar la sesión actual?',
      );

      if (confirm == true) {
        final success = await provider.endDigitizationSession();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Sesión finalizada exitosamente'
                    : 'Error al finalizar sesión',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } else {
      // Start session
      final success = await provider.startDigitizationSession(
        assignmentId: assignmentId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Sesión iniciada exitosamente'
                  : 'Error al iniciar sesión',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
