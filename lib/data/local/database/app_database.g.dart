// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PendingUploadsTable extends PendingUploads
    with TableInfo<$PendingUploadsTable, PendingUpload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingUploadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _personIdMeta =
      const VerificationMeta('personId');
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
      'person_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _personNameMeta =
      const VerificationMeta('personName');
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
      'person_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _familyIdMeta =
      const VerificationMeta('familyId');
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
      'family_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _documentTypeMeta =
      const VerificationMeta('documentType');
  @override
  late final GeneratedColumn<String> documentType = GeneratedColumn<String>(
      'document_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _documentNumberMeta =
      const VerificationMeta('documentNumber');
  @override
  late final GeneratedColumn<String> documentNumber = GeneratedColumn<String>(
      'document_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _digitizedByMeta =
      const VerificationMeta('digitizedBy');
  @override
  late final GeneratedColumn<String> digitizedBy = GeneratedColumn<String>(
      'digitized_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _documentTypeIdMeta =
      const VerificationMeta('documentTypeId');
  @override
  late final GeneratedColumn<int> documentTypeId = GeneratedColumn<int>(
      'document_type_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        personId,
        personName,
        familyId,
        filePath,
        fileName,
        documentType,
        documentNumber,
        digitizedBy,
        metadata,
        tags,
        documentTypeId,
        createdAt,
        retryCount,
        status,
        lastError,
        lastAttemptAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_uploads';
  @override
  VerificationContext validateIntegrity(Insertable<PendingUpload> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(_personIdMeta,
          personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta));
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('person_name')) {
      context.handle(
          _personNameMeta,
          personName.isAcceptableOrUnknown(
              data['person_name']!, _personNameMeta));
    } else if (isInserting) {
      context.missing(_personNameMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(_familyIdMeta,
          familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta));
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('document_type')) {
      context.handle(
          _documentTypeMeta,
          documentType.isAcceptableOrUnknown(
              data['document_type']!, _documentTypeMeta));
    } else if (isInserting) {
      context.missing(_documentTypeMeta);
    }
    if (data.containsKey('document_number')) {
      context.handle(
          _documentNumberMeta,
          documentNumber.isAcceptableOrUnknown(
              data['document_number']!, _documentNumberMeta));
    }
    if (data.containsKey('digitized_by')) {
      context.handle(
          _digitizedByMeta,
          digitizedBy.isAcceptableOrUnknown(
              data['digitized_by']!, _digitizedByMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('document_type_id')) {
      context.handle(
          _documentTypeIdMeta,
          documentTypeId.isAcceptableOrUnknown(
              data['document_type_id']!, _documentTypeIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingUpload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingUpload(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      personId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}person_id'])!,
      personName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}person_name'])!,
      familyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}family_id'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      documentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_type'])!,
      documentNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_number']),
      digitizedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}digitized_by']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      documentTypeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}document_type_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
    );
  }

  @override
  $PendingUploadsTable createAlias(String alias) {
    return $PendingUploadsTable(attachedDatabase, alias);
  }
}

class PendingUpload extends DataClass implements Insertable<PendingUpload> {
  final int id;
  final String personId;
  final String personName;
  final String familyId;
  final String filePath;
  final String fileName;
  final String documentType;
  final String? documentNumber;
  final String? digitizedBy;
  final String metadata;
  final String tags;
  final int? documentTypeId;
  final DateTime createdAt;
  final int retryCount;
  final String status;
  final String? lastError;
  final DateTime? lastAttemptAt;
  const PendingUpload(
      {required this.id,
      required this.personId,
      required this.personName,
      required this.familyId,
      required this.filePath,
      required this.fileName,
      required this.documentType,
      this.documentNumber,
      this.digitizedBy,
      required this.metadata,
      required this.tags,
      this.documentTypeId,
      required this.createdAt,
      required this.retryCount,
      required this.status,
      this.lastError,
      this.lastAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<String>(personId);
    map['person_name'] = Variable<String>(personName);
    map['family_id'] = Variable<String>(familyId);
    map['file_path'] = Variable<String>(filePath);
    map['file_name'] = Variable<String>(fileName);
    map['document_type'] = Variable<String>(documentType);
    if (!nullToAbsent || documentNumber != null) {
      map['document_number'] = Variable<String>(documentNumber);
    }
    if (!nullToAbsent || digitizedBy != null) {
      map['digitized_by'] = Variable<String>(digitizedBy);
    }
    map['metadata'] = Variable<String>(metadata);
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || documentTypeId != null) {
      map['document_type_id'] = Variable<int>(documentTypeId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  PendingUploadsCompanion toCompanion(bool nullToAbsent) {
    return PendingUploadsCompanion(
      id: Value(id),
      personId: Value(personId),
      personName: Value(personName),
      familyId: Value(familyId),
      filePath: Value(filePath),
      fileName: Value(fileName),
      documentType: Value(documentType),
      documentNumber: documentNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(documentNumber),
      digitizedBy: digitizedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(digitizedBy),
      metadata: Value(metadata),
      tags: Value(tags),
      documentTypeId: documentTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentTypeId),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory PendingUpload.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingUpload(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      personName: serializer.fromJson<String>(json['personName']),
      familyId: serializer.fromJson<String>(json['familyId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      documentType: serializer.fromJson<String>(json['documentType']),
      documentNumber: serializer.fromJson<String?>(json['documentNumber']),
      digitizedBy: serializer.fromJson<String?>(json['digitizedBy']),
      metadata: serializer.fromJson<String>(json['metadata']),
      tags: serializer.fromJson<String>(json['tags']),
      documentTypeId: serializer.fromJson<int?>(json['documentTypeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<String>(personId),
      'personName': serializer.toJson<String>(personName),
      'familyId': serializer.toJson<String>(familyId),
      'filePath': serializer.toJson<String>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'documentType': serializer.toJson<String>(documentType),
      'documentNumber': serializer.toJson<String?>(documentNumber),
      'digitizedBy': serializer.toJson<String?>(digitizedBy),
      'metadata': serializer.toJson<String>(metadata),
      'tags': serializer.toJson<String>(tags),
      'documentTypeId': serializer.toJson<int?>(documentTypeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  PendingUpload copyWith(
          {int? id,
          String? personId,
          String? personName,
          String? familyId,
          String? filePath,
          String? fileName,
          String? documentType,
          Value<String?> documentNumber = const Value.absent(),
          Value<String?> digitizedBy = const Value.absent(),
          String? metadata,
          String? tags,
          Value<int?> documentTypeId = const Value.absent(),
          DateTime? createdAt,
          int? retryCount,
          String? status,
          Value<String?> lastError = const Value.absent(),
          Value<DateTime?> lastAttemptAt = const Value.absent()}) =>
      PendingUpload(
        id: id ?? this.id,
        personId: personId ?? this.personId,
        personName: personName ?? this.personName,
        familyId: familyId ?? this.familyId,
        filePath: filePath ?? this.filePath,
        fileName: fileName ?? this.fileName,
        documentType: documentType ?? this.documentType,
        documentNumber:
            documentNumber.present ? documentNumber.value : this.documentNumber,
        digitizedBy: digitizedBy.present ? digitizedBy.value : this.digitizedBy,
        metadata: metadata ?? this.metadata,
        tags: tags ?? this.tags,
        documentTypeId:
            documentTypeId.present ? documentTypeId.value : this.documentTypeId,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        status: status ?? this.status,
        lastError: lastError.present ? lastError.value : this.lastError,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
      );
  PendingUpload copyWithCompanion(PendingUploadsCompanion data) {
    return PendingUpload(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      personName:
          data.personName.present ? data.personName.value : this.personName,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      documentNumber: data.documentNumber.present
          ? data.documentNumber.value
          : this.documentNumber,
      digitizedBy:
          data.digitizedBy.present ? data.digitizedBy.value : this.digitizedBy,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      tags: data.tags.present ? data.tags.value : this.tags,
      documentTypeId: data.documentTypeId.present
          ? data.documentTypeId.value
          : this.documentTypeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingUpload(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('familyId: $familyId, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('documentType: $documentType, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('digitizedBy: $digitizedBy, ')
          ..write('metadata: $metadata, ')
          ..write('tags: $tags, ')
          ..write('documentTypeId: $documentTypeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      personId,
      personName,
      familyId,
      filePath,
      fileName,
      documentType,
      documentNumber,
      digitizedBy,
      metadata,
      tags,
      documentTypeId,
      createdAt,
      retryCount,
      status,
      lastError,
      lastAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingUpload &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.personName == this.personName &&
          other.familyId == this.familyId &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.documentType == this.documentType &&
          other.documentNumber == this.documentNumber &&
          other.digitizedBy == this.digitizedBy &&
          other.metadata == this.metadata &&
          other.tags == this.tags &&
          other.documentTypeId == this.documentTypeId &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.lastError == this.lastError &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class PendingUploadsCompanion extends UpdateCompanion<PendingUpload> {
  final Value<int> id;
  final Value<String> personId;
  final Value<String> personName;
  final Value<String> familyId;
  final Value<String> filePath;
  final Value<String> fileName;
  final Value<String> documentType;
  final Value<String?> documentNumber;
  final Value<String?> digitizedBy;
  final Value<String> metadata;
  final Value<String> tags;
  final Value<int?> documentTypeId;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<DateTime?> lastAttemptAt;
  const PendingUploadsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.familyId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.documentType = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.digitizedBy = const Value.absent(),
    this.metadata = const Value.absent(),
    this.tags = const Value.absent(),
    this.documentTypeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
  });
  PendingUploadsCompanion.insert({
    this.id = const Value.absent(),
    required String personId,
    required String personName,
    required String familyId,
    required String filePath,
    required String fileName,
    required String documentType,
    this.documentNumber = const Value.absent(),
    this.digitizedBy = const Value.absent(),
    this.metadata = const Value.absent(),
    this.tags = const Value.absent(),
    this.documentTypeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
  })  : personId = Value(personId),
        personName = Value(personName),
        familyId = Value(familyId),
        filePath = Value(filePath),
        fileName = Value(fileName),
        documentType = Value(documentType);
  static Insertable<PendingUpload> custom({
    Expression<int>? id,
    Expression<String>? personId,
    Expression<String>? personName,
    Expression<String>? familyId,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<String>? documentType,
    Expression<String>? documentNumber,
    Expression<String>? digitizedBy,
    Expression<String>? metadata,
    Expression<String>? tags,
    Expression<int>? documentTypeId,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<DateTime>? lastAttemptAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (personName != null) 'person_name': personName,
      if (familyId != null) 'family_id': familyId,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (documentType != null) 'document_type': documentType,
      if (documentNumber != null) 'document_number': documentNumber,
      if (digitizedBy != null) 'digitized_by': digitizedBy,
      if (metadata != null) 'metadata': metadata,
      if (tags != null) 'tags': tags,
      if (documentTypeId != null) 'document_type_id': documentTypeId,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
    });
  }

  PendingUploadsCompanion copyWith(
      {Value<int>? id,
      Value<String>? personId,
      Value<String>? personName,
      Value<String>? familyId,
      Value<String>? filePath,
      Value<String>? fileName,
      Value<String>? documentType,
      Value<String?>? documentNumber,
      Value<String?>? digitizedBy,
      Value<String>? metadata,
      Value<String>? tags,
      Value<int?>? documentTypeId,
      Value<DateTime>? createdAt,
      Value<int>? retryCount,
      Value<String>? status,
      Value<String?>? lastError,
      Value<DateTime?>? lastAttemptAt}) {
    return PendingUploadsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      familyId: familyId ?? this.familyId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      digitizedBy: digitizedBy ?? this.digitizedBy,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      documentTypeId: documentTypeId ?? this.documentTypeId,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (documentType.present) {
      map['document_type'] = Variable<String>(documentType.value);
    }
    if (documentNumber.present) {
      map['document_number'] = Variable<String>(documentNumber.value);
    }
    if (digitizedBy.present) {
      map['digitized_by'] = Variable<String>(digitizedBy.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (documentTypeId.present) {
      map['document_type_id'] = Variable<int>(documentTypeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingUploadsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('familyId: $familyId, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('documentType: $documentType, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('digitizedBy: $digitizedBy, ')
          ..write('metadata: $metadata, ')
          ..write('tags: $tags, ')
          ..write('documentTypeId: $documentTypeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }
}

class $UploadHistoryTable extends UploadHistory
    with TableInfo<$UploadHistoryTable, UploadHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _personIdMeta =
      const VerificationMeta('personId');
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
      'person_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _personNameMeta =
      const VerificationMeta('personName');
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
      'person_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _documentTypeMeta =
      const VerificationMeta('documentType');
  @override
  late final GeneratedColumn<String> documentType = GeneratedColumn<String>(
      'document_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tejidoDocumentIdMeta =
      const VerificationMeta('tejidoDocumentId');
  @override
  late final GeneratedColumn<int> tejidoDocumentId = GeneratedColumn<int>(
      'tejido_document_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _uploadedAtMeta =
      const VerificationMeta('uploadedAt');
  @override
  late final GeneratedColumn<DateTime> uploadedAt = GeneratedColumn<DateTime>(
      'uploaded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _uploadDurationMsMeta =
      const VerificationMeta('uploadDurationMs');
  @override
  late final GeneratedColumn<int> uploadDurationMs = GeneratedColumn<int>(
      'upload_duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _wasOfflineMeta =
      const VerificationMeta('wasOffline');
  @override
  late final GeneratedColumn<bool> wasOffline = GeneratedColumn<bool>(
      'was_offline', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("was_offline" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        personId,
        personName,
        documentType,
        tejidoDocumentId,
        uploadedAt,
        status,
        fileSize,
        uploadDurationMs,
        wasOffline
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_history';
  @override
  VerificationContext validateIntegrity(Insertable<UploadHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(_personIdMeta,
          personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta));
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('person_name')) {
      context.handle(
          _personNameMeta,
          personName.isAcceptableOrUnknown(
              data['person_name']!, _personNameMeta));
    } else if (isInserting) {
      context.missing(_personNameMeta);
    }
    if (data.containsKey('document_type')) {
      context.handle(
          _documentTypeMeta,
          documentType.isAcceptableOrUnknown(
              data['document_type']!, _documentTypeMeta));
    } else if (isInserting) {
      context.missing(_documentTypeMeta);
    }
    if (data.containsKey('tejido_document_id')) {
      context.handle(
          _tejidoDocumentIdMeta,
          tejidoDocumentId.isAcceptableOrUnknown(
              data['tejido_document_id']!, _tejidoDocumentIdMeta));
    }
    if (data.containsKey('uploaded_at')) {
      context.handle(
          _uploadedAtMeta,
          uploadedAt.isAcceptableOrUnknown(
              data['uploaded_at']!, _uploadedAtMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    }
    if (data.containsKey('upload_duration_ms')) {
      context.handle(
          _uploadDurationMsMeta,
          uploadDurationMs.isAcceptableOrUnknown(
              data['upload_duration_ms']!, _uploadDurationMsMeta));
    }
    if (data.containsKey('was_offline')) {
      context.handle(
          _wasOfflineMeta,
          wasOffline.isAcceptableOrUnknown(
              data['was_offline']!, _wasOfflineMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      personId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}person_id'])!,
      personName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}person_name'])!,
      documentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_type'])!,
      tejidoDocumentId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}tejido_document_id']),
      uploadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}uploaded_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      uploadDurationMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}upload_duration_ms'])!,
      wasOffline: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_offline'])!,
    );
  }

  @override
  $UploadHistoryTable createAlias(String alias) {
    return $UploadHistoryTable(attachedDatabase, alias);
  }
}

class UploadHistoryData extends DataClass
    implements Insertable<UploadHistoryData> {
  final int id;
  final String personId;
  final String personName;
  final String documentType;
  final int? tejidoDocumentId;
  final DateTime uploadedAt;
  final String status;
  final int fileSize;
  final int uploadDurationMs;
  final bool wasOffline;
  const UploadHistoryData(
      {required this.id,
      required this.personId,
      required this.personName,
      required this.documentType,
      this.tejidoDocumentId,
      required this.uploadedAt,
      required this.status,
      required this.fileSize,
      required this.uploadDurationMs,
      required this.wasOffline});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<String>(personId);
    map['person_name'] = Variable<String>(personName);
    map['document_type'] = Variable<String>(documentType);
    if (!nullToAbsent || tejidoDocumentId != null) {
      map['tejido_document_id'] = Variable<int>(tejidoDocumentId);
    }
    map['uploaded_at'] = Variable<DateTime>(uploadedAt);
    map['status'] = Variable<String>(status);
    map['file_size'] = Variable<int>(fileSize);
    map['upload_duration_ms'] = Variable<int>(uploadDurationMs);
    map['was_offline'] = Variable<bool>(wasOffline);
    return map;
  }

  UploadHistoryCompanion toCompanion(bool nullToAbsent) {
    return UploadHistoryCompanion(
      id: Value(id),
      personId: Value(personId),
      personName: Value(personName),
      documentType: Value(documentType),
      tejidoDocumentId: tejidoDocumentId == null && nullToAbsent
          ? const Value.absent()
          : Value(tejidoDocumentId),
      uploadedAt: Value(uploadedAt),
      status: Value(status),
      fileSize: Value(fileSize),
      uploadDurationMs: Value(uploadDurationMs),
      wasOffline: Value(wasOffline),
    );
  }

  factory UploadHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadHistoryData(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      personName: serializer.fromJson<String>(json['personName']),
      documentType: serializer.fromJson<String>(json['documentType']),
      tejidoDocumentId:
          serializer.fromJson<int?>(json['tejidoDocumentId']),
      uploadedAt: serializer.fromJson<DateTime>(json['uploadedAt']),
      status: serializer.fromJson<String>(json['status']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      uploadDurationMs: serializer.fromJson<int>(json['uploadDurationMs']),
      wasOffline: serializer.fromJson<bool>(json['wasOffline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<String>(personId),
      'personName': serializer.toJson<String>(personName),
      'documentType': serializer.toJson<String>(documentType),
      'tejidoDocumentId': serializer.toJson<int?>(tejidoDocumentId),
      'uploadedAt': serializer.toJson<DateTime>(uploadedAt),
      'status': serializer.toJson<String>(status),
      'fileSize': serializer.toJson<int>(fileSize),
      'uploadDurationMs': serializer.toJson<int>(uploadDurationMs),
      'wasOffline': serializer.toJson<bool>(wasOffline),
    };
  }

  UploadHistoryData copyWith(
          {int? id,
          String? personId,
          String? personName,
          String? documentType,
          Value<int?> tejidoDocumentId = const Value.absent(),
          DateTime? uploadedAt,
          String? status,
          int? fileSize,
          int? uploadDurationMs,
          bool? wasOffline}) =>
      UploadHistoryData(
        id: id ?? this.id,
        personId: personId ?? this.personId,
        personName: personName ?? this.personName,
        documentType: documentType ?? this.documentType,
        tejidoDocumentId: tejidoDocumentId.present
            ? tejidoDocumentId.value
            : this.tejidoDocumentId,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        status: status ?? this.status,
        fileSize: fileSize ?? this.fileSize,
        uploadDurationMs: uploadDurationMs ?? this.uploadDurationMs,
        wasOffline: wasOffline ?? this.wasOffline,
      );
  UploadHistoryData copyWithCompanion(UploadHistoryCompanion data) {
    return UploadHistoryData(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      personName:
          data.personName.present ? data.personName.value : this.personName,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      tejidoDocumentId: data.tejidoDocumentId.present
          ? data.tejidoDocumentId.value
          : this.tejidoDocumentId,
      uploadedAt:
          data.uploadedAt.present ? data.uploadedAt.value : this.uploadedAt,
      status: data.status.present ? data.status.value : this.status,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      uploadDurationMs: data.uploadDurationMs.present
          ? data.uploadDurationMs.value
          : this.uploadDurationMs,
      wasOffline:
          data.wasOffline.present ? data.wasOffline.value : this.wasOffline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadHistoryData(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('documentType: $documentType, ')
          ..write('tejidoDocumentId: $tejidoDocumentId, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('status: $status, ')
          ..write('fileSize: $fileSize, ')
          ..write('uploadDurationMs: $uploadDurationMs, ')
          ..write('wasOffline: $wasOffline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      personId,
      personName,
      documentType,
      tejidoDocumentId,
      uploadedAt,
      status,
      fileSize,
      uploadDurationMs,
      wasOffline);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadHistoryData &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.personName == this.personName &&
          other.documentType == this.documentType &&
          other.tejidoDocumentId == this.tejidoDocumentId &&
          other.uploadedAt == this.uploadedAt &&
          other.status == this.status &&
          other.fileSize == this.fileSize &&
          other.uploadDurationMs == this.uploadDurationMs &&
          other.wasOffline == this.wasOffline);
}

class UploadHistoryCompanion extends UpdateCompanion<UploadHistoryData> {
  final Value<int> id;
  final Value<String> personId;
  final Value<String> personName;
  final Value<String> documentType;
  final Value<int?> tejidoDocumentId;
  final Value<DateTime> uploadedAt;
  final Value<String> status;
  final Value<int> fileSize;
  final Value<int> uploadDurationMs;
  final Value<bool> wasOffline;
  const UploadHistoryCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.documentType = const Value.absent(),
    this.tejidoDocumentId = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.uploadDurationMs = const Value.absent(),
    this.wasOffline = const Value.absent(),
  });
  UploadHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String personId,
    required String personName,
    required String documentType,
    this.tejidoDocumentId = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    required String status,
    this.fileSize = const Value.absent(),
    this.uploadDurationMs = const Value.absent(),
    this.wasOffline = const Value.absent(),
  })  : personId = Value(personId),
        personName = Value(personName),
        documentType = Value(documentType),
        status = Value(status);
  static Insertable<UploadHistoryData> custom({
    Expression<int>? id,
    Expression<String>? personId,
    Expression<String>? personName,
    Expression<String>? documentType,
    Expression<int>? tejidoDocumentId,
    Expression<DateTime>? uploadedAt,
    Expression<String>? status,
    Expression<int>? fileSize,
    Expression<int>? uploadDurationMs,
    Expression<bool>? wasOffline,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (personName != null) 'person_name': personName,
      if (documentType != null) 'document_type': documentType,
      if (tejidoDocumentId != null)
        'tejido_document_id': tejidoDocumentId,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (status != null) 'status': status,
      if (fileSize != null) 'file_size': fileSize,
      if (uploadDurationMs != null) 'upload_duration_ms': uploadDurationMs,
      if (wasOffline != null) 'was_offline': wasOffline,
    });
  }

  UploadHistoryCompanion copyWith(
      {Value<int>? id,
      Value<String>? personId,
      Value<String>? personName,
      Value<String>? documentType,
      Value<int?>? tejidoDocumentId,
      Value<DateTime>? uploadedAt,
      Value<String>? status,
      Value<int>? fileSize,
      Value<int>? uploadDurationMs,
      Value<bool>? wasOffline}) {
    return UploadHistoryCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      documentType: documentType ?? this.documentType,
      tejidoDocumentId: tejidoDocumentId ?? this.tejidoDocumentId,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
      fileSize: fileSize ?? this.fileSize,
      uploadDurationMs: uploadDurationMs ?? this.uploadDurationMs,
      wasOffline: wasOffline ?? this.wasOffline,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (documentType.present) {
      map['document_type'] = Variable<String>(documentType.value);
    }
    if (tejidoDocumentId.present) {
      map['tejido_document_id'] = Variable<int>(tejidoDocumentId.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (uploadDurationMs.present) {
      map['upload_duration_ms'] = Variable<int>(uploadDurationMs.value);
    }
    if (wasOffline.present) {
      map['was_offline'] = Variable<bool>(wasOffline.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadHistoryCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('documentType: $documentType, ')
          ..write('tejidoDocumentId: $tejidoDocumentId, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('status: $status, ')
          ..write('fileSize: $fileSize, ')
          ..write('uploadDurationMs: $uploadDurationMs, ')
          ..write('wasOffline: $wasOffline')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _censusIdMeta =
      const VerificationMeta('censusId');
  @override
  late final GeneratedColumn<String> censusId = GeneratedColumn<String>(
      'census_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _birthDateMeta =
      const VerificationMeta('birthDate');
  @override
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
      'birth_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lifeStageMeta =
      const VerificationMeta('lifeStage');
  @override
  late final GeneratedColumn<String> lifeStage = GeneratedColumn<String>(
      'life_stage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _familyRoleMeta =
      const VerificationMeta('familyRole');
  @override
  late final GeneratedColumn<String> familyRole = GeneratedColumn<String>(
      'family_role', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _communityMeta =
      const VerificationMeta('community');
  @override
  late final GeneratedColumn<String> community = GeneratedColumn<String>(
      'community', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        censusId,
        name,
        birthDate,
        lifeStage,
        familyRole,
        community,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(Insertable<Person> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('census_id')) {
      context.handle(_censusIdMeta,
          censusId.isAcceptableOrUnknown(data['census_id']!, _censusIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    }
    if (data.containsKey('life_stage')) {
      context.handle(_lifeStageMeta,
          lifeStage.isAcceptableOrUnknown(data['life_stage']!, _lifeStageMeta));
    }
    if (data.containsKey('family_role')) {
      context.handle(
          _familyRoleMeta,
          familyRole.isAcceptableOrUnknown(
              data['family_role']!, _familyRoleMeta));
    }
    if (data.containsKey('community')) {
      context.handle(_communityMeta,
          community.isAcceptableOrUnknown(data['community']!, _communityMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      censusId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}census_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birth_date']),
      lifeStage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}life_stage']),
      familyRole: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}family_role']),
      community: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}community']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final String id;
  final String? censusId;
  final String name;
  final String? birthDate;
  final String? lifeStage;
  final String? familyRole;
  final String? community;
  final DateTime syncedAt;
  const Person(
      {required this.id,
      this.censusId,
      required this.name,
      this.birthDate,
      this.lifeStage,
      this.familyRole,
      this.community,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || censusId != null) {
      map['census_id'] = Variable<String>(censusId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<String>(birthDate);
    }
    if (!nullToAbsent || lifeStage != null) {
      map['life_stage'] = Variable<String>(lifeStage);
    }
    if (!nullToAbsent || familyRole != null) {
      map['family_role'] = Variable<String>(familyRole);
    }
    if (!nullToAbsent || community != null) {
      map['community'] = Variable<String>(community);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      id: Value(id),
      censusId: censusId == null && nullToAbsent
          ? const Value.absent()
          : Value(censusId),
      name: Value(name),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      lifeStage: lifeStage == null && nullToAbsent
          ? const Value.absent()
          : Value(lifeStage),
      familyRole: familyRole == null && nullToAbsent
          ? const Value.absent()
          : Value(familyRole),
      community: community == null && nullToAbsent
          ? const Value.absent()
          : Value(community),
      syncedAt: Value(syncedAt),
    );
  }

  factory Person.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<String>(json['id']),
      censusId: serializer.fromJson<String?>(json['censusId']),
      name: serializer.fromJson<String>(json['name']),
      birthDate: serializer.fromJson<String?>(json['birthDate']),
      lifeStage: serializer.fromJson<String?>(json['lifeStage']),
      familyRole: serializer.fromJson<String?>(json['familyRole']),
      community: serializer.fromJson<String?>(json['community']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'censusId': serializer.toJson<String?>(censusId),
      'name': serializer.toJson<String>(name),
      'birthDate': serializer.toJson<String?>(birthDate),
      'lifeStage': serializer.toJson<String?>(lifeStage),
      'familyRole': serializer.toJson<String?>(familyRole),
      'community': serializer.toJson<String?>(community),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  Person copyWith(
          {String? id,
          Value<String?> censusId = const Value.absent(),
          String? name,
          Value<String?> birthDate = const Value.absent(),
          Value<String?> lifeStage = const Value.absent(),
          Value<String?> familyRole = const Value.absent(),
          Value<String?> community = const Value.absent(),
          DateTime? syncedAt}) =>
      Person(
        id: id ?? this.id,
        censusId: censusId.present ? censusId.value : this.censusId,
        name: name ?? this.name,
        birthDate: birthDate.present ? birthDate.value : this.birthDate,
        lifeStage: lifeStage.present ? lifeStage.value : this.lifeStage,
        familyRole: familyRole.present ? familyRole.value : this.familyRole,
        community: community.present ? community.value : this.community,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      censusId: data.censusId.present ? data.censusId.value : this.censusId,
      name: data.name.present ? data.name.value : this.name,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      lifeStage: data.lifeStage.present ? data.lifeStage.value : this.lifeStage,
      familyRole:
          data.familyRole.present ? data.familyRole.value : this.familyRole,
      community: data.community.present ? data.community.value : this.community,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('censusId: $censusId, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('lifeStage: $lifeStage, ')
          ..write('familyRole: $familyRole, ')
          ..write('community: $community, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, censusId, name, birthDate, lifeStage,
      familyRole, community, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.censusId == this.censusId &&
          other.name == this.name &&
          other.birthDate == this.birthDate &&
          other.lifeStage == this.lifeStage &&
          other.familyRole == this.familyRole &&
          other.community == this.community &&
          other.syncedAt == this.syncedAt);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<String> id;
  final Value<String?> censusId;
  final Value<String> name;
  final Value<String?> birthDate;
  final Value<String?> lifeStage;
  final Value<String?> familyRole;
  final Value<String?> community;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const PersonsCompanion({
    this.id = const Value.absent(),
    this.censusId = const Value.absent(),
    this.name = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.lifeStage = const Value.absent(),
    this.familyRole = const Value.absent(),
    this.community = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonsCompanion.insert({
    required String id,
    this.censusId = const Value.absent(),
    required String name,
    this.birthDate = const Value.absent(),
    this.lifeStage = const Value.absent(),
    this.familyRole = const Value.absent(),
    this.community = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        syncedAt = Value(syncedAt);
  static Insertable<Person> custom({
    Expression<String>? id,
    Expression<String>? censusId,
    Expression<String>? name,
    Expression<String>? birthDate,
    Expression<String>? lifeStage,
    Expression<String>? familyRole,
    Expression<String>? community,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (censusId != null) 'census_id': censusId,
      if (name != null) 'name': name,
      if (birthDate != null) 'birth_date': birthDate,
      if (lifeStage != null) 'life_stage': lifeStage,
      if (familyRole != null) 'family_role': familyRole,
      if (community != null) 'community': community,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? censusId,
      Value<String>? name,
      Value<String?>? birthDate,
      Value<String?>? lifeStage,
      Value<String?>? familyRole,
      Value<String?>? community,
      Value<DateTime>? syncedAt,
      Value<int>? rowid}) {
    return PersonsCompanion(
      id: id ?? this.id,
      censusId: censusId ?? this.censusId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      lifeStage: lifeStage ?? this.lifeStage,
      familyRole: familyRole ?? this.familyRole,
      community: community ?? this.community,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (censusId.present) {
      map['census_id'] = Variable<String>(censusId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (lifeStage.present) {
      map['life_stage'] = Variable<String>(lifeStage.value);
    }
    if (familyRole.present) {
      map['family_role'] = Variable<String>(familyRole.value);
    }
    if (community.present) {
      map['community'] = Variable<String>(community.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('id: $id, ')
          ..write('censusId: $censusId, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('lifeStage: $lifeStage, ')
          ..write('familyRole: $familyRole, ')
          ..write('community: $community, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentTypesTable extends DocumentTypes
    with TableInfo<$DocumentTypesTable, DocumentType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_types';
  @override
  VerificationContext validateIntegrity(Insertable<DocumentType> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentType(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $DocumentTypesTable createAlias(String alias) {
    return $DocumentTypesTable(attachedDatabase, alias);
  }
}

class DocumentType extends DataClass implements Insertable<DocumentType> {
  final int id;
  final String name;
  final DateTime cachedAt;
  const DocumentType(
      {required this.id, required this.name, required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  DocumentTypesCompanion toCompanion(bool nullToAbsent) {
    return DocumentTypesCompanion(
      id: Value(id),
      name: Value(name),
      cachedAt: Value(cachedAt),
    );
  }

  factory DocumentType.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentType(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  DocumentType copyWith({int? id, String? name, DateTime? cachedAt}) =>
      DocumentType(
        id: id ?? this.id,
        name: name ?? this.name,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  DocumentType copyWithCompanion(DocumentTypesCompanion data) {
    return DocumentType(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentType(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentType &&
          other.id == this.id &&
          other.name == this.name &&
          other.cachedAt == this.cachedAt);
}

class DocumentTypesCompanion extends UpdateCompanion<DocumentType> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> cachedAt;
  const DocumentTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  DocumentTypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime cachedAt,
  })  : name = Value(name),
        cachedAt = Value(cachedAt);
  static Insertable<DocumentType> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  DocumentTypesCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<DateTime>? cachedAt}) {
    return DocumentTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, color, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  final String? color;
  final DateTime cachedAt;
  const Tag(
      {required this.id,
      required this.name,
      this.color,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      cachedAt: Value(cachedAt),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Tag copyWith(
          {int? id,
          String? name,
          Value<String?> color = const Value.absent(),
          DateTime? cachedAt}) =>
      Tag(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.cachedAt == this.cachedAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<DateTime> cachedAt;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    required DateTime cachedAt,
  })  : name = Value(name),
        cachedAt = Value(cachedAt);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  TagsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? color,
      Value<DateTime>? cachedAt}) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CustomFieldsTable extends CustomFields
    with TableInfo<$CustomFieldsTable, CustomField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataTypeMeta =
      const VerificationMeta('dataType');
  @override
  late final GeneratedColumn<String> dataType = GeneratedColumn<String>(
      'data_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, dataType, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_fields';
  @override
  VerificationContext validateIntegrity(Insertable<CustomField> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('data_type')) {
      context.handle(_dataTypeMeta,
          dataType.isAcceptableOrUnknown(data['data_type']!, _dataTypeMeta));
    } else if (isInserting) {
      context.missing(_dataTypeMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomField(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dataType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_type'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CustomFieldsTable createAlias(String alias) {
    return $CustomFieldsTable(attachedDatabase, alias);
  }
}

class CustomField extends DataClass implements Insertable<CustomField> {
  final int id;
  final String name;
  final String dataType;
  final DateTime cachedAt;
  const CustomField(
      {required this.id,
      required this.name,
      required this.dataType,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['data_type'] = Variable<String>(dataType);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CustomFieldsCompanion toCompanion(bool nullToAbsent) {
    return CustomFieldsCompanion(
      id: Value(id),
      name: Value(name),
      dataType: Value(dataType),
      cachedAt: Value(cachedAt),
    );
  }

  factory CustomField.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomField(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dataType: serializer.fromJson<String>(json['dataType']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'dataType': serializer.toJson<String>(dataType),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CustomField copyWith(
          {int? id, String? name, String? dataType, DateTime? cachedAt}) =>
      CustomField(
        id: id ?? this.id,
        name: name ?? this.name,
        dataType: dataType ?? this.dataType,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CustomField copyWithCompanion(CustomFieldsCompanion data) {
    return CustomField(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dataType: data.dataType.present ? data.dataType.value : this.dataType,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomField(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dataType: $dataType, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, dataType, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomField &&
          other.id == this.id &&
          other.name == this.name &&
          other.dataType == this.dataType &&
          other.cachedAt == this.cachedAt);
}

class CustomFieldsCompanion extends UpdateCompanion<CustomField> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> dataType;
  final Value<DateTime> cachedAt;
  const CustomFieldsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dataType = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CustomFieldsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String dataType,
    required DateTime cachedAt,
  })  : name = Value(name),
        dataType = Value(dataType),
        cachedAt = Value(cachedAt);
  static Insertable<CustomField> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? dataType,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dataType != null) 'data_type': dataType,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CustomFieldsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? dataType,
      Value<DateTime>? cachedAt}) {
    return CustomFieldsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dataType: dataType ?? this.dataType,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dataType.present) {
      map['data_type'] = Variable<String>(dataType.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFieldsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dataType: $dataType, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PendingUploadsTable pendingUploads = $PendingUploadsTable(this);
  late final $UploadHistoryTable uploadHistory = $UploadHistoryTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $DocumentTypesTable documentTypes = $DocumentTypesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $CustomFieldsTable customFields = $CustomFieldsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        pendingUploads,
        uploadHistory,
        persons,
        documentTypes,
        tags,
        customFields
      ];
}

typedef $$PendingUploadsTableCreateCompanionBuilder = PendingUploadsCompanion
    Function({
  Value<int> id,
  required String personId,
  required String personName,
  required String familyId,
  required String filePath,
  required String fileName,
  required String documentType,
  Value<String?> documentNumber,
  Value<String?> digitizedBy,
  Value<String> metadata,
  Value<String> tags,
  Value<int?> documentTypeId,
  Value<DateTime> createdAt,
  Value<int> retryCount,
  Value<String> status,
  Value<String?> lastError,
  Value<DateTime?> lastAttemptAt,
});
typedef $$PendingUploadsTableUpdateCompanionBuilder = PendingUploadsCompanion
    Function({
  Value<int> id,
  Value<String> personId,
  Value<String> personName,
  Value<String> familyId,
  Value<String> filePath,
  Value<String> fileName,
  Value<String> documentType,
  Value<String?> documentNumber,
  Value<String?> digitizedBy,
  Value<String> metadata,
  Value<String> tags,
  Value<int?> documentTypeId,
  Value<DateTime> createdAt,
  Value<int> retryCount,
  Value<String> status,
  Value<String?> lastError,
  Value<DateTime?> lastAttemptAt,
});

class $$PendingUploadsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personId => $composableBuilder(
      column: $table.personId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get familyId => $composableBuilder(
      column: $table.familyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentType => $composableBuilder(
      column: $table.documentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentNumber => $composableBuilder(
      column: $table.documentNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get digitizedBy => $composableBuilder(
      column: $table.digitizedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get documentTypeId => $composableBuilder(
      column: $table.documentTypeId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));
}

class $$PendingUploadsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personId => $composableBuilder(
      column: $table.personId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get familyId => $composableBuilder(
      column: $table.familyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentType => $composableBuilder(
      column: $table.documentType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentNumber => $composableBuilder(
      column: $table.documentNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get digitizedBy => $composableBuilder(
      column: $table.digitizedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get documentTypeId => $composableBuilder(
      column: $table.documentTypeId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));
}

class $$PendingUploadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => column);

  GeneratedColumn<String> get familyId =>
      $composableBuilder(column: $table.familyId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get documentType => $composableBuilder(
      column: $table.documentType, builder: (column) => column);

  GeneratedColumn<String> get documentNumber => $composableBuilder(
      column: $table.documentNumber, builder: (column) => column);

  GeneratedColumn<String> get digitizedBy => $composableBuilder(
      column: $table.digitizedBy, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get documentTypeId => $composableBuilder(
      column: $table.documentTypeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);
}

class $$PendingUploadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingUploadsTable,
    PendingUpload,
    $$PendingUploadsTableFilterComposer,
    $$PendingUploadsTableOrderingComposer,
    $$PendingUploadsTableAnnotationComposer,
    $$PendingUploadsTableCreateCompanionBuilder,
    $$PendingUploadsTableUpdateCompanionBuilder,
    (
      PendingUpload,
      BaseReferences<_$AppDatabase, $PendingUploadsTable, PendingUpload>
    ),
    PendingUpload,
    PrefetchHooks Function()> {
  $$PendingUploadsTableTableManager(
      _$AppDatabase db, $PendingUploadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingUploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingUploadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingUploadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> personId = const Value.absent(),
            Value<String> personName = const Value.absent(),
            Value<String> familyId = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> documentType = const Value.absent(),
            Value<String?> documentNumber = const Value.absent(),
            Value<String?> digitizedBy = const Value.absent(),
            Value<String> metadata = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<int?> documentTypeId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
          }) =>
              PendingUploadsCompanion(
            id: id,
            personId: personId,
            personName: personName,
            familyId: familyId,
            filePath: filePath,
            fileName: fileName,
            documentType: documentType,
            documentNumber: documentNumber,
            digitizedBy: digitizedBy,
            metadata: metadata,
            tags: tags,
            documentTypeId: documentTypeId,
            createdAt: createdAt,
            retryCount: retryCount,
            status: status,
            lastError: lastError,
            lastAttemptAt: lastAttemptAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String personId,
            required String personName,
            required String familyId,
            required String filePath,
            required String fileName,
            required String documentType,
            Value<String?> documentNumber = const Value.absent(),
            Value<String?> digitizedBy = const Value.absent(),
            Value<String> metadata = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<int?> documentTypeId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
          }) =>
              PendingUploadsCompanion.insert(
            id: id,
            personId: personId,
            personName: personName,
            familyId: familyId,
            filePath: filePath,
            fileName: fileName,
            documentType: documentType,
            documentNumber: documentNumber,
            digitizedBy: digitizedBy,
            metadata: metadata,
            tags: tags,
            documentTypeId: documentTypeId,
            createdAt: createdAt,
            retryCount: retryCount,
            status: status,
            lastError: lastError,
            lastAttemptAt: lastAttemptAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingUploadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingUploadsTable,
    PendingUpload,
    $$PendingUploadsTableFilterComposer,
    $$PendingUploadsTableOrderingComposer,
    $$PendingUploadsTableAnnotationComposer,
    $$PendingUploadsTableCreateCompanionBuilder,
    $$PendingUploadsTableUpdateCompanionBuilder,
    (
      PendingUpload,
      BaseReferences<_$AppDatabase, $PendingUploadsTable, PendingUpload>
    ),
    PendingUpload,
    PrefetchHooks Function()>;
typedef $$UploadHistoryTableCreateCompanionBuilder = UploadHistoryCompanion
    Function({
  Value<int> id,
  required String personId,
  required String personName,
  required String documentType,
  Value<int?> tejidoDocumentId,
  Value<DateTime> uploadedAt,
  required String status,
  Value<int> fileSize,
  Value<int> uploadDurationMs,
  Value<bool> wasOffline,
});
typedef $$UploadHistoryTableUpdateCompanionBuilder = UploadHistoryCompanion
    Function({
  Value<int> id,
  Value<String> personId,
  Value<String> personName,
  Value<String> documentType,
  Value<int?> tejidoDocumentId,
  Value<DateTime> uploadedAt,
  Value<String> status,
  Value<int> fileSize,
  Value<int> uploadDurationMs,
  Value<bool> wasOffline,
});

class $$UploadHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $UploadHistoryTable> {
  $$UploadHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personId => $composableBuilder(
      column: $table.personId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentType => $composableBuilder(
      column: $table.documentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tejidoDocumentId => $composableBuilder(
      column: $table.tejidoDocumentId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uploadDurationMs => $composableBuilder(
      column: $table.uploadDurationMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasOffline => $composableBuilder(
      column: $table.wasOffline, builder: (column) => ColumnFilters(column));
}

class $$UploadHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $UploadHistoryTable> {
  $$UploadHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personId => $composableBuilder(
      column: $table.personId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentType => $composableBuilder(
      column: $table.documentType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tejidoDocumentId => $composableBuilder(
      column: $table.tejidoDocumentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uploadDurationMs => $composableBuilder(
      column: $table.uploadDurationMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasOffline => $composableBuilder(
      column: $table.wasOffline, builder: (column) => ColumnOrderings(column));
}

class $$UploadHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $UploadHistoryTable> {
  $$UploadHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => column);

  GeneratedColumn<String> get documentType => $composableBuilder(
      column: $table.documentType, builder: (column) => column);

  GeneratedColumn<int> get tejidoDocumentId => $composableBuilder(
      column: $table.tejidoDocumentId, builder: (column) => column);

  GeneratedColumn<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get uploadDurationMs => $composableBuilder(
      column: $table.uploadDurationMs, builder: (column) => column);

  GeneratedColumn<bool> get wasOffline => $composableBuilder(
      column: $table.wasOffline, builder: (column) => column);
}

class $$UploadHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UploadHistoryTable,
    UploadHistoryData,
    $$UploadHistoryTableFilterComposer,
    $$UploadHistoryTableOrderingComposer,
    $$UploadHistoryTableAnnotationComposer,
    $$UploadHistoryTableCreateCompanionBuilder,
    $$UploadHistoryTableUpdateCompanionBuilder,
    (
      UploadHistoryData,
      BaseReferences<_$AppDatabase, $UploadHistoryTable, UploadHistoryData>
    ),
    UploadHistoryData,
    PrefetchHooks Function()> {
  $$UploadHistoryTableTableManager(_$AppDatabase db, $UploadHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> personId = const Value.absent(),
            Value<String> personName = const Value.absent(),
            Value<String> documentType = const Value.absent(),
            Value<int?> tejidoDocumentId = const Value.absent(),
            Value<DateTime> uploadedAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<int> uploadDurationMs = const Value.absent(),
            Value<bool> wasOffline = const Value.absent(),
          }) =>
              UploadHistoryCompanion(
            id: id,
            personId: personId,
            personName: personName,
            documentType: documentType,
            tejidoDocumentId: tejidoDocumentId,
            uploadedAt: uploadedAt,
            status: status,
            fileSize: fileSize,
            uploadDurationMs: uploadDurationMs,
            wasOffline: wasOffline,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String personId,
            required String personName,
            required String documentType,
            Value<int?> tejidoDocumentId = const Value.absent(),
            Value<DateTime> uploadedAt = const Value.absent(),
            required String status,
            Value<int> fileSize = const Value.absent(),
            Value<int> uploadDurationMs = const Value.absent(),
            Value<bool> wasOffline = const Value.absent(),
          }) =>
              UploadHistoryCompanion.insert(
            id: id,
            personId: personId,
            personName: personName,
            documentType: documentType,
            tejidoDocumentId: tejidoDocumentId,
            uploadedAt: uploadedAt,
            status: status,
            fileSize: fileSize,
            uploadDurationMs: uploadDurationMs,
            wasOffline: wasOffline,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UploadHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UploadHistoryTable,
    UploadHistoryData,
    $$UploadHistoryTableFilterComposer,
    $$UploadHistoryTableOrderingComposer,
    $$UploadHistoryTableAnnotationComposer,
    $$UploadHistoryTableCreateCompanionBuilder,
    $$UploadHistoryTableUpdateCompanionBuilder,
    (
      UploadHistoryData,
      BaseReferences<_$AppDatabase, $UploadHistoryTable, UploadHistoryData>
    ),
    UploadHistoryData,
    PrefetchHooks Function()>;
typedef $$PersonsTableCreateCompanionBuilder = PersonsCompanion Function({
  required String id,
  Value<String?> censusId,
  required String name,
  Value<String?> birthDate,
  Value<String?> lifeStage,
  Value<String?> familyRole,
  Value<String?> community,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$PersonsTableUpdateCompanionBuilder = PersonsCompanion Function({
  Value<String> id,
  Value<String?> censusId,
  Value<String> name,
  Value<String?> birthDate,
  Value<String?> lifeStage,
  Value<String?> familyRole,
  Value<String?> community,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get censusId => $composableBuilder(
      column: $table.censusId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lifeStage => $composableBuilder(
      column: $table.lifeStage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get familyRole => $composableBuilder(
      column: $table.familyRole, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get community => $composableBuilder(
      column: $table.community, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get censusId => $composableBuilder(
      column: $table.censusId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lifeStage => $composableBuilder(
      column: $table.lifeStage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get familyRole => $composableBuilder(
      column: $table.familyRole, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get community => $composableBuilder(
      column: $table.community, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get censusId =>
      $composableBuilder(column: $table.censusId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get lifeStage =>
      $composableBuilder(column: $table.lifeStage, builder: (column) => column);

  GeneratedColumn<String> get familyRole => $composableBuilder(
      column: $table.familyRole, builder: (column) => column);

  GeneratedColumn<String> get community =>
      $composableBuilder(column: $table.community, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$PersonsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PersonsTable,
    Person,
    $$PersonsTableFilterComposer,
    $$PersonsTableOrderingComposer,
    $$PersonsTableAnnotationComposer,
    $$PersonsTableCreateCompanionBuilder,
    $$PersonsTableUpdateCompanionBuilder,
    (Person, BaseReferences<_$AppDatabase, $PersonsTable, Person>),
    Person,
    PrefetchHooks Function()> {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> censusId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> birthDate = const Value.absent(),
            Value<String?> lifeStage = const Value.absent(),
            Value<String?> familyRole = const Value.absent(),
            Value<String?> community = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonsCompanion(
            id: id,
            censusId: censusId,
            name: name,
            birthDate: birthDate,
            lifeStage: lifeStage,
            familyRole: familyRole,
            community: community,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> censusId = const Value.absent(),
            required String name,
            Value<String?> birthDate = const Value.absent(),
            Value<String?> lifeStage = const Value.absent(),
            Value<String?> familyRole = const Value.absent(),
            Value<String?> community = const Value.absent(),
            required DateTime syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonsCompanion.insert(
            id: id,
            censusId: censusId,
            name: name,
            birthDate: birthDate,
            lifeStage: lifeStage,
            familyRole: familyRole,
            community: community,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PersonsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PersonsTable,
    Person,
    $$PersonsTableFilterComposer,
    $$PersonsTableOrderingComposer,
    $$PersonsTableAnnotationComposer,
    $$PersonsTableCreateCompanionBuilder,
    $$PersonsTableUpdateCompanionBuilder,
    (Person, BaseReferences<_$AppDatabase, $PersonsTable, Person>),
    Person,
    PrefetchHooks Function()>;
typedef $$DocumentTypesTableCreateCompanionBuilder = DocumentTypesCompanion
    Function({
  Value<int> id,
  required String name,
  required DateTime cachedAt,
});
typedef $$DocumentTypesTableUpdateCompanionBuilder = DocumentTypesCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> cachedAt,
});

class $$DocumentTypesTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentTypesTable> {
  $$DocumentTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$DocumentTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentTypesTable> {
  $$DocumentTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$DocumentTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentTypesTable> {
  $$DocumentTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$DocumentTypesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentTypesTable,
    DocumentType,
    $$DocumentTypesTableFilterComposer,
    $$DocumentTypesTableOrderingComposer,
    $$DocumentTypesTableAnnotationComposer,
    $$DocumentTypesTableCreateCompanionBuilder,
    $$DocumentTypesTableUpdateCompanionBuilder,
    (
      DocumentType,
      BaseReferences<_$AppDatabase, $DocumentTypesTable, DocumentType>
    ),
    DocumentType,
    PrefetchHooks Function()> {
  $$DocumentTypesTableTableManager(_$AppDatabase db, $DocumentTypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              DocumentTypesCompanion(
            id: id,
            name: name,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required DateTime cachedAt,
          }) =>
              DocumentTypesCompanion.insert(
            id: id,
            name: name,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentTypesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentTypesTable,
    DocumentType,
    $$DocumentTypesTableFilterComposer,
    $$DocumentTypesTableOrderingComposer,
    $$DocumentTypesTableAnnotationComposer,
    $$DocumentTypesTableCreateCompanionBuilder,
    $$DocumentTypesTableUpdateCompanionBuilder,
    (
      DocumentType,
      BaseReferences<_$AppDatabase, $DocumentTypesTable, DocumentType>
    ),
    DocumentType,
    PrefetchHooks Function()>;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> color,
  required DateTime cachedAt,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> color,
  Value<DateTime> cachedAt,
});

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$TagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
    Tag,
    PrefetchHooks Function()> {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              TagsCompanion(
            id: id,
            name: name,
            color: color,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> color = const Value.absent(),
            required DateTime cachedAt,
          }) =>
              TagsCompanion.insert(
            id: id,
            name: name,
            color: color,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
    Tag,
    PrefetchHooks Function()>;
typedef $$CustomFieldsTableCreateCompanionBuilder = CustomFieldsCompanion
    Function({
  Value<int> id,
  required String name,
  required String dataType,
  required DateTime cachedAt,
});
typedef $$CustomFieldsTableUpdateCompanionBuilder = CustomFieldsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> dataType,
  Value<DateTime> cachedAt,
});

class $$CustomFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomFieldsTable> {
  $$CustomFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataType => $composableBuilder(
      column: $table.dataType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CustomFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomFieldsTable> {
  $$CustomFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataType => $composableBuilder(
      column: $table.dataType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomFieldsTable> {
  $$CustomFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dataType =>
      $composableBuilder(column: $table.dataType, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CustomFieldsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomFieldsTable,
    CustomField,
    $$CustomFieldsTableFilterComposer,
    $$CustomFieldsTableOrderingComposer,
    $$CustomFieldsTableAnnotationComposer,
    $$CustomFieldsTableCreateCompanionBuilder,
    $$CustomFieldsTableUpdateCompanionBuilder,
    (
      CustomField,
      BaseReferences<_$AppDatabase, $CustomFieldsTable, CustomField>
    ),
    CustomField,
    PrefetchHooks Function()> {
  $$CustomFieldsTableTableManager(_$AppDatabase db, $CustomFieldsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> dataType = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              CustomFieldsCompanion(
            id: id,
            name: name,
            dataType: dataType,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String dataType,
            required DateTime cachedAt,
          }) =>
              CustomFieldsCompanion.insert(
            id: id,
            name: name,
            dataType: dataType,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomFieldsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomFieldsTable,
    CustomField,
    $$CustomFieldsTableFilterComposer,
    $$CustomFieldsTableOrderingComposer,
    $$CustomFieldsTableAnnotationComposer,
    $$CustomFieldsTableCreateCompanionBuilder,
    $$CustomFieldsTableUpdateCompanionBuilder,
    (
      CustomField,
      BaseReferences<_$AppDatabase, $CustomFieldsTable, CustomField>
    ),
    CustomField,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PendingUploadsTableTableManager get pendingUploads =>
      $$PendingUploadsTableTableManager(_db, _db.pendingUploads);
  $$UploadHistoryTableTableManager get uploadHistory =>
      $$UploadHistoryTableTableManager(_db, _db.uploadHistory);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$DocumentTypesTableTableManager get documentTypes =>
      $$DocumentTypesTableTableManager(_db, _db.documentTypes);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$CustomFieldsTableTableManager get customFields =>
      $$CustomFieldsTableTableManager(_db, _db.customFields);
}
