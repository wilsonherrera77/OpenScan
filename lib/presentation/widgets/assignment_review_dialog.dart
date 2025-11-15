import 'package:flutter/material.dart';
import '../../domain/entities/assignment.dart';

/// Assignment Review Dialog
/// Dialog for reviewers to approve or reject assignments
class AssignmentReviewDialog extends StatefulWidget {
  final PersonAssignment assignment;
  final Function(int qualityScore, String feedback) onApprove;
  final Function(String feedback, String issuesFound) onReject;

  const AssignmentReviewDialog({
    Key? key,
    required this.assignment,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  State<AssignmentReviewDialog> createState() => _AssignmentReviewDialogState();
}

class _AssignmentReviewDialogState extends State<AssignmentReviewDialog> {
  final _feedbackController = TextEditingController();
  final _issuesController = TextEditingController();
  double _qualityScore = 75.0;
  bool _isApproving = true;

  @override
  void dispose() {
    _feedbackController.dispose();
    _issuesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isApproving ? Icons.check_circle : Icons.cancel,
            color: _isApproving ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isApproving ? 'Aprobar Asignación' : 'Rechazar Asignación',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assignment.personName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('ID: ${widget.assignment.personId}'),
                    Text('Digitalizador: ${widget.assignment.digitizerName}'),
                    Text(
                      'Progreso: ${widget.assignment.digitizedDocuments}/${widget.assignment.requiredDocuments} documentos',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action selector
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isApproving = true),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isApproving ? Colors.green : Colors.grey[300],
                      foregroundColor: _isApproving ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isApproving = false),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isApproving ? Colors.red : Colors.grey[300],
                      foregroundColor: !_isApproving ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quality score slider (only for approve)
            if (_isApproving) ...[
              const Text(
                'Calificación de Calidad',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _qualityScore,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      label: _qualityScore.toInt().toString(),
                      onChanged: (value) => setState(() => _qualityScore = value),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${_qualityScore.toInt()}/100',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              Text(
                _getQualityLabel(_qualityScore.toInt()),
                style: TextStyle(
                  color: _getQualityColor(_qualityScore.toInt()),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Feedback text field
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                labelText: _isApproving ? 'Comentarios (opcional)' : 'Comentarios *',
                hintText: _isApproving
                    ? 'Trabajo excelente, buena calidad...'
                    : 'Por favor especifica los problemas encontrados',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Issues text field (only for reject)
            if (!_isApproving) ...[
              TextField(
                controller: _issuesController,
                decoration: const InputDecoration(
                  labelText: 'Problemas Encontrados (opcional)',
                  hintText: 'Imagen borrosa, datos incorrectos, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isApproving ? Colors.green : Colors.red,
          ),
          child: Text(_isApproving ? 'Aprobar' : 'Rechazar'),
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (_isApproving) {
      // Approve
      widget.onApprove(
        _qualityScore.toInt(),
        _feedbackController.text.trim(),
      );
    } else {
      // Reject - feedback is required
      if (_feedbackController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor proporciona comentarios al rechazar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onReject(
        _feedbackController.text.trim(),
        _issuesController.text.trim(),
      );
    }

    Navigator.of(context).pop();
  }

  String _getQualityLabel(int score) {
    if (score >= 90) return 'Excelente';
    if (score >= 75) return 'Bueno';
    if (score >= 60) return 'Aceptable';
    if (score >= 40) return 'Necesita mejora';
    return 'Deficiente';
  }

  Color _getQualityColor(int score) {
    if (score >= 90) return Colors.green[700]!;
    if (score >= 75) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }
}

/// Show assignment review dialog
Future<void> showAssignmentReviewDialog({
  required BuildContext context,
  required PersonAssignment assignment,
  required Function(int qualityScore, String feedback) onApprove,
  required Function(String feedback, String issuesFound) onReject,
}) async {
  await showDialog(
    context: context,
    builder: (context) => AssignmentReviewDialog(
      assignment: assignment,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}
