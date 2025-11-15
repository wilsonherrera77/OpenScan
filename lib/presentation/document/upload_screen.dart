import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/logger_adapter.dart';
import 'dart:io';
import '../../domain/entities/person.dart';
import '../../domain/entities/document_existence_check.dart';
import '../../services/upload_service.dart';
import '../../data/repositories/document_repository.dart';
import '../providers/census_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/assignment_provider.dart';
import '../widgets/document_exists_dialogs.dart';
import 'document_preview_screen.dart';

/// Upload Screen - Document Upload UI
/// Professional implementation with validation and error handling
class UploadScreen extends StatefulWidget {
  static const String route = '/upload';
  final File? initialImage;

  const UploadScreen({Key? key, this.initialImage}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _imageFile;
  String? _selectedDocType;
  final _docNumberController = TextEditingController();
  bool _isUploading = false;
  bool _isReplacement = false; // Track if this is a document replacement
  final LoggerAdapter _logger = LoggerAdapter();

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImage;
  }

  @override
  void dispose() {
    _docNumberController.dispose();
    super.dispose();
  }

  /// Check if document exists BEFORE opening camera
  /// This implements the anti-duplicate detection system for Jornada de Digitalización
  ///
  /// Flow:
  /// 1. Show checking dialog
  /// 2. Call backend to check if document exists
  /// 3. If exists with good quality → Show "already exists" dialog, DON'T capture
  /// 4. If exists with low quality → Ask user if wants to replace, capture if yes
  /// 5. If doesn't exist → Capture directly
  Future<void> _checkAndCapture() async {
    if (_selectedDocType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Primero selecciona el tipo de documento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final censusProvider = context.read<CensusProvider>();
    final person = censusProvider.selectedPerson;

    if (person == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No hay persona seleccionada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final documentRepository = context.read<DocumentRepository>();
    final docTypeLabel = _getDocumentTypeLabel(_selectedDocType!);

    _logger.i('🔍 Checking if document exists BEFORE capture');
    _logger.d('   Person: ${person.fullName} (${person.personId})');
    _logger.d('   Document Type: $docTypeLabel');

    // Show checking dialog
    showCheckingDialog(context);

    try {
      // Call backend to check if document exists
      // Returns DocumentExistenceCheck entity directly (not Map)
      final check = await documentRepository.checkDocumentExists(
        personId: person.personId,
        documentType: docTypeLabel,
      );

      // Dismiss checking dialog
      if (mounted) Navigator.of(context).pop();

      _logger.i('✅ Check completed: ${check.toString()}');

      // Handle based on existence status
      if (check.existsWithGoodQuality) {
        // Document exists with good quality - DON'T capture
        _logger.i('📄 Document exists with GOOD quality - showing info dialog');
        await showAlreadyExistsDialog(context, check);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Este documento ya fue digitalizado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return; // DON'T open camera
      } else if (check.existsWithLowQuality) {
        // Document exists with low quality - ASK user if wants to replace
        _logger.i('⚠️ Document exists with LOW quality - asking user');
        final shouldReplace = await showLowQualityDialog(context, check);

        if (shouldReplace) {
          _logger.i('✅ User chose to replace - opening camera');
          _isReplacement = true;
          await _pickImage(ImageSource.camera);
        } else {
          _logger.i('❌ User cancelled replacement');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Captura cancelada'),
                backgroundColor: Colors.grey,
              ),
            );
          }
        }
        return;
      } else {
        // Document doesn't exist - CAPTURE
        _logger.i('📸 Document does NOT exist - proceeding to capture');
        _isReplacement = false;
        await _pickImage(ImageSource.camera);
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to check document existence', error: e, stackTrace: stackTrace);

      // Dismiss checking dialog if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al verificar documento: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      _logger.i('📸 Image captured, opening preview screen');

      // Navigate to preview screen for quality validation and editing
      final validatedImage = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentPreviewScreen(
            imageFile: File(pickedFile.path),
            documentType: _getDocumentTypeLabel(_selectedDocType!),
            onRetake: () {
              // User chose to retake from preview screen
              // This callback allows preview screen to trigger retake
              _checkAndCapture();
            },
          ),
        ),
      );

      if (validatedImage != null && mounted) {
        _logger.i('✅ Image validated and approved');
        setState(() {
          _imageFile = validatedImage;
        });
      } else {
        _logger.i('❌ Image rejected or retake requested');
        // User rejected the image or chose to retake
        // _imageFile remains null, user can try again
      }
    }
  }

  /// Get document type label for API (maps from KEY to LABEL)
  String _getDocumentTypeLabel(String key) {
    const typeMapping = {
      'CEDULA_CIUDADANIA': 'Cédula de Ciudadanía',
      'TARJETA_IDENTIDAD': 'Tarjeta de Identidad',
      'REGISTRO_CIVIL': 'Registro Civil de Nacimiento',
      'CERTIFICADO_AFILIACION_EPS': 'Certificado EPS',
      'CERTIFICADO_ESTUDIO': 'Certificado de Estudio',
      'CERTIFICADO_DEFUNCION': 'Registro Civil de Defunción',
      'CERTIFICADO_MATRIMONIO': 'Registro Civil de Matrimonio',
      'OTRO_DOCUMENTO': 'Otro Documento',
    };

    return typeMapping[key] ?? key;
  }

  Future<void> _upload() async {
    if (_imageFile == null || _selectedDocType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Selecciona una imagen y tipo de documento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final censusProvider = context.read<CensusProvider>();
      final authProvider = context.read<AuthProvider>();
      final uploadService = context.read<UploadService>();
      final person = censusProvider.selectedPerson!;

      // Enqueue upload to local database queue
      // isReplacement flag is set by _checkAndCapture() based on user decision
      final uploadId = await uploadService.enqueueUpload(
        person: person,
        imageFile: _imageFile!,
        documentType: _selectedDocType!,
        documentNumber: _docNumberController.text.trim().isEmpty
            ? null
            : _docNumberController.text.trim(),
        digitizedBy: authProvider.username,
        isReplacement: _isReplacement, // Set by anti-duplicate check
      );

      _logger.i('📤 Document enqueued with ID $uploadId for ${person.fullName}');
      _logger.d('   Is replacement: $_isReplacement');

      // ⏱️ FASE 2: Increment session document count if session active
      final assignmentProvider = context.read<AssignmentProvider>();
      if (assignmentProvider.hasActiveSession) {
        await assignmentProvider.incrementSessionDocuments();
        _logger.d('✅ Session document count incremented');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isReplacement
                  ? '✅ Documento agregado a cola\nReemplazará el documento de baja calidad'
                  : '✅ Documento agregado a cola de sincronización',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Clear form and reset replacement flag
        setState(() {
          _imageFile = null;
          _selectedDocType = null;
          _docNumberController.clear();
          _isReplacement = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Upload enqueue failed', error: e, stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al agregar documento a cola: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final censusProvider = context.watch<CensusProvider>();
    final selectedPerson = censusProvider.selectedPerson;

    if (selectedPerson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subir Documento')),
        body: const Center(
          child: Text('No hay persona seleccionada'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Documento'),
        actions: [
          if (_imageFile != null && _selectedDocType != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isUploading ? null : _upload,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Person Info Card
            _PersonInfoCard(person: selectedPerson),
            const SizedBox(height: 16),

            // Document Type Selector (FIRST - before capture)
            _DocumentTypeSelector(
              selectedType: _selectedDocType,
              onChanged: (value) => setState(() {
                _selectedDocType = value;
                // Reset image and replacement flag when changing document type
                _imageFile = null;
                _isReplacement = false;
              }),
            ),

            const SizedBox(height: 16),

            // Capture Button or Image Preview
            if (_imageFile == null) ...[
              // Show capture button (calls _checkAndCapture)
              ElevatedButton.icon(
                onPressed: _selectedDocType != null ? _checkAndCapture : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capturar Documento'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      _selectedDocType == null
                          ? 'Primero selecciona el tipo de documento'
                          : 'El sistema verificará si este documento ya fue digitalizado',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedDocType != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.verified_user, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Anti-Duplicados Activado',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // Show image preview after capture
              _ImagePreviewCard(
                imageFile: _imageFile!,
                onRemove: () => setState(() {
                  _imageFile = null;
                  _isReplacement = false;
                }),
                onRetake: _checkAndCapture, // Re-check when retaking
              ),
            ],

            const SizedBox(height: 16),

            // Document Number (optional)
            TextField(
              controller: _docNumberController,
              decoration: const InputDecoration(
                labelText: 'Número de Documento (opcional)',
                hintText: 'Ej: 1234567890',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // Upload Button
            if (_imageFile != null && _selectedDocType != null)
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _upload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Subiendo...' : 'Subir Documento'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Supporting Widgets
class _PersonInfoCard extends StatelessWidget {
  final Person person;

  const _PersonInfoCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person, size: 20),
                SizedBox(width: 8),
                Text(
                  'Persona Seleccionada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            _InfoRow(label: 'Nombre', value: person.fullName),
            _InfoRow(label: 'ID', value: person.personId),
            if (person.familyId != null && person.familyId!.isNotEmpty)
              _InfoRow(label: 'Familia', value: person.familyId!),
            if (person.requiredDocumentsCount > 0)
              _InfoRow(
                label: 'Documentos pendientes',
                value: '${person.requiredDocumentsCount}',
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final Function(ImageSource) onPickImage;

  const _ImagePickerCard({required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.add_a_photo, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Selecciona una imagen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onPickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onPickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  final File imageFile;
  final VoidCallback onRemove;
  final VoidCallback onRetake;

  const _ImagePreviewCard({
    required this.imageFile,
    required this.onRemove,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.file(
            imageFile,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: onRetake,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Retomar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentTypeSelector extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onChanged;

  const _DocumentTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final documentTypes = [
      {'key': 'CEDULA_CIUDADANIA', 'label': 'Cédula de Ciudadanía'},
      {'key': 'TARJETA_IDENTIDAD', 'label': 'Tarjeta de Identidad'},
      {'key': 'REGISTRO_CIVIL', 'label': 'Registro Civil'},
      {'key': 'CERTIFICADO_AFILIACION_EPS', 'label': 'Certificado EPS'},
      {'key': 'CERTIFICADO_ESTUDIO', 'label': 'Certificado de Estudio'},
      {'key': 'CERTIFICADO_DEFUNCION', 'label': 'Certificado de Defunción'},
      {'key': 'CERTIFICADO_MATRIMONIO', 'label': 'Certificado de Matrimonio'},
      {'key': 'OTRO_DOCUMENTO', 'label': 'Otro Documento'},
    ];

    return DropdownButtonFormField<String>(
      value: selectedType,
      decoration: const InputDecoration(
        labelText: 'Tipo de Documento *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      items: documentTypes.map((type) {
        return DropdownMenuItem(
          value: type['key'],
          child: Text(type['label']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
