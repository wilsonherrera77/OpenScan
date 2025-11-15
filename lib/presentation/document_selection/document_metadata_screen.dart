import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/person.dart';
import '../providers/census_provider.dart';
import '../../screens/home_screen.dart';

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

  // Document types matching Paperless tags (IDs 10-16)
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

  void _proceedToScan() {
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

    // Store metadata in CensusProvider for use during upload
    final censusProvider = Provider.of<CensusProvider>(context, listen: false);
    censusProvider.setDocumentMetadata(
      documentType: _selectedDocumentType!,
      documentNumber: _documentNumberController.text.trim(),
    );

    // Navigate to OpenScan home
    Navigator.of(context).pushReplacementNamed(HomeScreen.route);
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
                        'Esta información se enviará a Paperless junto con el documento digitalizado.',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Continue Button
            ElevatedButton.icon(
              onPressed: _proceedToScan,
              icon: const Icon(Icons.camera_alt, size: 28),
              label: const Text(
                'Continuar a Escanear',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
