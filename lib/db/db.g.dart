// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $ConversationTable extends Conversation
    with TableInfo<$ConversationTable, ConversationData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'New Conversation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buildMeta = const VerificationMeta('build');
  @override
  late final GeneratedColumn<String> build = GeneratedColumn<String>(
    'build',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    title,
    data,
    build,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('New Conversation')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['New Conversation']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('build')) {
      context.handle(
        _buildMeta,
        build.isAcceptableOrUnknown(data['build']!, _buildMeta),
      );
    } else if (isInserting) {
      context.missing(_buildMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ConversationData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationData(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}New Conversation'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      build: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}build'],
      )!,
    );
  }

  @override
  $ConversationTable createAlias(String alias) {
    return $ConversationTable(attachedDatabase, alias);
  }
}

class ConversationData extends DataClass
    implements Insertable<ConversationData> {
  final int createdAt;
  final int? updatedAt;
  final String title;
  final String data;
  final String build;
  const ConversationData({
    required this.createdAt,
    this.updatedAt,
    required this.title,
    required this.data,
    required this.build,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    map['New Conversation'] = Variable<String>(title);
    map['data'] = Variable<String>(data);
    map['build'] = Variable<String>(build);
    return map;
  }

  ConversationCompanion toCompanion(bool nullToAbsent) {
    return ConversationCompanion(
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      title: Value(title),
      data: Value(data),
      build: Value(build),
    );
  }

  factory ConversationData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationData(
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      title: serializer.fromJson<String>(json['title']),
      data: serializer.fromJson<String>(json['data']),
      build: serializer.fromJson<String>(json['build']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'title': serializer.toJson<String>(title),
      'data': serializer.toJson<String>(data),
      'build': serializer.toJson<String>(build),
    };
  }

  ConversationData copyWith({
    int? createdAt,
    Value<int?> updatedAt = const Value.absent(),
    String? title,
    String? data,
    String? build,
  }) => ConversationData(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    title: title ?? this.title,
    data: data ?? this.data,
    build: build ?? this.build,
  );
  ConversationData copyWithCompanion(ConversationCompanion data) {
    return ConversationData(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      title: data.title.present ? data.title.value : this.title,
      data: data.data.present ? data.data.value : this.data,
      build: data.build.present ? data.build.value : this.build,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationData(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('title: $title, ')
          ..write('data: $data, ')
          ..write('build: $build')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(createdAt, updatedAt, title, data, build);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationData &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.title == this.title &&
          other.data == this.data &&
          other.build == this.build);
}

class ConversationCompanion extends UpdateCompanion<ConversationData> {
  final Value<int> createdAt;
  final Value<int?> updatedAt;
  final Value<String> title;
  final Value<String> data;
  final Value<String> build;
  final Value<int> rowid;
  const ConversationCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.data = const Value.absent(),
    this.build = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationCompanion.insert({
    required int createdAt,
    this.updatedAt = const Value.absent(),
    required String title,
    required String data,
    required String build,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       title = Value(title),
       data = Value(data),
       build = Value(build);
  static Insertable<ConversationData> custom({
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? title,
    Expression<String>? data,
    Expression<String>? build,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (title != null) 'New Conversation': title,
      if (data != null) 'data': data,
      if (build != null) 'build': build,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationCompanion copyWith({
    Value<int>? createdAt,
    Value<int?>? updatedAt,
    Value<String>? title,
    Value<String>? data,
    Value<String>? build,
    Value<int>? rowid,
  }) {
    return ConversationCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      data: data ?? this.data,
      build: build ?? this.build,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (title.present) {
      map['New Conversation'] = Variable<String>(title.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (build.present) {
      map['build'] = Variable<String>(build.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('title: $title, ')
          ..write('data: $data, ')
          ..write('build: $build, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MsgTable extends Msg with TableInfo<$MsgTable, MsgData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MsgTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isMineMeta = const VerificationMeta('isMine');
  @override
  late final GeneratedColumn<bool> isMine = GeneratedColumn<bool>(
    'is_mine',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mine" IN (0, 1))',
    ),
  );
  static const VerificationMeta _changingMeta = const VerificationMeta(
    'changing',
  );
  @override
  late final GeneratedColumn<bool> changing = GeneratedColumn<bool>(
    'changing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("changing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReasoningMeta = const VerificationMeta(
    'isReasoning',
  );
  @override
  late final GeneratedColumn<bool> isReasoning = GeneratedColumn<bool>(
    'is_reasoning',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_reasoning" IN (0, 1))',
    ),
  );
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  @override
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
    'paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paused" IN (0, 1))',
    ),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioLengthMeta = const VerificationMeta(
    'audioLength',
  );
  @override
  late final GeneratedColumn<int> audioLength = GeneratedColumn<int>(
    'audio_length',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSensitiveMeta = const VerificationMeta(
    'isSensitive',
  );
  @override
  late final GeneratedColumn<bool> isSensitive = GeneratedColumn<bool>(
    'is_sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sensitive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ttsCFMStepsMeta = const VerificationMeta(
    'ttsCFMSteps',
  );
  @override
  late final GeneratedColumn<int> ttsCFMSteps = GeneratedColumn<int>(
    'tts_c_f_m_steps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ttsTargetMeta = const VerificationMeta(
    'ttsTarget',
  );
  @override
  late final GeneratedColumn<String> ttsTarget = GeneratedColumn<String>(
    'tts_target',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ttsSpeakerNameMeta = const VerificationMeta(
    'ttsSpeakerName',
  );
  @override
  late final GeneratedColumn<String> ttsSpeakerName = GeneratedColumn<String>(
    'tts_speaker_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ttsSourceAudioPathMeta =
      const VerificationMeta('ttsSourceAudioPath');
  @override
  late final GeneratedColumn<String> ttsSourceAudioPath =
      GeneratedColumn<String>(
        'tts_source_audio_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ttsInstructionMeta = const VerificationMeta(
    'ttsInstruction',
  );
  @override
  late final GeneratedColumn<String> ttsInstruction = GeneratedColumn<String>(
    'tts_instruction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ttsOverallProgressMeta =
      const VerificationMeta('ttsOverallProgress');
  @override
  late final GeneratedColumn<double> ttsOverallProgress =
      GeneratedColumn<double>(
        'tts_overall_progress',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ttsPerWavProgressMeta = const VerificationMeta(
    'ttsPerWavProgress',
  );
  @override
  late final GeneratedColumn<String> ttsPerWavProgress =
      GeneratedColumn<String>(
        'tts_per_wav_progress',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ttsFilePathsMeta = const VerificationMeta(
    'ttsFilePaths',
  );
  @override
  late final GeneratedColumn<String> ttsFilePaths = GeneratedColumn<String>(
    'tts_file_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runningModeMeta = const VerificationMeta(
    'runningMode',
  );
  @override
  late final GeneratedColumn<String> runningMode = GeneratedColumn<String>(
    'running_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buildMeta = const VerificationMeta('build');
  @override
  late final GeneratedColumn<String> build = GeneratedColumn<String>(
    'build',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    isMine,
    changing,
    type,
    isReasoning,
    paused,
    imageUrl,
    audioUrl,
    audioLength,
    isSensitive,
    ttsCFMSteps,
    ttsTarget,
    ttsSpeakerName,
    ttsSourceAudioPath,
    ttsInstruction,
    ttsOverallProgress,
    ttsPerWavProgress,
    ttsFilePaths,
    modelName,
    runningMode,
    build,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'msg';
  @override
  VerificationContext validateIntegrity(
    Insertable<MsgData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_mine')) {
      context.handle(
        _isMineMeta,
        isMine.isAcceptableOrUnknown(data['is_mine']!, _isMineMeta),
      );
    } else if (isInserting) {
      context.missing(_isMineMeta);
    }
    if (data.containsKey('changing')) {
      context.handle(
        _changingMeta,
        changing.isAcceptableOrUnknown(data['changing']!, _changingMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('is_reasoning')) {
      context.handle(
        _isReasoningMeta,
        isReasoning.isAcceptableOrUnknown(
          data['is_reasoning']!,
          _isReasoningMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isReasoningMeta);
    }
    if (data.containsKey('paused')) {
      context.handle(
        _pausedMeta,
        paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta),
      );
    } else if (isInserting) {
      context.missing(_pausedMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    }
    if (data.containsKey('audio_length')) {
      context.handle(
        _audioLengthMeta,
        audioLength.isAcceptableOrUnknown(
          data['audio_length']!,
          _audioLengthMeta,
        ),
      );
    }
    if (data.containsKey('is_sensitive')) {
      context.handle(
        _isSensitiveMeta,
        isSensitive.isAcceptableOrUnknown(
          data['is_sensitive']!,
          _isSensitiveMeta,
        ),
      );
    }
    if (data.containsKey('tts_c_f_m_steps')) {
      context.handle(
        _ttsCFMStepsMeta,
        ttsCFMSteps.isAcceptableOrUnknown(
          data['tts_c_f_m_steps']!,
          _ttsCFMStepsMeta,
        ),
      );
    }
    if (data.containsKey('tts_target')) {
      context.handle(
        _ttsTargetMeta,
        ttsTarget.isAcceptableOrUnknown(data['tts_target']!, _ttsTargetMeta),
      );
    }
    if (data.containsKey('tts_speaker_name')) {
      context.handle(
        _ttsSpeakerNameMeta,
        ttsSpeakerName.isAcceptableOrUnknown(
          data['tts_speaker_name']!,
          _ttsSpeakerNameMeta,
        ),
      );
    }
    if (data.containsKey('tts_source_audio_path')) {
      context.handle(
        _ttsSourceAudioPathMeta,
        ttsSourceAudioPath.isAcceptableOrUnknown(
          data['tts_source_audio_path']!,
          _ttsSourceAudioPathMeta,
        ),
      );
    }
    if (data.containsKey('tts_instruction')) {
      context.handle(
        _ttsInstructionMeta,
        ttsInstruction.isAcceptableOrUnknown(
          data['tts_instruction']!,
          _ttsInstructionMeta,
        ),
      );
    }
    if (data.containsKey('tts_overall_progress')) {
      context.handle(
        _ttsOverallProgressMeta,
        ttsOverallProgress.isAcceptableOrUnknown(
          data['tts_overall_progress']!,
          _ttsOverallProgressMeta,
        ),
      );
    }
    if (data.containsKey('tts_per_wav_progress')) {
      context.handle(
        _ttsPerWavProgressMeta,
        ttsPerWavProgress.isAcceptableOrUnknown(
          data['tts_per_wav_progress']!,
          _ttsPerWavProgressMeta,
        ),
      );
    }
    if (data.containsKey('tts_file_paths')) {
      context.handle(
        _ttsFilePathsMeta,
        ttsFilePaths.isAcceptableOrUnknown(
          data['tts_file_paths']!,
          _ttsFilePathsMeta,
        ),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('running_mode')) {
      context.handle(
        _runningModeMeta,
        runningMode.isAcceptableOrUnknown(
          data['running_mode']!,
          _runningModeMeta,
        ),
      );
    }
    if (data.containsKey('build')) {
      context.handle(
        _buildMeta,
        build.isAcceptableOrUnknown(data['build']!, _buildMeta),
      );
    } else if (isInserting) {
      context.missing(_buildMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MsgData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MsgData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      isMine: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mine'],
      )!,
      changing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}changing'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      isReasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_reasoning'],
      )!,
      paused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paused'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      ),
      audioLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}audio_length'],
      ),
      isSensitive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_sensitive'],
      )!,
      ttsCFMSteps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tts_c_f_m_steps'],
      ),
      ttsTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_target'],
      ),
      ttsSpeakerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_speaker_name'],
      ),
      ttsSourceAudioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_source_audio_path'],
      ),
      ttsInstruction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_instruction'],
      ),
      ttsOverallProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tts_overall_progress'],
      ),
      ttsPerWavProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_per_wav_progress'],
      ),
      ttsFilePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_file_paths'],
      ),
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      ),
      runningMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}running_mode'],
      ),
      build: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}build'],
      )!,
    );
  }

  @override
  $MsgTable createAlias(String alias) {
    return $MsgTable(attachedDatabase, alias);
  }
}

class MsgData extends DataClass implements Insertable<MsgData> {
  final int id;
  final String content;
  final bool isMine;
  final bool changing;
  final String type;
  final bool isReasoning;
  final bool paused;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioLength;
  final bool isSensitive;
  final int? ttsCFMSteps;
  final String? ttsTarget;
  final String? ttsSpeakerName;
  final String? ttsSourceAudioPath;
  final String? ttsInstruction;
  final double? ttsOverallProgress;
  final String? ttsPerWavProgress;
  final String? ttsFilePaths;
  final String? modelName;
  final String? runningMode;
  final String build;
  const MsgData({
    required this.id,
    required this.content,
    required this.isMine,
    required this.changing,
    required this.type,
    required this.isReasoning,
    required this.paused,
    this.imageUrl,
    this.audioUrl,
    this.audioLength,
    required this.isSensitive,
    this.ttsCFMSteps,
    this.ttsTarget,
    this.ttsSpeakerName,
    this.ttsSourceAudioPath,
    this.ttsInstruction,
    this.ttsOverallProgress,
    this.ttsPerWavProgress,
    this.ttsFilePaths,
    this.modelName,
    this.runningMode,
    required this.build,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['is_mine'] = Variable<bool>(isMine);
    map['changing'] = Variable<bool>(changing);
    map['type'] = Variable<String>(type);
    map['is_reasoning'] = Variable<bool>(isReasoning);
    map['paused'] = Variable<bool>(paused);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    if (!nullToAbsent || audioLength != null) {
      map['audio_length'] = Variable<int>(audioLength);
    }
    map['is_sensitive'] = Variable<bool>(isSensitive);
    if (!nullToAbsent || ttsCFMSteps != null) {
      map['tts_c_f_m_steps'] = Variable<int>(ttsCFMSteps);
    }
    if (!nullToAbsent || ttsTarget != null) {
      map['tts_target'] = Variable<String>(ttsTarget);
    }
    if (!nullToAbsent || ttsSpeakerName != null) {
      map['tts_speaker_name'] = Variable<String>(ttsSpeakerName);
    }
    if (!nullToAbsent || ttsSourceAudioPath != null) {
      map['tts_source_audio_path'] = Variable<String>(ttsSourceAudioPath);
    }
    if (!nullToAbsent || ttsInstruction != null) {
      map['tts_instruction'] = Variable<String>(ttsInstruction);
    }
    if (!nullToAbsent || ttsOverallProgress != null) {
      map['tts_overall_progress'] = Variable<double>(ttsOverallProgress);
    }
    if (!nullToAbsent || ttsPerWavProgress != null) {
      map['tts_per_wav_progress'] = Variable<String>(ttsPerWavProgress);
    }
    if (!nullToAbsent || ttsFilePaths != null) {
      map['tts_file_paths'] = Variable<String>(ttsFilePaths);
    }
    if (!nullToAbsent || modelName != null) {
      map['model_name'] = Variable<String>(modelName);
    }
    if (!nullToAbsent || runningMode != null) {
      map['running_mode'] = Variable<String>(runningMode);
    }
    map['build'] = Variable<String>(build);
    return map;
  }

  MsgCompanion toCompanion(bool nullToAbsent) {
    return MsgCompanion(
      id: Value(id),
      content: Value(content),
      isMine: Value(isMine),
      changing: Value(changing),
      type: Value(type),
      isReasoning: Value(isReasoning),
      paused: Value(paused),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      audioLength: audioLength == null && nullToAbsent
          ? const Value.absent()
          : Value(audioLength),
      isSensitive: Value(isSensitive),
      ttsCFMSteps: ttsCFMSteps == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsCFMSteps),
      ttsTarget: ttsTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsTarget),
      ttsSpeakerName: ttsSpeakerName == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsSpeakerName),
      ttsSourceAudioPath: ttsSourceAudioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsSourceAudioPath),
      ttsInstruction: ttsInstruction == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsInstruction),
      ttsOverallProgress: ttsOverallProgress == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsOverallProgress),
      ttsPerWavProgress: ttsPerWavProgress == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsPerWavProgress),
      ttsFilePaths: ttsFilePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsFilePaths),
      modelName: modelName == null && nullToAbsent
          ? const Value.absent()
          : Value(modelName),
      runningMode: runningMode == null && nullToAbsent
          ? const Value.absent()
          : Value(runningMode),
      build: Value(build),
    );
  }

  factory MsgData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MsgData(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      isMine: serializer.fromJson<bool>(json['isMine']),
      changing: serializer.fromJson<bool>(json['changing']),
      type: serializer.fromJson<String>(json['type']),
      isReasoning: serializer.fromJson<bool>(json['isReasoning']),
      paused: serializer.fromJson<bool>(json['paused']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      audioLength: serializer.fromJson<int?>(json['audioLength']),
      isSensitive: serializer.fromJson<bool>(json['isSensitive']),
      ttsCFMSteps: serializer.fromJson<int?>(json['ttsCFMSteps']),
      ttsTarget: serializer.fromJson<String?>(json['ttsTarget']),
      ttsSpeakerName: serializer.fromJson<String?>(json['ttsSpeakerName']),
      ttsSourceAudioPath: serializer.fromJson<String?>(
        json['ttsSourceAudioPath'],
      ),
      ttsInstruction: serializer.fromJson<String?>(json['ttsInstruction']),
      ttsOverallProgress: serializer.fromJson<double?>(
        json['ttsOverallProgress'],
      ),
      ttsPerWavProgress: serializer.fromJson<String?>(
        json['ttsPerWavProgress'],
      ),
      ttsFilePaths: serializer.fromJson<String?>(json['ttsFilePaths']),
      modelName: serializer.fromJson<String?>(json['modelName']),
      runningMode: serializer.fromJson<String?>(json['runningMode']),
      build: serializer.fromJson<String>(json['build']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'isMine': serializer.toJson<bool>(isMine),
      'changing': serializer.toJson<bool>(changing),
      'type': serializer.toJson<String>(type),
      'isReasoning': serializer.toJson<bool>(isReasoning),
      'paused': serializer.toJson<bool>(paused),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'audioLength': serializer.toJson<int?>(audioLength),
      'isSensitive': serializer.toJson<bool>(isSensitive),
      'ttsCFMSteps': serializer.toJson<int?>(ttsCFMSteps),
      'ttsTarget': serializer.toJson<String?>(ttsTarget),
      'ttsSpeakerName': serializer.toJson<String?>(ttsSpeakerName),
      'ttsSourceAudioPath': serializer.toJson<String?>(ttsSourceAudioPath),
      'ttsInstruction': serializer.toJson<String?>(ttsInstruction),
      'ttsOverallProgress': serializer.toJson<double?>(ttsOverallProgress),
      'ttsPerWavProgress': serializer.toJson<String?>(ttsPerWavProgress),
      'ttsFilePaths': serializer.toJson<String?>(ttsFilePaths),
      'modelName': serializer.toJson<String?>(modelName),
      'runningMode': serializer.toJson<String?>(runningMode),
      'build': serializer.toJson<String>(build),
    };
  }

  MsgData copyWith({
    int? id,
    String? content,
    bool? isMine,
    bool? changing,
    String? type,
    bool? isReasoning,
    bool? paused,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> audioUrl = const Value.absent(),
    Value<int?> audioLength = const Value.absent(),
    bool? isSensitive,
    Value<int?> ttsCFMSteps = const Value.absent(),
    Value<String?> ttsTarget = const Value.absent(),
    Value<String?> ttsSpeakerName = const Value.absent(),
    Value<String?> ttsSourceAudioPath = const Value.absent(),
    Value<String?> ttsInstruction = const Value.absent(),
    Value<double?> ttsOverallProgress = const Value.absent(),
    Value<String?> ttsPerWavProgress = const Value.absent(),
    Value<String?> ttsFilePaths = const Value.absent(),
    Value<String?> modelName = const Value.absent(),
    Value<String?> runningMode = const Value.absent(),
    String? build,
  }) => MsgData(
    id: id ?? this.id,
    content: content ?? this.content,
    isMine: isMine ?? this.isMine,
    changing: changing ?? this.changing,
    type: type ?? this.type,
    isReasoning: isReasoning ?? this.isReasoning,
    paused: paused ?? this.paused,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
    audioLength: audioLength.present ? audioLength.value : this.audioLength,
    isSensitive: isSensitive ?? this.isSensitive,
    ttsCFMSteps: ttsCFMSteps.present ? ttsCFMSteps.value : this.ttsCFMSteps,
    ttsTarget: ttsTarget.present ? ttsTarget.value : this.ttsTarget,
    ttsSpeakerName: ttsSpeakerName.present
        ? ttsSpeakerName.value
        : this.ttsSpeakerName,
    ttsSourceAudioPath: ttsSourceAudioPath.present
        ? ttsSourceAudioPath.value
        : this.ttsSourceAudioPath,
    ttsInstruction: ttsInstruction.present
        ? ttsInstruction.value
        : this.ttsInstruction,
    ttsOverallProgress: ttsOverallProgress.present
        ? ttsOverallProgress.value
        : this.ttsOverallProgress,
    ttsPerWavProgress: ttsPerWavProgress.present
        ? ttsPerWavProgress.value
        : this.ttsPerWavProgress,
    ttsFilePaths: ttsFilePaths.present ? ttsFilePaths.value : this.ttsFilePaths,
    modelName: modelName.present ? modelName.value : this.modelName,
    runningMode: runningMode.present ? runningMode.value : this.runningMode,
    build: build ?? this.build,
  );
  MsgData copyWithCompanion(MsgCompanion data) {
    return MsgData(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      isMine: data.isMine.present ? data.isMine.value : this.isMine,
      changing: data.changing.present ? data.changing.value : this.changing,
      type: data.type.present ? data.type.value : this.type,
      isReasoning: data.isReasoning.present
          ? data.isReasoning.value
          : this.isReasoning,
      paused: data.paused.present ? data.paused.value : this.paused,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      audioLength: data.audioLength.present
          ? data.audioLength.value
          : this.audioLength,
      isSensitive: data.isSensitive.present
          ? data.isSensitive.value
          : this.isSensitive,
      ttsCFMSteps: data.ttsCFMSteps.present
          ? data.ttsCFMSteps.value
          : this.ttsCFMSteps,
      ttsTarget: data.ttsTarget.present ? data.ttsTarget.value : this.ttsTarget,
      ttsSpeakerName: data.ttsSpeakerName.present
          ? data.ttsSpeakerName.value
          : this.ttsSpeakerName,
      ttsSourceAudioPath: data.ttsSourceAudioPath.present
          ? data.ttsSourceAudioPath.value
          : this.ttsSourceAudioPath,
      ttsInstruction: data.ttsInstruction.present
          ? data.ttsInstruction.value
          : this.ttsInstruction,
      ttsOverallProgress: data.ttsOverallProgress.present
          ? data.ttsOverallProgress.value
          : this.ttsOverallProgress,
      ttsPerWavProgress: data.ttsPerWavProgress.present
          ? data.ttsPerWavProgress.value
          : this.ttsPerWavProgress,
      ttsFilePaths: data.ttsFilePaths.present
          ? data.ttsFilePaths.value
          : this.ttsFilePaths,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      runningMode: data.runningMode.present
          ? data.runningMode.value
          : this.runningMode,
      build: data.build.present ? data.build.value : this.build,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MsgData(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('isMine: $isMine, ')
          ..write('changing: $changing, ')
          ..write('type: $type, ')
          ..write('isReasoning: $isReasoning, ')
          ..write('paused: $paused, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('audioLength: $audioLength, ')
          ..write('isSensitive: $isSensitive, ')
          ..write('ttsCFMSteps: $ttsCFMSteps, ')
          ..write('ttsTarget: $ttsTarget, ')
          ..write('ttsSpeakerName: $ttsSpeakerName, ')
          ..write('ttsSourceAudioPath: $ttsSourceAudioPath, ')
          ..write('ttsInstruction: $ttsInstruction, ')
          ..write('ttsOverallProgress: $ttsOverallProgress, ')
          ..write('ttsPerWavProgress: $ttsPerWavProgress, ')
          ..write('ttsFilePaths: $ttsFilePaths, ')
          ..write('modelName: $modelName, ')
          ..write('runningMode: $runningMode, ')
          ..write('build: $build')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    content,
    isMine,
    changing,
    type,
    isReasoning,
    paused,
    imageUrl,
    audioUrl,
    audioLength,
    isSensitive,
    ttsCFMSteps,
    ttsTarget,
    ttsSpeakerName,
    ttsSourceAudioPath,
    ttsInstruction,
    ttsOverallProgress,
    ttsPerWavProgress,
    ttsFilePaths,
    modelName,
    runningMode,
    build,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MsgData &&
          other.id == this.id &&
          other.content == this.content &&
          other.isMine == this.isMine &&
          other.changing == this.changing &&
          other.type == this.type &&
          other.isReasoning == this.isReasoning &&
          other.paused == this.paused &&
          other.imageUrl == this.imageUrl &&
          other.audioUrl == this.audioUrl &&
          other.audioLength == this.audioLength &&
          other.isSensitive == this.isSensitive &&
          other.ttsCFMSteps == this.ttsCFMSteps &&
          other.ttsTarget == this.ttsTarget &&
          other.ttsSpeakerName == this.ttsSpeakerName &&
          other.ttsSourceAudioPath == this.ttsSourceAudioPath &&
          other.ttsInstruction == this.ttsInstruction &&
          other.ttsOverallProgress == this.ttsOverallProgress &&
          other.ttsPerWavProgress == this.ttsPerWavProgress &&
          other.ttsFilePaths == this.ttsFilePaths &&
          other.modelName == this.modelName &&
          other.runningMode == this.runningMode &&
          other.build == this.build);
}

class MsgCompanion extends UpdateCompanion<MsgData> {
  final Value<int> id;
  final Value<String> content;
  final Value<bool> isMine;
  final Value<bool> changing;
  final Value<String> type;
  final Value<bool> isReasoning;
  final Value<bool> paused;
  final Value<String?> imageUrl;
  final Value<String?> audioUrl;
  final Value<int?> audioLength;
  final Value<bool> isSensitive;
  final Value<int?> ttsCFMSteps;
  final Value<String?> ttsTarget;
  final Value<String?> ttsSpeakerName;
  final Value<String?> ttsSourceAudioPath;
  final Value<String?> ttsInstruction;
  final Value<double?> ttsOverallProgress;
  final Value<String?> ttsPerWavProgress;
  final Value<String?> ttsFilePaths;
  final Value<String?> modelName;
  final Value<String?> runningMode;
  final Value<String> build;
  const MsgCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.isMine = const Value.absent(),
    this.changing = const Value.absent(),
    this.type = const Value.absent(),
    this.isReasoning = const Value.absent(),
    this.paused = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.audioLength = const Value.absent(),
    this.isSensitive = const Value.absent(),
    this.ttsCFMSteps = const Value.absent(),
    this.ttsTarget = const Value.absent(),
    this.ttsSpeakerName = const Value.absent(),
    this.ttsSourceAudioPath = const Value.absent(),
    this.ttsInstruction = const Value.absent(),
    this.ttsOverallProgress = const Value.absent(),
    this.ttsPerWavProgress = const Value.absent(),
    this.ttsFilePaths = const Value.absent(),
    this.modelName = const Value.absent(),
    this.runningMode = const Value.absent(),
    this.build = const Value.absent(),
  });
  MsgCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required bool isMine,
    this.changing = const Value.absent(),
    required String type,
    required bool isReasoning,
    required bool paused,
    this.imageUrl = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.audioLength = const Value.absent(),
    this.isSensitive = const Value.absent(),
    this.ttsCFMSteps = const Value.absent(),
    this.ttsTarget = const Value.absent(),
    this.ttsSpeakerName = const Value.absent(),
    this.ttsSourceAudioPath = const Value.absent(),
    this.ttsInstruction = const Value.absent(),
    this.ttsOverallProgress = const Value.absent(),
    this.ttsPerWavProgress = const Value.absent(),
    this.ttsFilePaths = const Value.absent(),
    this.modelName = const Value.absent(),
    this.runningMode = const Value.absent(),
    required String build,
  }) : content = Value(content),
       isMine = Value(isMine),
       type = Value(type),
       isReasoning = Value(isReasoning),
       paused = Value(paused),
       build = Value(build);
  static Insertable<MsgData> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<bool>? isMine,
    Expression<bool>? changing,
    Expression<String>? type,
    Expression<bool>? isReasoning,
    Expression<bool>? paused,
    Expression<String>? imageUrl,
    Expression<String>? audioUrl,
    Expression<int>? audioLength,
    Expression<bool>? isSensitive,
    Expression<int>? ttsCFMSteps,
    Expression<String>? ttsTarget,
    Expression<String>? ttsSpeakerName,
    Expression<String>? ttsSourceAudioPath,
    Expression<String>? ttsInstruction,
    Expression<double>? ttsOverallProgress,
    Expression<String>? ttsPerWavProgress,
    Expression<String>? ttsFilePaths,
    Expression<String>? modelName,
    Expression<String>? runningMode,
    Expression<String>? build,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (isMine != null) 'is_mine': isMine,
      if (changing != null) 'changing': changing,
      if (type != null) 'type': type,
      if (isReasoning != null) 'is_reasoning': isReasoning,
      if (paused != null) 'paused': paused,
      if (imageUrl != null) 'image_url': imageUrl,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (audioLength != null) 'audio_length': audioLength,
      if (isSensitive != null) 'is_sensitive': isSensitive,
      if (ttsCFMSteps != null) 'tts_c_f_m_steps': ttsCFMSteps,
      if (ttsTarget != null) 'tts_target': ttsTarget,
      if (ttsSpeakerName != null) 'tts_speaker_name': ttsSpeakerName,
      if (ttsSourceAudioPath != null)
        'tts_source_audio_path': ttsSourceAudioPath,
      if (ttsInstruction != null) 'tts_instruction': ttsInstruction,
      if (ttsOverallProgress != null)
        'tts_overall_progress': ttsOverallProgress,
      if (ttsPerWavProgress != null) 'tts_per_wav_progress': ttsPerWavProgress,
      if (ttsFilePaths != null) 'tts_file_paths': ttsFilePaths,
      if (modelName != null) 'model_name': modelName,
      if (runningMode != null) 'running_mode': runningMode,
      if (build != null) 'build': build,
    });
  }

  MsgCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<bool>? isMine,
    Value<bool>? changing,
    Value<String>? type,
    Value<bool>? isReasoning,
    Value<bool>? paused,
    Value<String?>? imageUrl,
    Value<String?>? audioUrl,
    Value<int?>? audioLength,
    Value<bool>? isSensitive,
    Value<int?>? ttsCFMSteps,
    Value<String?>? ttsTarget,
    Value<String?>? ttsSpeakerName,
    Value<String?>? ttsSourceAudioPath,
    Value<String?>? ttsInstruction,
    Value<double?>? ttsOverallProgress,
    Value<String?>? ttsPerWavProgress,
    Value<String?>? ttsFilePaths,
    Value<String?>? modelName,
    Value<String?>? runningMode,
    Value<String>? build,
  }) {
    return MsgCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      isMine: isMine ?? this.isMine,
      changing: changing ?? this.changing,
      type: type ?? this.type,
      isReasoning: isReasoning ?? this.isReasoning,
      paused: paused ?? this.paused,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      audioLength: audioLength ?? this.audioLength,
      isSensitive: isSensitive ?? this.isSensitive,
      ttsCFMSteps: ttsCFMSteps ?? this.ttsCFMSteps,
      ttsTarget: ttsTarget ?? this.ttsTarget,
      ttsSpeakerName: ttsSpeakerName ?? this.ttsSpeakerName,
      ttsSourceAudioPath: ttsSourceAudioPath ?? this.ttsSourceAudioPath,
      ttsInstruction: ttsInstruction ?? this.ttsInstruction,
      ttsOverallProgress: ttsOverallProgress ?? this.ttsOverallProgress,
      ttsPerWavProgress: ttsPerWavProgress ?? this.ttsPerWavProgress,
      ttsFilePaths: ttsFilePaths ?? this.ttsFilePaths,
      modelName: modelName ?? this.modelName,
      runningMode: runningMode ?? this.runningMode,
      build: build ?? this.build,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isMine.present) {
      map['is_mine'] = Variable<bool>(isMine.value);
    }
    if (changing.present) {
      map['changing'] = Variable<bool>(changing.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (isReasoning.present) {
      map['is_reasoning'] = Variable<bool>(isReasoning.value);
    }
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (audioLength.present) {
      map['audio_length'] = Variable<int>(audioLength.value);
    }
    if (isSensitive.present) {
      map['is_sensitive'] = Variable<bool>(isSensitive.value);
    }
    if (ttsCFMSteps.present) {
      map['tts_c_f_m_steps'] = Variable<int>(ttsCFMSteps.value);
    }
    if (ttsTarget.present) {
      map['tts_target'] = Variable<String>(ttsTarget.value);
    }
    if (ttsSpeakerName.present) {
      map['tts_speaker_name'] = Variable<String>(ttsSpeakerName.value);
    }
    if (ttsSourceAudioPath.present) {
      map['tts_source_audio_path'] = Variable<String>(ttsSourceAudioPath.value);
    }
    if (ttsInstruction.present) {
      map['tts_instruction'] = Variable<String>(ttsInstruction.value);
    }
    if (ttsOverallProgress.present) {
      map['tts_overall_progress'] = Variable<double>(ttsOverallProgress.value);
    }
    if (ttsPerWavProgress.present) {
      map['tts_per_wav_progress'] = Variable<String>(ttsPerWavProgress.value);
    }
    if (ttsFilePaths.present) {
      map['tts_file_paths'] = Variable<String>(ttsFilePaths.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (runningMode.present) {
      map['running_mode'] = Variable<String>(runningMode.value);
    }
    if (build.present) {
      map['build'] = Variable<String>(build.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MsgCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('isMine: $isMine, ')
          ..write('changing: $changing, ')
          ..write('type: $type, ')
          ..write('isReasoning: $isReasoning, ')
          ..write('paused: $paused, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('audioLength: $audioLength, ')
          ..write('isSensitive: $isSensitive, ')
          ..write('ttsCFMSteps: $ttsCFMSteps, ')
          ..write('ttsTarget: $ttsTarget, ')
          ..write('ttsSpeakerName: $ttsSpeakerName, ')
          ..write('ttsSourceAudioPath: $ttsSourceAudioPath, ')
          ..write('ttsInstruction: $ttsInstruction, ')
          ..write('ttsOverallProgress: $ttsOverallProgress, ')
          ..write('ttsPerWavProgress: $ttsPerWavProgress, ')
          ..write('ttsFilePaths: $ttsFilePaths, ')
          ..write('modelName: $modelName, ')
          ..write('runningMode: $runningMode, ')
          ..write('build: $build')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConversationTable conversation = $ConversationTable(this);
  late final $MsgTable msg = $MsgTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [conversation, msg];
}

typedef $$ConversationTableCreateCompanionBuilder =
    ConversationCompanion Function({
      required int createdAt,
      Value<int?> updatedAt,
      required String title,
      required String data,
      required String build,
      Value<int> rowid,
    });
typedef $$ConversationTableUpdateCompanionBuilder =
    ConversationCompanion Function({
      Value<int> createdAt,
      Value<int?> updatedAt,
      Value<String> title,
      Value<String> data,
      Value<String> build,
      Value<int> rowid,
    });

class $$ConversationTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationTable> {
  $$ConversationTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get build => $composableBuilder(
    column: $table.build,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationTable> {
  $$ConversationTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get build => $composableBuilder(
    column: $table.build,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationTable> {
  $$ConversationTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get build =>
      $composableBuilder(column: $table.build, builder: (column) => column);
}

class $$ConversationTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationTable,
          ConversationData,
          $$ConversationTableFilterComposer,
          $$ConversationTableOrderingComposer,
          $$ConversationTableAnnotationComposer,
          $$ConversationTableCreateCompanionBuilder,
          $$ConversationTableUpdateCompanionBuilder,
          (
            ConversationData,
            BaseReferences<_$AppDatabase, $ConversationTable, ConversationData>,
          ),
          ConversationData,
          PrefetchHooks Function()
        > {
  $$ConversationTableTableManager(_$AppDatabase db, $ConversationTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<String> build = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationCompanion(
                createdAt: createdAt,
                updatedAt: updatedAt,
                title: title,
                data: data,
                build: build,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int createdAt,
                Value<int?> updatedAt = const Value.absent(),
                required String title,
                required String data,
                required String build,
                Value<int> rowid = const Value.absent(),
              }) => ConversationCompanion.insert(
                createdAt: createdAt,
                updatedAt: updatedAt,
                title: title,
                data: data,
                build: build,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationTable,
      ConversationData,
      $$ConversationTableFilterComposer,
      $$ConversationTableOrderingComposer,
      $$ConversationTableAnnotationComposer,
      $$ConversationTableCreateCompanionBuilder,
      $$ConversationTableUpdateCompanionBuilder,
      (
        ConversationData,
        BaseReferences<_$AppDatabase, $ConversationTable, ConversationData>,
      ),
      ConversationData,
      PrefetchHooks Function()
    >;
typedef $$MsgTableCreateCompanionBuilder =
    MsgCompanion Function({
      Value<int> id,
      required String content,
      required bool isMine,
      Value<bool> changing,
      required String type,
      required bool isReasoning,
      required bool paused,
      Value<String?> imageUrl,
      Value<String?> audioUrl,
      Value<int?> audioLength,
      Value<bool> isSensitive,
      Value<int?> ttsCFMSteps,
      Value<String?> ttsTarget,
      Value<String?> ttsSpeakerName,
      Value<String?> ttsSourceAudioPath,
      Value<String?> ttsInstruction,
      Value<double?> ttsOverallProgress,
      Value<String?> ttsPerWavProgress,
      Value<String?> ttsFilePaths,
      Value<String?> modelName,
      Value<String?> runningMode,
      required String build,
    });
typedef $$MsgTableUpdateCompanionBuilder =
    MsgCompanion Function({
      Value<int> id,
      Value<String> content,
      Value<bool> isMine,
      Value<bool> changing,
      Value<String> type,
      Value<bool> isReasoning,
      Value<bool> paused,
      Value<String?> imageUrl,
      Value<String?> audioUrl,
      Value<int?> audioLength,
      Value<bool> isSensitive,
      Value<int?> ttsCFMSteps,
      Value<String?> ttsTarget,
      Value<String?> ttsSpeakerName,
      Value<String?> ttsSourceAudioPath,
      Value<String?> ttsInstruction,
      Value<double?> ttsOverallProgress,
      Value<String?> ttsPerWavProgress,
      Value<String?> ttsFilePaths,
      Value<String?> modelName,
      Value<String?> runningMode,
      Value<String> build,
    });

class $$MsgTableFilterComposer extends Composer<_$AppDatabase, $MsgTable> {
  $$MsgTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMine => $composableBuilder(
    column: $table.isMine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get changing => $composableBuilder(
    column: $table.changing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReasoning => $composableBuilder(
    column: $table.isReasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get audioLength => $composableBuilder(
    column: $table.audioLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSensitive => $composableBuilder(
    column: $table.isSensitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ttsCFMSteps => $composableBuilder(
    column: $table.ttsCFMSteps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsTarget => $composableBuilder(
    column: $table.ttsTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsSpeakerName => $composableBuilder(
    column: $table.ttsSpeakerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsSourceAudioPath => $composableBuilder(
    column: $table.ttsSourceAudioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsInstruction => $composableBuilder(
    column: $table.ttsInstruction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ttsOverallProgress => $composableBuilder(
    column: $table.ttsOverallProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsPerWavProgress => $composableBuilder(
    column: $table.ttsPerWavProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsFilePaths => $composableBuilder(
    column: $table.ttsFilePaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runningMode => $composableBuilder(
    column: $table.runningMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get build => $composableBuilder(
    column: $table.build,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MsgTableOrderingComposer extends Composer<_$AppDatabase, $MsgTable> {
  $$MsgTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMine => $composableBuilder(
    column: $table.isMine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get changing => $composableBuilder(
    column: $table.changing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReasoning => $composableBuilder(
    column: $table.isReasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get audioLength => $composableBuilder(
    column: $table.audioLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSensitive => $composableBuilder(
    column: $table.isSensitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ttsCFMSteps => $composableBuilder(
    column: $table.ttsCFMSteps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsTarget => $composableBuilder(
    column: $table.ttsTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsSpeakerName => $composableBuilder(
    column: $table.ttsSpeakerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsSourceAudioPath => $composableBuilder(
    column: $table.ttsSourceAudioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsInstruction => $composableBuilder(
    column: $table.ttsInstruction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ttsOverallProgress => $composableBuilder(
    column: $table.ttsOverallProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsPerWavProgress => $composableBuilder(
    column: $table.ttsPerWavProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsFilePaths => $composableBuilder(
    column: $table.ttsFilePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runningMode => $composableBuilder(
    column: $table.runningMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get build => $composableBuilder(
    column: $table.build,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MsgTableAnnotationComposer extends Composer<_$AppDatabase, $MsgTable> {
  $$MsgTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isMine =>
      $composableBuilder(column: $table.isMine, builder: (column) => column);

  GeneratedColumn<bool> get changing =>
      $composableBuilder(column: $table.changing, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isReasoning => $composableBuilder(
    column: $table.isReasoning,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<int> get audioLength => $composableBuilder(
    column: $table.audioLength,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSensitive => $composableBuilder(
    column: $table.isSensitive,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ttsCFMSteps => $composableBuilder(
    column: $table.ttsCFMSteps,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ttsTarget =>
      $composableBuilder(column: $table.ttsTarget, builder: (column) => column);

  GeneratedColumn<String> get ttsSpeakerName => $composableBuilder(
    column: $table.ttsSpeakerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ttsSourceAudioPath => $composableBuilder(
    column: $table.ttsSourceAudioPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ttsInstruction => $composableBuilder(
    column: $table.ttsInstruction,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ttsOverallProgress => $composableBuilder(
    column: $table.ttsOverallProgress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ttsPerWavProgress => $composableBuilder(
    column: $table.ttsPerWavProgress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ttsFilePaths => $composableBuilder(
    column: $table.ttsFilePaths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get runningMode => $composableBuilder(
    column: $table.runningMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get build =>
      $composableBuilder(column: $table.build, builder: (column) => column);
}

class $$MsgTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MsgTable,
          MsgData,
          $$MsgTableFilterComposer,
          $$MsgTableOrderingComposer,
          $$MsgTableAnnotationComposer,
          $$MsgTableCreateCompanionBuilder,
          $$MsgTableUpdateCompanionBuilder,
          (MsgData, BaseReferences<_$AppDatabase, $MsgTable, MsgData>),
          MsgData,
          PrefetchHooks Function()
        > {
  $$MsgTableTableManager(_$AppDatabase db, $MsgTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MsgTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MsgTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MsgTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> isMine = const Value.absent(),
                Value<bool> changing = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> isReasoning = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<int?> audioLength = const Value.absent(),
                Value<bool> isSensitive = const Value.absent(),
                Value<int?> ttsCFMSteps = const Value.absent(),
                Value<String?> ttsTarget = const Value.absent(),
                Value<String?> ttsSpeakerName = const Value.absent(),
                Value<String?> ttsSourceAudioPath = const Value.absent(),
                Value<String?> ttsInstruction = const Value.absent(),
                Value<double?> ttsOverallProgress = const Value.absent(),
                Value<String?> ttsPerWavProgress = const Value.absent(),
                Value<String?> ttsFilePaths = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> runningMode = const Value.absent(),
                Value<String> build = const Value.absent(),
              }) => MsgCompanion(
                id: id,
                content: content,
                isMine: isMine,
                changing: changing,
                type: type,
                isReasoning: isReasoning,
                paused: paused,
                imageUrl: imageUrl,
                audioUrl: audioUrl,
                audioLength: audioLength,
                isSensitive: isSensitive,
                ttsCFMSteps: ttsCFMSteps,
                ttsTarget: ttsTarget,
                ttsSpeakerName: ttsSpeakerName,
                ttsSourceAudioPath: ttsSourceAudioPath,
                ttsInstruction: ttsInstruction,
                ttsOverallProgress: ttsOverallProgress,
                ttsPerWavProgress: ttsPerWavProgress,
                ttsFilePaths: ttsFilePaths,
                modelName: modelName,
                runningMode: runningMode,
                build: build,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                required bool isMine,
                Value<bool> changing = const Value.absent(),
                required String type,
                required bool isReasoning,
                required bool paused,
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<int?> audioLength = const Value.absent(),
                Value<bool> isSensitive = const Value.absent(),
                Value<int?> ttsCFMSteps = const Value.absent(),
                Value<String?> ttsTarget = const Value.absent(),
                Value<String?> ttsSpeakerName = const Value.absent(),
                Value<String?> ttsSourceAudioPath = const Value.absent(),
                Value<String?> ttsInstruction = const Value.absent(),
                Value<double?> ttsOverallProgress = const Value.absent(),
                Value<String?> ttsPerWavProgress = const Value.absent(),
                Value<String?> ttsFilePaths = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> runningMode = const Value.absent(),
                required String build,
              }) => MsgCompanion.insert(
                id: id,
                content: content,
                isMine: isMine,
                changing: changing,
                type: type,
                isReasoning: isReasoning,
                paused: paused,
                imageUrl: imageUrl,
                audioUrl: audioUrl,
                audioLength: audioLength,
                isSensitive: isSensitive,
                ttsCFMSteps: ttsCFMSteps,
                ttsTarget: ttsTarget,
                ttsSpeakerName: ttsSpeakerName,
                ttsSourceAudioPath: ttsSourceAudioPath,
                ttsInstruction: ttsInstruction,
                ttsOverallProgress: ttsOverallProgress,
                ttsPerWavProgress: ttsPerWavProgress,
                ttsFilePaths: ttsFilePaths,
                modelName: modelName,
                runningMode: runningMode,
                build: build,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MsgTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MsgTable,
      MsgData,
      $$MsgTableFilterComposer,
      $$MsgTableOrderingComposer,
      $$MsgTableAnnotationComposer,
      $$MsgTableCreateCompanionBuilder,
      $$MsgTableUpdateCompanionBuilder,
      (MsgData, BaseReferences<_$AppDatabase, $MsgTable, MsgData>),
      MsgData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConversationTableTableManager get conversation =>
      $$ConversationTableTableManager(_db, _db.conversation);
  $$MsgTableTableManager get msg => $$MsgTableTableManager(_db, _db.msg);
}
