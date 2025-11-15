import '../services/logger_adapter.dart';
import '../data/local/database/app_database.dart';
import '../data/repositories/document_repository.dart';

/// Workflow Engine
///
/// Automated workflow system for document processing
///
/// Features:
/// - Rule-based document classification
/// - Automatic tagging
/// - Notification triggers
/// - Document routing
/// - Quality checks
/// - Gap-based workflows
class WorkflowEngine {
  final AppDatabase _database;
  final DocumentRepository _documentRepository;
  final LoggerAdapter _logger = LoggerAdapter();

  // Workflow rules
  final List<WorkflowRule> _rules = [];
  final List<WorkflowAction> _executedActions = [];

  WorkflowEngine(this._database, this._documentRepository) {
    _initializeDefaultRules();
  }

  /// Initialize default workflow rules
  void _initializeDefaultRules() {
    // Rule 1: Auto-tag documents by type
    _rules.add(WorkflowRule(
      id: 'auto_tag_cedula',
      name: 'Auto-etiquetar Cédulas',
      description: 'Aplica etiqueta "cedula" automáticamente',
      trigger: WorkflowTrigger.onUpload,
      conditions: [
        WorkflowCondition(
          field: 'document_type',
          operator: ConditionOperator.contains,
          value: 'Cédula',
        ),
      ],
      actions: [
        WorkflowAction(
          type: WorkflowActionType.addTag,
          parameters: {'tag': 'cedula', 'tag_id': 1},
        ),
      ],
      enabled: true,
      priority: 10,
    ));

    // Rule 2: Notify on high-priority documents
    _rules.add(WorkflowRule(
      id: 'notify_high_priority',
      name: 'Notificar Documentos Prioritarios',
      description: 'Notifica cuando se sube documento de persona con brechas',
      trigger: WorkflowTrigger.onUpload,
      conditions: [
        WorkflowCondition(
          field: 'person_has_gaps',
          operator: ConditionOperator.equals,
          value: true,
        ),
      ],
      actions: [
        WorkflowAction(
          type: WorkflowActionType.sendNotification,
          parameters: {
            'title': 'Documento prioritario subido',
            'message': 'Se completó un documento faltante',
          },
        ),
      ],
      enabled: true,
      priority: 20,
    ));

    // Rule 3: Auto-classify by content
    _rules.add(WorkflowRule(
      id: 'classify_by_filename',
      name: 'Clasificar por Nombre de Archivo',
      description: 'Clasifica documentos basándose en nombre de archivo',
      trigger: WorkflowTrigger.onUpload,
      conditions: [
        WorkflowCondition(
          field: 'filename',
          operator: ConditionOperator.contains,
          value: 'vacuna',
        ),
      ],
      actions: [
        WorkflowAction(
          type: WorkflowActionType.setDocumentType,
          parameters: {'document_type': 'Carné de Vacunación'},
        ),
        WorkflowAction(
          type: WorkflowActionType.addTag,
          parameters: {'tag': 'salud', 'tag_id': 2},
        ),
      ],
      enabled: true,
      priority: 15,
    ));

    // Rule 4: Quality check reminder
    _rules.add(WorkflowRule(
      id: 'quality_check_reminder',
      name: 'Recordatorio de Calidad',
      description: 'Notifica si imagen de baja calidad',
      trigger: WorkflowTrigger.onQualityCheck,
      conditions: [
        WorkflowCondition(
          field: 'quality_score',
          operator: ConditionOperator.lessThan,
          value: 60,
        ),
      ],
      actions: [
        WorkflowAction(
          type: WorkflowActionType.sendNotification,
          parameters: {
            'title': 'Calidad de imagen baja',
            'message': 'Considera tomar la foto nuevamente para mejor OCR',
          },
        ),
      ],
      enabled: true,
      priority: 30,
    ));

    // Rule 5: Complete family notification
    _rules.add(WorkflowRule(
      id: 'family_complete',
      name: 'Familia Completa',
      description: 'Notifica cuando una familia completa todos sus documentos',
      trigger: WorkflowTrigger.onUpload,
      conditions: [
        WorkflowCondition(
          field: 'family_completion',
          operator: ConditionOperator.equals,
          value: 100,
        ),
      ],
      actions: [
        WorkflowAction(
          type: WorkflowActionType.sendNotification,
          parameters: {
            'title': '🎉 Familia completa',
            'message': 'Todos los documentos de la familia están completos',
          },
        ),
        WorkflowAction(
          type: WorkflowActionType.addTag,
          parameters: {'tag': 'completo', 'tag_id': 3},
        ),
      ],
      enabled: true,
      priority: 5,
    ));

    _logger.i('✅ Initialized ${_rules.length} workflow rules');
  }

  /// Execute workflows for a document upload
  Future<List<WorkflowAction>> executeWorkflows({
    required String uploadId,
    required WorkflowTrigger trigger,
    Map<String, dynamic>? context,
  }) async {
    try {
      _logger.i('⚙️ Executing workflows for upload: $uploadId');

      final executedActions = <WorkflowAction>[];

      // Get upload details
      final upload = await _database.getPendingUploadById(int.parse(uploadId));
      if (upload == null) {
        _logger.w('Upload not found: $uploadId');
        return executedActions;
      }

      // Build execution context
      final ctx = {
        'upload_id': uploadId,
        'person_id': upload.personId,
        'family_id': upload.familyId,
        'document_type': upload.documentNumber ?? '',
        'filename': upload.filePath.split('/').last,
        ...?context,
      };

      // Get applicable rules (matching trigger)
      final applicableRules = _rules
          .where((rule) => rule.enabled && rule.trigger == trigger)
          .toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));

      _logger.d('   Found ${applicableRules.length} applicable rules');

      // Execute each rule
      for (var rule in applicableRules) {
        if (await _evaluateConditions(rule.conditions, ctx)) {
          _logger.i('   ✓ Rule matched: ${rule.name}');

          // Execute actions
          for (var action in rule.actions) {
            try {
              await _executeAction(action, ctx);
              executedActions.add(action);
              _logger.d('     → Action executed: ${action.type}');
            } catch (e) {
              _logger.e('     ✗ Action failed: ${action.type} - $e');
            }
          }
        }
      }

      _logger.i('✅ Workflow execution complete: ${executedActions.length} actions executed');
      return executedActions;
    } catch (e, stackTrace) {
      _logger.e('❌ Workflow execution failed: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Evaluate workflow conditions
  Future<bool> _evaluateConditions(
    List<WorkflowCondition> conditions,
    Map<String, dynamic> context,
  ) async {
    for (var condition in conditions) {
      final fieldValue = context[condition.field];
      if (!_evaluateCondition(condition, fieldValue)) {
        return false;
      }
    }
    return true;
  }

  /// Evaluate single condition
  bool _evaluateCondition(WorkflowCondition condition, dynamic fieldValue) {
    switch (condition.operator) {
      case ConditionOperator.equals:
        return fieldValue == condition.value;
      case ConditionOperator.notEquals:
        return fieldValue != condition.value;
      case ConditionOperator.contains:
        return fieldValue.toString().toLowerCase().contains(
              condition.value.toString().toLowerCase(),
            );
      case ConditionOperator.notContains:
        return !fieldValue.toString().toLowerCase().contains(
              condition.value.toString().toLowerCase(),
            );
      case ConditionOperator.greaterThan:
        return (fieldValue as num) > (condition.value as num);
      case ConditionOperator.lessThan:
        return (fieldValue as num) < (condition.value as num);
      case ConditionOperator.greaterThanOrEqual:
        return (fieldValue as num) >= (condition.value as num);
      case ConditionOperator.lessThanOrEqual:
        return (fieldValue as num) <= (condition.value as num);
      default:
        return false;
    }
  }

  /// Execute workflow action
  Future<void> _executeAction(
    WorkflowAction action,
    Map<String, dynamic> context,
  ) async {
    switch (action.type) {
      case WorkflowActionType.addTag:
        await _addTag(action.parameters, context);
        break;
      case WorkflowActionType.removeTag:
        await _removeTag(action.parameters, context);
        break;
      case WorkflowActionType.setDocumentType:
        await _setDocumentType(action.parameters, context);
        break;
      case WorkflowActionType.sendNotification:
        await _sendNotification(action.parameters, context);
        break;
      case WorkflowActionType.assignToUser:
        await _assignToUser(action.parameters, context);
        break;
      case WorkflowActionType.updateMetadata:
        await _updateMetadata(action.parameters, context);
        break;
      case WorkflowActionType.triggerWebhook:
        await _triggerWebhook(action.parameters, context);
        break;
      default:
        _logger.w('Unknown action type: ${action.type}');
    }
  }

  /// Action: Add tag
  Future<void> _addTag(Map<String, dynamic> params, Map<String, dynamic> ctx) async {
    final tagName = params['tag'] as String;
    _logger.d('     Adding tag: $tagName');
    // In production, call DocumentRepository to add tag
  }

  /// Action: Remove tag
  Future<void> _removeTag(Map<String, dynamic> params, Map<String, dynamic> ctx) async {
    final tagName = params['tag'] as String;
    _logger.d('     Removing tag: $tagName');
  }

  /// Action: Set document type
  Future<void> _setDocumentType(Map<String, dynamic> params, Map<String, dynamic> ctx) async {
    final docType = params['document_type'] as String;
    _logger.d('     Setting document type: $docType');
    // Update upload record with document type
  }

  /// Action: Send notification
  Future<void> _sendNotification(Map<String, dynamic> params, Map<String, dynamic> ctx) async {
    final title = params['title'] as String;
    final message = params['message'] as String;
    _logger.i('     📬 Notification: $title - $message');
    // In production, use local notifications plugin
  }

  /// Action: Assign to user
  Future<void> _assignToUser(Map<String, dynamic> params, Map<String, dynamic> ctx) async {
    final userId = params['user_id'] as String;
    _logger.d('     Assigning to user: $userId');
  }

  /// Action: Update metadata
  Future<void> _updateMetadata(Map<String, dynamic> params, Map<String, dynamic> ctx) async {
    final metadata = params['metadata'] as Map<String, dynamic>;
    _logger.d('     Updating metadata: $metadata');
  }

  /// Action: Trigger webhook
  Future<void> _triggerWebhook(Map<String, dynamic> params, Map<String, dynamic> ctx) async {
    final url = params['url'] as String;
    _logger.d('     Triggering webhook: $url');
    // In production, make HTTP POST request
  }

  /// Add custom rule
  void addRule(WorkflowRule rule) {
    _rules.add(rule);
    _logger.i('✅ Added workflow rule: ${rule.name}');
  }

  /// Remove rule
  void removeRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
    _logger.i('✅ Removed workflow rule: $ruleId');
  }

  /// Enable/disable rule
  void setRuleEnabled(String ruleId, bool enabled) {
    final rule = _rules.firstWhere((r) => r.id == ruleId);
    rule.enabled = enabled;
    _logger.i('✅ Rule ${enabled ? "enabled" : "disabled"}: $ruleId');
  }

  /// Get all rules
  List<WorkflowRule> getRules() => List.unmodifiable(_rules);

  /// Get execution history
  List<WorkflowAction> getExecutionHistory() => List.unmodifiable(_executedActions);
}

/// Workflow Rule
class WorkflowRule {
  final String id;
  final String name;
  final String description;
  final WorkflowTrigger trigger;
  final List<WorkflowCondition> conditions;
  final List<WorkflowAction> actions;
  bool enabled;
  final int priority; // Lower = higher priority

  WorkflowRule({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    required this.conditions,
    required this.actions,
    this.enabled = true,
    this.priority = 100,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'trigger': trigger.toString(),
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        'enabled': enabled,
        'priority': priority,
      };
}

/// Workflow Trigger
enum WorkflowTrigger {
  onUpload,
  onQualityCheck,
  onSync,
  onComplete,
  onError,
  scheduled,
}

/// Workflow Condition
class WorkflowCondition {
  final String field;
  final ConditionOperator operator;
  final dynamic value;

  WorkflowCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'operator': operator.toString(),
        'value': value,
      };
}

/// Condition Operator
enum ConditionOperator {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
}

/// Workflow Action
class WorkflowAction {
  final WorkflowActionType type;
  final Map<String, dynamic> parameters;
  DateTime? executedAt;

  WorkflowAction({
    required this.type,
    required this.parameters,
    this.executedAt,
  });

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'parameters': parameters,
        'executed_at': executedAt?.toIso8601String(),
      };
}

/// Workflow Action Type
enum WorkflowActionType {
  addTag,
  removeTag,
  setDocumentType,
  sendNotification,
  assignToUser,
  updateMetadata,
  triggerWebhook,
}
