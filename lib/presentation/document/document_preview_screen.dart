import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/logger_adapter.dart';
import '../../core/utils/image_quality_checker.dart';
import '../../services/document_scanner_service.dart';
import '../../services/hybrid_ocr_service.dart';

/// Document Preview Screen
/// Enhanced preview with quality validation and editing capabilities
///
/// Features:
/// - Full-screen image preview with zoom
/// - Quality score and indicators
/// - Image editing (crop, rotate)
/// - Re-capture option
/// - Clear visual feedback
class DocumentPreviewScreen extends StatefulWidget {
  static const String route = '/document-preview';

  final File imageFile;
  final String documentType;
  final VoidCallback onRetake;

  const DocumentPreviewScreen({
    Key? key,
    required this.imageFile,
    required this.documentType,
    required this.onRetake,
  }) : super(key: key);

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  final LoggerAdapter _logger = LoggerAdapter();
  final ImageQualityChecker _qualityChecker = ImageQualityChecker();
  final DocumentScannerService _scannerService = DocumentScannerService();
  final HybridOcrService _ocrService = HybridOcrService();

  File? _currentImage;
  ImageQualityResult? _qualityResult;
  HybridOcrResult? _ocrResult;
  bool _isProcessing = false;
  bool _isCheckingQuality = true;
  bool _isRunningOcr = false;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.imageFile;
    _checkQuality();
  }

  /// Check image quality
  Future<void> _checkQuality() async {
    setState(() => _isCheckingQuality = true);

    try {
      final result = await _qualityChecker.checkQuality(_currentImage!.path);

      if (mounted) {
        setState(() {
          _qualityResult = result;
          _isCheckingQuality = false;
        });

        _logger.i('📊 Quality check: ${result.score}% - ${result.qualityLevel}');
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to check quality', error: e, stackTrace: stackTrace);

      if (mounted) {
        setState(() => _isCheckingQuality = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ No se pudo verificar calidad: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Crop image
  Future<void> _cropImage() async {
    setState(() => _isProcessing = true);

    try {
      _logger.i('✂️ Opening crop editor');

      final croppedPath = await _scannerService.cropImage(_currentImage!.path);

      if (croppedPath != null && mounted) {
        _logger.i('✅ Image cropped successfully');

        setState(() {
          _currentImage = File(croppedPath);
          _isProcessing = false;
        });

        // Re-check quality after cropping
        await _checkQuality();
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to crop image', error: e, stackTrace: stackTrace);

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al recortar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Rotate image
  Future<void> _rotateImage() async {
    setState(() => _isProcessing = true);

    try {
      _logger.i('🔄 Rotating image 90°');

      final rotatedPath = await _scannerService.rotateImage(
        _currentImage!.path,
        degrees: 90,
      );

      if (rotatedPath != null && mounted) {
        _logger.i('✅ Image rotated successfully');

        setState(() {
          _currentImage = File(rotatedPath);
          _isProcessing = false;
        });

        // Re-check quality after rotation
        await _checkQuality();
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to rotate image', error: e, stackTrace: stackTrace);

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al rotar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Confirm image and return to upload screen
  void _confirmImage() {
    _logger.i('✅ Image confirmed with quality ${_qualityResult?.score}%');
    Navigator.of(context).pop(_currentImage);
  }

  /// Retake image
  void _retakeImage() {
    _logger.i('📸 User chose to retake image');
    Navigator.of(context).pop(null);
    widget.onRetake();
  }

  /// Run OCR on image
  Future<void> _runOcr() async {
    setState(() => _isRunningOcr = true);

    try {
      _logger.i('🔍 Running OCR on image');

      final result = await _ocrService.processDocument(
        _currentImage!.path,
        expectedDocumentType: widget.documentType,
      );

      if (mounted) {
        setState(() {
          _ocrResult = result;
          _isRunningOcr = false;
        });

        _logger.i('✅ OCR completed: ${result.toString()}');

        // Show result dialog
        await _showOcrResultDialog(result);
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to run OCR', error: e, stackTrace: stackTrace);

      if (mounted) {
        setState(() => _isRunningOcr = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al procesar OCR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show OCR result dialog
  Future<void> _showOcrResultDialog(HybridOcrResult result) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.usedLocalOcr ? Icons.phone_android : Icons.cloud,
              color: result.usedLocalOcr ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.usedLocalOcr ? 'OCR Local' : 'OCR Cloud',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Document type
              _OcrResultField(
                label: 'Tipo de Documento',
                value: result.documentTypeLabel,
                icon: Icons.description,
              ),
              const SizedBox(height: 12),

              // Confidence
              _OcrResultField(
                label: 'Confianza',
                value: '${result.confidencePercent}%',
                icon: Icons.analytics,
                valueColor: result.confidence >= 0.7 ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 12),

              // Processing info
              Row(
                children: [
                  Expanded(
                    child: _OcrResultField(
                      label: 'Tiempo',
                      value: '${result.processingTime.inSeconds}s',
                      icon: Icons.timer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OcrResultField(
                      label: 'Ahorro',
                      value: '${result.costSavings}%',
                      icon: Icons.savings,
                      valueColor: Colors.green,
                    ),
                  ),
                ],
              ),

              if (result.fields.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Campos Extraídos:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.fields.entries.map((entry) {
                  final value = entry.value;
                  if (value == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _OcrResultField(
                      label: _formatFieldLabel(entry.key),
                      value: value.toString(),
                      icon: Icons.label,
                    ),
                  );
                }).toList(),
              ],

              if (result.fullText.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Texto Completo:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(
                      result.fullText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Format field label for display
  String _formatFieldLabel(String key) {
    final labels = {
      'document_number': 'Número Documento',
      'identification_number': 'Número Identificación',
      'names': 'Nombres',
      'dates': 'Fechas',
      'places': 'Lugares',
      'expedition_date': 'Fecha Expedición',
      'expedition_place': 'Lugar Expedición',
      'birth_date': 'Fecha Nacimiento',
      'birth_place': 'Lugar Nacimiento',
      'parents': 'Padres',
      'eps_name': 'Nombre EPS',
      'regime': 'Régimen',
      'affiliation_date': 'Fecha Afiliación',
    };

    return labels[key] ?? key;
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Vista Previa'),
        actions: [
          if (_qualityResult != null && _qualityResult!.isAcceptable)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: _isProcessing ? null : _confirmImage,
              tooltip: 'Confirmar',
            ),
        ],
      ),
      body: _isCheckingQuality
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Verificando calidad...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Image preview with zoom
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(_currentImage!),
                  ),
                ),

                // Quality indicator overlay (top)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _QualityIndicator(
                    qualityResult: _qualityResult,
                    documentType: widget.documentType,
                  ),
                ),

                // Controls (bottom)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _ControlPanel(
                    isProcessing: _isProcessing,
                    isRunningOcr: _isRunningOcr,
                    qualityResult: _qualityResult,
                    ocrResult: _ocrResult,
                    onCrop: _cropImage,
                    onRotate: _rotateImage,
                    onRetake: _retakeImage,
                    onRunOcr: _runOcr,
                    onConfirm: _confirmImage,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Quality Indicator Widget
class _QualityIndicator extends StatelessWidget {
  final ImageQualityResult? qualityResult;
  final String documentType;

  const _QualityIndicator({
    required this.qualityResult,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    if (qualityResult == null) {
      return const SizedBox.shrink();
    }

    final result = qualityResult!;
    final color = _getQualityColor(result.score);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(_getQualityIcon(result.score), color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  documentType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _QualityBadge(score: result.score, level: result.qualityLevel),
            ],
          ),

          const SizedBox(height: 12),

          // Quality score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 8),

          // Details
          if (result.width != null && result.height != null)
            _DetailRow(
              icon: Icons.photo_size_select_large,
              text: '${result.width}x${result.height} px',
            ),

          // Issues (critical)
          ...result.issues.map((issue) => _DetailRow(
                icon: Icons.error,
                text: issue,
                color: Colors.red,
              )),

          // Warnings (non-critical)
          ...result.warnings.map((warning) => _DetailRow(
                icon: Icons.warning,
                text: warning,
                color: Colors.orange,
              )),

          // Recommendations
          if (!result.isAcceptable) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Calidad insuficiente. Recomendamos retomar la foto.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getQualityColor(int score) {
    if (score >= 75) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getQualityIcon(int score) {
    if (score >= 75) return Icons.check_circle;
    if (score >= 60) return Icons.warning;
    return Icons.error;
  }
}

/// Quality Badge
class _QualityBadge extends StatelessWidget {
  final int score;
  final String level;

  const _QualityBadge({required this.score, required this.level});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            level,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    if (score >= 75) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// Detail Row
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _DetailRow({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color ?? Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Control Panel
class _ControlPanel extends StatelessWidget {
  final bool isProcessing;
  final bool isRunningOcr;
  final ImageQualityResult? qualityResult;
  final HybridOcrResult? ocrResult;
  final VoidCallback onCrop;
  final VoidCallback onRotate;
  final VoidCallback onRetake;
  final VoidCallback onRunOcr;
  final VoidCallback onConfirm;

  const _ControlPanel({
    required this.isProcessing,
    required this.isRunningOcr,
    required this.qualityResult,
    this.ocrResult,
    required this.onCrop,
    required this.onRotate,
    required this.onRetake,
    required this.onRunOcr,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canConfirm = qualityResult != null && qualityResult!.isAcceptable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: Icons.crop,
                label: 'Recortar',
                onPressed: isProcessing ? null : onCrop,
              ),
              _ControlButton(
                icon: Icons.rotate_right,
                label: 'Rotar',
                onPressed: isProcessing ? null : onRotate,
              ),
              _ControlButton(
                icon: isRunningOcr ? Icons.hourglass_empty : Icons.text_fields,
                label: isRunningOcr ? 'OCR...' : 'OCR',
                onPressed: (isProcessing || isRunningOcr) ? null : onRunOcr,
                color: ocrResult != null
                    ? (ocrResult!.usedLocalOcr ? Colors.green : Colors.blue)
                    : Colors.purple,
              ),
              _ControlButton(
                icon: Icons.camera_alt,
                label: 'Retomar',
                onPressed: isProcessing ? null : onRetake,
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isProcessing || !canConfirm) ? null : onConfirm,
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(canConfirm ? Icons.check : Icons.error),
              label: Text(
                isProcessing
                    ? 'Procesando...'
                    : canConfirm
                        ? 'Confirmar Imagen'
                        : 'Calidad Insuficiente',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: canConfirm ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          if (!canConfirm && qualityResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Recomendamos retomar la foto para mejor calidad',
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// OCR Result Field widget
class _OcrResultField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _OcrResultField({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Control Button
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: color ?? Colors.white,
          iconSize: 32,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
