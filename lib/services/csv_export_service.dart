import 'dart:io';
import '../services/logger_adapter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/repositories/assignment_repository.dart';

/// CSV Export Service
/// Handles exporting data to CSV files and sharing them
class CSVExportService {
  final AssignmentRepository _repository;
  final LoggerAdapter _logger = LoggerAdapter();

  CSVExportService(this._repository);

  /// Export assignments to CSV and share
  Future<bool> exportAndShareAssignments({String? status}) async {
    try {
      _logger.i('📊 Exporting assignments to CSV');

      // Get CSV data from backend
      final csvContent = await _repository.exportAssignmentsCSV(status: status);

      // Save to temporary file
      final file = await _saveTempCSV(
        content: csvContent,
        filename: 'assignments_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Reporte de Asignaciones - Lumara',
        text: 'Reporte de asignaciones exportado desde Lumara',
      );

      _logger.i('✅ Assignments exported and shared successfully');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to export assignments', error: e);
      return false;
    }
  }

  /// Export productivity data to CSV and share
  Future<bool> exportAndShareProductivity({
    String? period,
    int? userId,
  }) async {
    try {
      _logger.i('📊 Exporting productivity to CSV');

      // Get CSV data from backend
      final csvContent = await _repository.exportProductivityCSV(
        period: period,
        userId: userId,
      );

      // Save to temporary file
      final file = await _saveTempCSV(
        content: csvContent,
        filename: 'productivity_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Reporte de Productividad - Lumara',
        text: 'Reporte de productividad exportado desde Lumara',
      );

      _logger.i('✅ Productivity exported and shared successfully');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to export productivity', error: e);
      return false;
    }
  }

  /// Export team summary to CSV and share
  Future<bool> exportAndShareTeamSummary() async {
    try {
      _logger.i('📊 Exporting team summary to CSV');

      // Get CSV data from backend
      final csvContent = await _repository.exportTeamSummaryCSV();

      // Save to temporary file
      final file = await _saveTempCSV(
        content: csvContent,
        filename: 'team_summary_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Resumen del Equipo - Lumara',
        text: 'Resumen del equipo exportado desde Lumara',
      );

      _logger.i('✅ Team summary exported and shared successfully');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to export team summary', error: e);
      return false;
    }
  }

  /// Save CSV content to temporary file
  Future<File> _saveTempCSV({
    required String content,
    required String filename,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Create file
      final file = File('${tempDir.path}/$filename');

      // Write content
      await file.writeAsString(content);

      _logger.d('📁 Saved CSV to: ${file.path}');

      return file;
    } catch (e) {
      _logger.e('❌ Failed to save CSV file', error: e);
      rethrow;
    }
  }

  /// Get downloads directory for saving files permanently
  Future<Directory?> getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // On Android, use external storage directory
        final dir = Directory('/storage/emulated/0/Download/Lumara');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      } else {
        // On other platforms, use app documents directory
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      _logger.e('❌ Failed to get downloads directory', error: e);
      return null;
    }
  }

  /// Save CSV to downloads directory (for permanent storage)
  Future<File?> savePermanentCSV({
    required String content,
    required String filename,
  }) async {
    try {
      final dir = await getDownloadsDirectory();
      if (dir == null) return null;

      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);

      _logger.i('✅ Saved CSV permanently: ${file.path}');

      return file;
    } catch (e) {
      _logger.e('❌ Failed to save permanent CSV', error: e);
      return null;
    }
  }

  /// Export assignments and save permanently
  Future<File?> exportAssignmentsToPermanent({String? status}) async {
    try {
      final csvContent = await _repository.exportAssignmentsCSV(status: status);

      final filename = 'lumara_assignments_${_formatDateForFilename(DateTime.now())}.csv';

      return await savePermanentCSV(
        content: csvContent,
        filename: filename,
      );
    } catch (e) {
      _logger.e('❌ Failed to export assignments permanently', error: e);
      return null;
    }
  }

  /// Export productivity and save permanently
  Future<File?> exportProductivityToPermanent({
    String? period,
    int? userId,
  }) async {
    try {
      final csvContent = await _repository.exportProductivityCSV(
        period: period,
        userId: userId,
      );

      final filename = 'lumara_productivity_${_formatDateForFilename(DateTime.now())}.csv';

      return await savePermanentCSV(
        content: csvContent,
        filename: filename,
      );
    } catch (e) {
      _logger.e('❌ Failed to export productivity permanently', error: e);
      return null;
    }
  }

  /// Export team summary and save permanently
  Future<File?> exportTeamSummaryToPermanent() async {
    try {
      final csvContent = await _repository.exportTeamSummaryCSV();

      final filename = 'lumara_team_summary_${_formatDateForFilename(DateTime.now())}.csv';

      return await savePermanentCSV(
        content: csvContent,
        filename: filename,
      );
    } catch (e) {
      _logger.e('❌ Failed to export team summary permanently', error: e);
      return null;
    }
  }

  /// Format date for filename (YYYYMMDD_HHMMSS)
  String _formatDateForFilename(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}'
        '_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}';
  }
}
