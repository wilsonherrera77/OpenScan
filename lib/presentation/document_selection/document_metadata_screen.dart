import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/person.dart';
import '../providers/census_provider.dart';
import '../../screens/home_screen.dart';
import '../../data/repositories/document_repository.dart';
import 'package:logger/logger.dart';

/// Document Metadata Selection Screen
/// Allows user to select document type and enter document number after person selection
class DocumentMetadataScreen extends StatefulWidget {
  static const String route = '/document-metadata';

  final Person person;

  const DocumentMetadataScreen({
    Key? key,
    required this.person,
  }) : super(key: key);

  @override
  State<DocumentMetadataScreen> createState() => _DocumentMetadataScreenState();
}

class _DocumentMetadataScreenState extends State<DocumentMetadataScreen> {
  String? _selectedDocumentType;
  final _documentNumberController = TextEditingController();
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  bool _isCheckingDuplicate = false;

  // Document types matching Tejido tags (IDs 10-16)
  final Map<String, int> _documentTypes = {
    'Registro Civil de Nacimiento': 10,
    'Tarjeta de Identidad': 11,
    'Cédula de Ciudadanía': 12,
    'Registro Civil de Matrimonio': 13,
    'Registro Civil de Defunción': 14,
    'PPT/PEP': 15,
    'Árbol Genealógico': 16,
  };

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  /// PRE-captura: Verificar si documento ya existe ANTES de capturar
  Future<void> _proceedToScan() async {
    if (_selectedDocumentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Selecciona el tipo de documento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_documentNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Ingresa el número de documento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // v6.4.17: PRE-captura duplicate check
    setState(() => _isCheckingDuplicate = true);

    try {
      final documentRepository = Provider.of<DocumentRepository>(context, listen: false);

      _logger.i('🔍 PRE-captura: Verificando duplicados para ${widget.person.fullName} - $_selectedDocumentType');

      final check = await documentRepository.checkDocumentExists(
        personId: widget.person.personId,
        documentType: _selectedDocumentType!,
      );

      if (check.exists) {
        // Documento ya existe - mostrar diálogo de confirmación
        final ocrConfidence = check.ocrConfidence ?? 1.0;
        final createdAt = check.existingDocument?.formattedDate ?? 'desconocida';

        _logger.w('⚠️ Documento duplicado detectado PRE-captura: OCR=${check.ocrQualityPercentage}%');

        if (!mounted) return;

        final shouldProceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Expanded(child: Text('Documento ya existe', overflow: TextOverflow.ellipsis)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.person.fullName} ya tiene este documento:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📄 $_selectedDocumentType'),
                      Text('📅 Fecha: $createdAt'),
                      Text('🔍 Calidad OCR: ${check.ocrQualityPercentage ?? 0}%'),
                      if (check.existingDocument?.digitizedBy != null)
                        Text('👤 Digitalizado por: ${check.existingDocument!.digitizedBy}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  check.canReplace == true
                      ? '💡 La calidad OCR es baja. Puedes capturar una nueva versión para reemplazarla.'
                      : '⚠️ Este documento ya tiene buena calidad. ¿Estás seguro de capturar otro?',
                  style: TextStyle(
                    color: check.canReplace == true ? Colors.green.shade700 : Colors.orange.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.camera_alt),
                label: Text(check.canReplace == true ? 'Reemplazar' : 'Capturar de todos modos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: check.canReplace == true ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        );

        if (shouldProceed != true) {
          _logger.i('❌ Usuario canceló captura de documento duplicado');
          return;
        }

        _logger.i('✅ Usuario confirmó reemplazo de documento');
      } else {
        _logger.i('✅ No hay duplicados - procediendo a captura');
      }
    } catch (e) {
      // Si falla la verificación, permitir continuar (fail-open para no bloquear)
      _logger.w('⚠️ Error verificando duplicados (continuando): $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingDuplicate = false);
      }
    }

    // Store metadata in CensusProvider for use during upload
    final censusProvider = Provider.of<CensusProvider>(context, listen: false);
    censusProvider.setDocumentMetadata(
      documentType: _selectedDocumentType!,
      documentNumber: _documentNumberController.text.trim(),
    );

    // Navigate to Lumara home
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos del Documento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Person Info Card
            Card(
              color: Colors.green.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Persona seleccionada:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      widget.person.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.person.documentNumber != null)
                      Text(
                        'Cédula: ${widget.person.documentNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Document Type Selection
            const Text(
              '1. Tipo de Documento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona el tipo de documento que vas a digitalizar:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedDocumentType,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.description),
                hintText: 'Seleccionar tipo de documento...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
              items: _documentTypes.keys.map((String docType) {
                return DropdownMenuItem<String>(
                  value: docType,
                  child: Text(
                    docType,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDocumentType = newValue;
                });
              },
            ),

            const SizedBox(height: 32),

            // Document Number Input
            const Text(
              '2. Número de Documento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa el número único del documento (ej: número de cédula):',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _documentNumberController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.numbers),
                hintText: 'Ej: 1234567890',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 32),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esta información se enviará a Tejido junto con el documento digitalizado.',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Continue Button with loading state
            ElevatedButton.icon(
              onPressed: _isCheckingDuplicate ? null : _proceedToScan,
              icon: _isCheckingDuplicate
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt, size: 28),
              label: Text(
                _isCheckingDuplicate ? 'Verificando...' : 'Continuar a Escanear',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.green.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
