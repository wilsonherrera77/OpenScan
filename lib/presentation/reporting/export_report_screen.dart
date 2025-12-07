import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/local/database/app_database.dart';
import '../../services/reporting_service.dart';

/// Export Report Screen
///
/// Allows exporting reports to PDF or Excel format
class ExportReportScreen extends StatefulWidget {
  static const String route = '/export-report';

  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  late ReportingService _reportingService;
  String? _selectedFormat;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final database = Provider.of<AppDatabase>(context, listen: false);
    _reportingService = ReportingService(database);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Reportes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el formato de exportación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFormatOption(
              'PDF',
              'Documento PDF para impresión o compartir',
              Icons.picture_as_pdf,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildFormatOption(
              'Excel',
              'Hoja de cálculo Excel para análisis',
              Icons.table_chart,
              Colors.green,
            ),
            const SizedBox(height: 24),
            if (_selectedFormat != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              _buildReportOptions(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportReport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isExporting ? 'Exportando...' : 'Exportar Reporte',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    String format,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedFormat == format;

    return Card(
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFormat = format;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opciones del reporte',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Incluir estadísticas generales'),
          value: true,
          onChanged: null, // Always included
        ),
        CheckboxListTile(
          title: const Text('Incluir reportes por familia'),
          value: true,
          onChanged: (value) {},
        ),
        CheckboxListTile(
          title: const Text('Incluir tendencias diarias'),
          value: true,
          onChanged: (value) {},
        ),
      ],
    );
  }

  Future<void> _exportReport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      if (_selectedFormat == 'PDF') {
        await _exportToPDF();
      } else if (_selectedFormat == 'Excel') {
        await _exportToExcel();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte exportado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportToPDF() async {
    // Load data
    final overallStats = await _reportingService.getOverallStatistics();
    final familyStats = await _reportingService.getFamilyStatistics();
    final dailyTrends = await _reportingService.getDailyTrends(days: 7);

    // Create PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Reporte de Digitalización',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),

          // Overall Statistics
          pw.Text(
            'Estadísticas Generales',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Métrica', 'Valor'],
            data: [
              ['Documentos Totales', overallStats.totalDocuments.toString()],
              ['Personas Únicas', overallStats.uniquePersons.toString()],
              ['Familias Únicas', overallStats.uniqueFamilies.toString()],
              ['Tamaño Total', ReportingService.formatBytes(overallStats.totalSize)],
              ['Tasa de Éxito', '${overallStats.successRate.toStringAsFixed(1)}%'],
              ['Últimos 7 días', overallStats.recentUploadsLast7Days.toString()],
            ],
          ),
          pw.SizedBox(height: 20),

          // Family Statistics
          pw.Text(
            'Top 10 Familias',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Familia', 'Documentos', 'Personas', 'Tamaño'],
            data: familyStats.take(10).map((family) => [
              family.familyId,
              family.totalDocuments.toString(),
              family.uniquePersons.toString(),
              ReportingService.formatBytes(family.totalSize),
            ]).toList(),
          ),
          pw.SizedBox(height: 20),

          // Daily Trends
          pw.Text(
            'Tendencia Últimos 7 Días',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Fecha', 'Documentos', 'Personas', 'Tamaño'],
            data: dailyTrends.map((day) => [
              '${day.date.day}/${day.date.month}/${day.date.year}',
              day.documentCount.toString(),
              day.uniquePersons.toString(),
              ReportingService.formatBytes(day.totalSize),
            ]).toList(),
          ),

          // Footer
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generado el: ${DateTime.now().toString().split('.')[0]}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.Text(
            'Lumara Indígenas - Sistema de Digitalización',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );

    // Save and share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'reporte_digitalizacion_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _exportToExcel() async {
    // Load data
    final overallStats = await _reportingService.getOverallStatistics();
    final familyStats = await _reportingService.getFamilyStatistics();
    final personStats = await _reportingService.getPersonStatistics();
    final dailyTrends = await _reportingService.getDailyTrends(days: 30);

    // Create Excel
    final excel = excel_lib.Excel.createExcel();

    // Overall Statistics Sheet
    final overallSheet = excel['Estadísticas Generales'];
    overallSheet.appendRow([excel_lib.TextCellValue('Métrica'), excel_lib.TextCellValue('Valor')]);
    overallSheet.appendRow([excel_lib.TextCellValue('Documentos Totales'), excel_lib.IntCellValue(overallStats.totalDocuments)]);
    overallSheet.appendRow([excel_lib.TextCellValue('Documentos Pendientes'), excel_lib.IntCellValue(overallStats.pendingDocuments)]);
    overallSheet.appendRow([excel_lib.TextCellValue('Documentos Fallidos'), excel_lib.IntCellValue(overallStats.failedDocuments)]);
    overallSheet.appendRow([excel_lib.TextCellValue('Personas Únicas'), excel_lib.IntCellValue(overallStats.uniquePersons)]);
    overallSheet.appendRow([excel_lib.TextCellValue('Familias Únicas'), excel_lib.IntCellValue(overallStats.uniqueFamilies)]);
    overallSheet.appendRow([excel_lib.TextCellValue('Tamaño Total'), excel_lib.TextCellValue(ReportingService.formatBytes(overallStats.totalSize))]);
    overallSheet.appendRow([excel_lib.TextCellValue('Tasa de Éxito'), excel_lib.TextCellValue('${overallStats.successRate.toStringAsFixed(1)}%')]);
    overallSheet.appendRow([excel_lib.TextCellValue('Últimos 7 días'), excel_lib.IntCellValue(overallStats.recentUploadsLast7Days)]);

    // Helper to convert values to CellValue
    List<excel_lib.CellValue> _toCellValues(List<dynamic> values) {
      return values.map((v) {
        if (v is int) return excel_lib.IntCellValue(v);
        return excel_lib.TextCellValue(v.toString());
      }).toList();
    }

    // Family Statistics Sheet
    final familySheet = excel['Reportes por Familia'];
    familySheet.appendRow(_toCellValues(['Familia ID', 'Documentos', 'Personas', 'Tamaño', 'Última Carga']));
    for (var family in familyStats) {
      familySheet.appendRow(_toCellValues([
        family.familyId,
        family.totalDocuments,
        family.uniquePersons,
        ReportingService.formatBytes(family.totalSize),
        family.lastUploadDate?.toString() ?? 'N/A',
      ]));
    }

    // Person Statistics Sheet
    final personSheet = excel['Reportes por Persona'];
    personSheet.appendRow(_toCellValues(['Persona ID', 'Nombre', 'Familia ID', 'Documentos', 'Tamaño', 'Última Carga']));
    for (var person in personStats) {
      personSheet.appendRow(_toCellValues([
        person.personId,
        person.personName,
        person.familyId,
        person.totalDocuments,
        ReportingService.formatBytes(person.totalSize),
        person.lastUploadDate?.toString() ?? 'N/A',
      ]));
    }

    // Daily Trends Sheet
    final trendsSheet = excel['Tendencias Diarias'];
    trendsSheet.appendRow(_toCellValues(['Fecha', 'Documentos', 'Personas', 'Tamaño']));
    for (var day in dailyTrends) {
      trendsSheet.appendRow(_toCellValues([
        '${day.date.day}/${day.date.month}/${day.date.year}',
        day.documentCount,
        day.uniquePersons,
        ReportingService.formatBytes(day.totalSize),
      ]));
    }

    // Remove default sheet
    excel.delete('Sheet1');

    // Save file
    final bytes = excel.encode();
    if (bytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/reporte_digitalizacion_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Reporte de Digitalización',
      );
    }
  }
}
