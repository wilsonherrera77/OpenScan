import 'package:flutter/material.dart';
import '../../domain/entities/document_existence_check.dart';

/// Show dialog when document already exists with GOOD quality (>= 80%)
///
/// User CANNOT replace the document. This dialog is informational only.
///
/// Returns: void (no action needed)
Future<void> showAlreadyExistsDialog(
  BuildContext context,
  DocumentExistenceCheck check,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap OK
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 64,
        ),
        title: const Text(
          'Documento Ya Digitalizado',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message
              Text(
                check.message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Document info
              if (check.existingDocument != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.description,
                  label: 'Documento',
                  value: check.existingDocument!.title,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Digitalizado',
                  value: check.existingDocument!.formattedDate,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.person,
                  label: 'Por',
                  value: check.existingDocument!.digitizedBy.isNotEmpty
                      ? check.existingDocument!.digitizedBy
                      : 'Usuario del sistema',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.verified,
                  label: 'Calidad OCR',
                  value: '${check.ocrQualityPercentage}%',
                  valueColor: Colors.green,
                ),
                if (check.existingDocument!.nuipExtracted != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.badge,
                    label: 'NUIP Extraído',
                    value: check.existingDocument!.nuipExtracted!,
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Entendido',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    },
  );
}

/// Show dialog when document exists but with LOW quality (< 80%)
///
/// User CAN choose to replace the document with a better quality capture.
///
/// Returns: true if user wants to replace, false if user cancels
Future<bool> showLowQualityDialog(
  BuildContext context,
  DocumentExistenceCheck check,
) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false, // User must choose an option
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 64,
        ),
        title: const Text(
          'Documento de Baja Calidad',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message
              const Text(
                'Este documento ya fue digitalizado, pero tiene baja calidad '
                'o faltan datos importantes.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Quality indicator
              if (check.ocrQualityPercentage != null) ...[
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${check.ocrQualityPercentage}%',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Text(
                        'Calidad OCR',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Issues detected
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Problemas detectados:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (check.ocrQualityPercentage != null &&
                  check.ocrQualityPercentage! < 80)
                _IssueItem(
                  icon: Icons.visibility_off,
                  text: 'Calidad OCR inferior al 80%',
                ),

              if (check.hasMinimumData == false)
                _IssueItem(
                  icon: Icons.badge,
                  text: 'NUIP no extraído correctamente',
                ),

              const SizedBox(height: 16),

              // Document info
              if (check.existingDocument != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Digitalizado',
                  value: check.existingDocument!.formattedDate,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.person,
                  label: 'Por',
                  value: check.existingDocument!.digitizedBy.isNotEmpty
                      ? check.existingDocument!.digitizedBy
                      : 'Usuario del sistema',
                ),
              ],

              const SizedBox(height: 24),

              // Recommendation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recomendamos capturar una nueva foto con mejor '
                        'iluminación y enfoque.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Capturar Mejor Versión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    },
  ) ?? false; // Default to false if dialog is dismissed
}

/// Show loading dialog while checking document existence
///
/// Call Navigator.pop(context) to dismiss this dialog when check is complete
void showCheckingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Verificando documento...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Esto solo toma unos segundos',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    },
  );
}

// Supporting widgets

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IssueItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IssueItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
