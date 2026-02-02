// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPhotoPathMeta = const VerificationMeta(
    'coverPhotoPath',
  );
  @override
  late final GeneratedColumn<String> coverPhotoPath = GeneratedColumn<String>(
    'cover_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, coverPhotoPath, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover_photo_path')) {
      context.handle(
        _coverPhotoPathMeta,
        coverPhotoPath.isAcceptableOrUnknown(
          data['cover_photo_path']!,
          _coverPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      coverPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_photo_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final int id;
  final String name;
  final String? coverPhotoPath;
  final DateTime createdAt;
  const Device({
    required this.id,
    required this.name,
    this.coverPhotoPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || coverPhotoPath != null) {
      map['cover_photo_path'] = Variable<String>(coverPhotoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      name: Value(name),
      coverPhotoPath: coverPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPhotoPath),
      createdAt: Value(createdAt),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      coverPhotoPath: serializer.fromJson<String?>(json['coverPhotoPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'coverPhotoPath': serializer.toJson<String?>(coverPhotoPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Device copyWith({
    int? id,
    String? name,
    Value<String?> coverPhotoPath = const Value.absent(),
    DateTime? createdAt,
  }) => Device(
    id: id ?? this.id,
    name: name ?? this.name,
    coverPhotoPath: coverPhotoPath.present
        ? coverPhotoPath.value
        : this.coverPhotoPath,
    createdAt: createdAt ?? this.createdAt,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      coverPhotoPath: data.coverPhotoPath.present
          ? data.coverPhotoPath.value
          : this.coverPhotoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPhotoPath: $coverPhotoPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, coverPhotoPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.name == this.name &&
          other.coverPhotoPath == this.coverPhotoPath &&
          other.createdAt == this.createdAt);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> coverPhotoPath;
  final Value<DateTime> createdAt;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.coverPhotoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DevicesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.coverPhotoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Device> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? coverPhotoPath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (coverPhotoPath != null) 'cover_photo_path': coverPhotoPath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DevicesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? coverPhotoPath,
    Value<DateTime>? createdAt,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      createdAt: createdAt ?? this.createdAt,
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
    if (coverPhotoPath.present) {
      map['cover_photo_path'] = Variable<String>(coverPhotoPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPhotoPath: $coverPhotoPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GuidesTable extends Guides with TableInfo<$GuidesTable, Guide> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuidesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, deviceId, title, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guides';
  @override
  VerificationContext validateIntegrity(
    Insertable<Guide> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Guide map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Guide(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GuidesTable createAlias(String alias) {
    return $GuidesTable(attachedDatabase, alias);
  }
}

class Guide extends DataClass implements Insertable<Guide> {
  final int id;
  final int deviceId;
  final String title;
  final DateTime createdAt;
  const Guide({
    required this.id,
    required this.deviceId,
    required this.title,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<int>(deviceId);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GuidesCompanion toCompanion(bool nullToAbsent) {
    return GuidesCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      title: Value(title),
      createdAt: Value(createdAt),
    );
  }

  factory Guide.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Guide(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<int>(json['deviceId']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<int>(deviceId),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Guide copyWith({
    int? id,
    int? deviceId,
    String? title,
    DateTime? createdAt,
  }) => Guide(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
  );
  Guide copyWithCompanion(GuidesCompanion data) {
    return Guide(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Guide(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deviceId, title, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Guide &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.title == this.title &&
          other.createdAt == this.createdAt);
}

class GuidesCompanion extends UpdateCompanion<Guide> {
  final Value<int> id;
  final Value<int> deviceId;
  final Value<String> title;
  final Value<DateTime> createdAt;
  const GuidesCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GuidesCompanion.insert({
    this.id = const Value.absent(),
    required int deviceId,
    required String title,
    this.createdAt = const Value.absent(),
  }) : deviceId = Value(deviceId),
       title = Value(title);
  static Insertable<Guide> custom({
    Expression<int>? id,
    Expression<int>? deviceId,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GuidesCompanion copyWith({
    Value<int>? id,
    Value<int>? deviceId,
    Value<String>? title,
    Value<DateTime>? createdAt,
  }) {
    return GuidesCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuidesCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StepsTable extends Steps with TableInfo<$StepsTable, Step> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _guideIdMeta = const VerificationMeta(
    'guideId',
  );
  @override
  late final GeneratedColumn<int> guideId = GeneratedColumn<int>(
    'guide_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES guides (id)',
    ),
  );
  static const VerificationMeta _stepIndexMeta = const VerificationMeta(
    'stepIndex',
  );
  @override
  late final GeneratedColumn<int> stepIndex = GeneratedColumn<int>(
    'step_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instructionTextMeta = const VerificationMeta(
    'instructionText',
  );
  @override
  late final GeneratedColumn<String> instructionText = GeneratedColumn<String>(
    'instruction_text',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 300,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    guideId,
    stepIndex,
    instructionText,
    photoPath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<Step> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('guide_id')) {
      context.handle(
        _guideIdMeta,
        guideId.isAcceptableOrUnknown(data['guide_id']!, _guideIdMeta),
      );
    } else if (isInserting) {
      context.missing(_guideIdMeta);
    }
    if (data.containsKey('step_index')) {
      context.handle(
        _stepIndexMeta,
        stepIndex.isAcceptableOrUnknown(data['step_index']!, _stepIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_stepIndexMeta);
    }
    if (data.containsKey('instruction_text')) {
      context.handle(
        _instructionTextMeta,
        instructionText.isAcceptableOrUnknown(
          data['instruction_text']!,
          _instructionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instructionTextMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Step map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Step(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      guideId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}guide_id'],
      )!,
      stepIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_index'],
      )!,
      instructionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instruction_text'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StepsTable createAlias(String alias) {
    return $StepsTable(attachedDatabase, alias);
  }
}

class Step extends DataClass implements Insertable<Step> {
  final int id;
  final int guideId;
  final int stepIndex;
  final String instructionText;
  final String? photoPath;
  final DateTime createdAt;
  const Step({
    required this.id,
    required this.guideId,
    required this.stepIndex,
    required this.instructionText,
    this.photoPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['guide_id'] = Variable<int>(guideId);
    map['step_index'] = Variable<int>(stepIndex);
    map['instruction_text'] = Variable<String>(instructionText);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StepsCompanion toCompanion(bool nullToAbsent) {
    return StepsCompanion(
      id: Value(id),
      guideId: Value(guideId),
      stepIndex: Value(stepIndex),
      instructionText: Value(instructionText),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      createdAt: Value(createdAt),
    );
  }

  factory Step.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Step(
      id: serializer.fromJson<int>(json['id']),
      guideId: serializer.fromJson<int>(json['guideId']),
      stepIndex: serializer.fromJson<int>(json['stepIndex']),
      instructionText: serializer.fromJson<String>(json['instructionText']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'guideId': serializer.toJson<int>(guideId),
      'stepIndex': serializer.toJson<int>(stepIndex),
      'instructionText': serializer.toJson<String>(instructionText),
      'photoPath': serializer.toJson<String?>(photoPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Step copyWith({
    int? id,
    int? guideId,
    int? stepIndex,
    String? instructionText,
    Value<String?> photoPath = const Value.absent(),
    DateTime? createdAt,
  }) => Step(
    id: id ?? this.id,
    guideId: guideId ?? this.guideId,
    stepIndex: stepIndex ?? this.stepIndex,
    instructionText: instructionText ?? this.instructionText,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    createdAt: createdAt ?? this.createdAt,
  );
  Step copyWithCompanion(StepsCompanion data) {
    return Step(
      id: data.id.present ? data.id.value : this.id,
      guideId: data.guideId.present ? data.guideId.value : this.guideId,
      stepIndex: data.stepIndex.present ? data.stepIndex.value : this.stepIndex,
      instructionText: data.instructionText.present
          ? data.instructionText.value
          : this.instructionText,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Step(')
          ..write('id: $id, ')
          ..write('guideId: $guideId, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('instructionText: $instructionText, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    guideId,
    stepIndex,
    instructionText,
    photoPath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Step &&
          other.id == this.id &&
          other.guideId == this.guideId &&
          other.stepIndex == this.stepIndex &&
          other.instructionText == this.instructionText &&
          other.photoPath == this.photoPath &&
          other.createdAt == this.createdAt);
}

class StepsCompanion extends UpdateCompanion<Step> {
  final Value<int> id;
  final Value<int> guideId;
  final Value<int> stepIndex;
  final Value<String> instructionText;
  final Value<String?> photoPath;
  final Value<DateTime> createdAt;
  const StepsCompanion({
    this.id = const Value.absent(),
    this.guideId = const Value.absent(),
    this.stepIndex = const Value.absent(),
    this.instructionText = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StepsCompanion.insert({
    this.id = const Value.absent(),
    required int guideId,
    required int stepIndex,
    required String instructionText,
    this.photoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : guideId = Value(guideId),
       stepIndex = Value(stepIndex),
       instructionText = Value(instructionText);
  static Insertable<Step> custom({
    Expression<int>? id,
    Expression<int>? guideId,
    Expression<int>? stepIndex,
    Expression<String>? instructionText,
    Expression<String>? photoPath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (guideId != null) 'guide_id': guideId,
      if (stepIndex != null) 'step_index': stepIndex,
      if (instructionText != null) 'instruction_text': instructionText,
      if (photoPath != null) 'photo_path': photoPath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StepsCompanion copyWith({
    Value<int>? id,
    Value<int>? guideId,
    Value<int>? stepIndex,
    Value<String>? instructionText,
    Value<String?>? photoPath,
    Value<DateTime>? createdAt,
  }) {
    return StepsCompanion(
      id: id ?? this.id,
      guideId: guideId ?? this.guideId,
      stepIndex: stepIndex ?? this.stepIndex,
      instructionText: instructionText ?? this.instructionText,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (guideId.present) {
      map['guide_id'] = Variable<int>(guideId.value);
    }
    if (stepIndex.present) {
      map['step_index'] = Variable<int>(stepIndex.value);
    }
    if (instructionText.present) {
      map['instruction_text'] = Variable<String>(instructionText.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepsCompanion(')
          ..write('id: $id, ')
          ..write('guideId: $guideId, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('instructionText: $instructionText, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StepHighlightsTable extends StepHighlights
    with TableInfo<$StepHighlightsTable, StepHighlight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepHighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stepIdMeta = const VerificationMeta('stepId');
  @override
  late final GeneratedColumn<int> stepId = GeneratedColumn<int>(
    'step_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES steps (id)',
    ),
  );
  static const VerificationMeta _shapeMeta = const VerificationMeta('shape');
  @override
  late final GeneratedColumn<int> shape = GeneratedColumn<int>(
    'shape',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wMeta = const VerificationMeta('w');
  @override
  late final GeneratedColumn<double> w = GeneratedColumn<double>(
    'w',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hMeta = const VerificationMeta('h');
  @override
  late final GeneratedColumn<double> h = GeneratedColumn<double>(
    'h',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [stepId, shape, x, y, w, h, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'step_highlights';
  @override
  VerificationContext validateIntegrity(
    Insertable<StepHighlight> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('step_id')) {
      context.handle(
        _stepIdMeta,
        stepId.isAcceptableOrUnknown(data['step_id']!, _stepIdMeta),
      );
    }
    if (data.containsKey('shape')) {
      context.handle(
        _shapeMeta,
        shape.isAcceptableOrUnknown(data['shape']!, _shapeMeta),
      );
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('w')) {
      context.handle(_wMeta, w.isAcceptableOrUnknown(data['w']!, _wMeta));
    } else if (isInserting) {
      context.missing(_wMeta);
    }
    if (data.containsKey('h')) {
      context.handle(_hMeta, h.isAcceptableOrUnknown(data['h']!, _hMeta));
    } else if (isInserting) {
      context.missing(_hMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stepId};
  @override
  StepHighlight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StepHighlight(
      stepId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_id'],
      )!,
      shape: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shape'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      w: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}w'],
      )!,
      h: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}h'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StepHighlightsTable createAlias(String alias) {
    return $StepHighlightsTable(attachedDatabase, alias);
  }
}

class StepHighlight extends DataClass implements Insertable<StepHighlight> {
  final int stepId;
  final int shape;
  final double x;
  final double y;
  final double w;
  final double h;
  final DateTime updatedAt;
  const StepHighlight({
    required this.stepId,
    required this.shape,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['step_id'] = Variable<int>(stepId);
    map['shape'] = Variable<int>(shape);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['w'] = Variable<double>(w);
    map['h'] = Variable<double>(h);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StepHighlightsCompanion toCompanion(bool nullToAbsent) {
    return StepHighlightsCompanion(
      stepId: Value(stepId),
      shape: Value(shape),
      x: Value(x),
      y: Value(y),
      w: Value(w),
      h: Value(h),
      updatedAt: Value(updatedAt),
    );
  }

  factory StepHighlight.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StepHighlight(
      stepId: serializer.fromJson<int>(json['stepId']),
      shape: serializer.fromJson<int>(json['shape']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      w: serializer.fromJson<double>(json['w']),
      h: serializer.fromJson<double>(json['h']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stepId': serializer.toJson<int>(stepId),
      'shape': serializer.toJson<int>(shape),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'w': serializer.toJson<double>(w),
      'h': serializer.toJson<double>(h),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StepHighlight copyWith({
    int? stepId,
    int? shape,
    double? x,
    double? y,
    double? w,
    double? h,
    DateTime? updatedAt,
  }) => StepHighlight(
    stepId: stepId ?? this.stepId,
    shape: shape ?? this.shape,
    x: x ?? this.x,
    y: y ?? this.y,
    w: w ?? this.w,
    h: h ?? this.h,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StepHighlight copyWithCompanion(StepHighlightsCompanion data) {
    return StepHighlight(
      stepId: data.stepId.present ? data.stepId.value : this.stepId,
      shape: data.shape.present ? data.shape.value : this.shape,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      w: data.w.present ? data.w.value : this.w,
      h: data.h.present ? data.h.value : this.h,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StepHighlight(')
          ..write('stepId: $stepId, ')
          ..write('shape: $shape, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('w: $w, ')
          ..write('h: $h, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stepId, shape, x, y, w, h, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StepHighlight &&
          other.stepId == this.stepId &&
          other.shape == this.shape &&
          other.x == this.x &&
          other.y == this.y &&
          other.w == this.w &&
          other.h == this.h &&
          other.updatedAt == this.updatedAt);
}

class StepHighlightsCompanion extends UpdateCompanion<StepHighlight> {
  final Value<int> stepId;
  final Value<int> shape;
  final Value<double> x;
  final Value<double> y;
  final Value<double> w;
  final Value<double> h;
  final Value<DateTime> updatedAt;
  const StepHighlightsCompanion({
    this.stepId = const Value.absent(),
    this.shape = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.w = const Value.absent(),
    this.h = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StepHighlightsCompanion.insert({
    this.stepId = const Value.absent(),
    this.shape = const Value.absent(),
    required double x,
    required double y,
    required double w,
    required double h,
    this.updatedAt = const Value.absent(),
  }) : x = Value(x),
       y = Value(y),
       w = Value(w),
       h = Value(h);
  static Insertable<StepHighlight> custom({
    Expression<int>? stepId,
    Expression<int>? shape,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? w,
    Expression<double>? h,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (stepId != null) 'step_id': stepId,
      if (shape != null) 'shape': shape,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (w != null) 'w': w,
      if (h != null) 'h': h,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StepHighlightsCompanion copyWith({
    Value<int>? stepId,
    Value<int>? shape,
    Value<double>? x,
    Value<double>? y,
    Value<double>? w,
    Value<double>? h,
    Value<DateTime>? updatedAt,
  }) {
    return StepHighlightsCompanion(
      stepId: stepId ?? this.stepId,
      shape: shape ?? this.shape,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stepId.present) {
      map['step_id'] = Variable<int>(stepId.value);
    }
    if (shape.present) {
      map['shape'] = Variable<int>(shape.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (w.present) {
      map['w'] = Variable<double>(w.value);
    }
    if (h.present) {
      map['h'] = Variable<double>(h.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepHighlightsCompanion(')
          ..write('stepId: $stepId, ')
          ..write('shape: $shape, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('w: $w, ')
          ..write('h: $h, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $GuidesTable guides = $GuidesTable(this);
  late final $StepsTable steps = $StepsTable(this);
  late final $StepHighlightsTable stepHighlights = $StepHighlightsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    devices,
    guides,
    steps,
    stepHighlights,
  ];
}

typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> coverPhotoPath,
      Value<DateTime> createdAt,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> coverPhotoPath,
      Value<DateTime> createdAt,
    });

final class $$DevicesTableReferences
    extends BaseReferences<_$AppDatabase, $DevicesTable, Device> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GuidesTable, List<Guide>> _guidesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.guides,
    aliasName: $_aliasNameGenerator(db.devices.id, db.guides.deviceId),
  );

  $$GuidesTableProcessedTableManager get guidesRefs {
    final manager = $$GuidesTableTableManager(
      $_db,
      $_db.guides,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_guidesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPhotoPath => $composableBuilder(
    column: $table.coverPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> guidesRefs(
    Expression<bool> Function($$GuidesTableFilterComposer f) f,
  ) {
    final $$GuidesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.guides,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GuidesTableFilterComposer(
            $db: $db,
            $table: $db.guides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPhotoPath => $composableBuilder(
    column: $table.coverPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
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

  GeneratedColumn<String> get coverPhotoPath => $composableBuilder(
    column: $table.coverPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> guidesRefs<T extends Object>(
    Expression<T> Function($$GuidesTableAnnotationComposer a) f,
  ) {
    final $$GuidesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.guides,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GuidesTableAnnotationComposer(
            $db: $db,
            $table: $db.guides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          Device,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (Device, $$DevicesTableReferences),
          Device,
          PrefetchHooks Function({bool guidesRefs})
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> coverPhotoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                name: name,
                coverPhotoPath: coverPhotoPath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> coverPhotoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                name: name,
                coverPhotoPath: coverPhotoPath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({guidesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (guidesRefs) db.guides],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (guidesRefs)
                    await $_getPrefetchedData<Device, $DevicesTable, Guide>(
                      currentTable: table,
                      referencedTable: $$DevicesTableReferences
                          ._guidesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DevicesTableReferences(db, table, p0).guidesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.deviceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      Device,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (Device, $$DevicesTableReferences),
      Device,
      PrefetchHooks Function({bool guidesRefs})
    >;
typedef $$GuidesTableCreateCompanionBuilder =
    GuidesCompanion Function({
      Value<int> id,
      required int deviceId,
      required String title,
      Value<DateTime> createdAt,
    });
typedef $$GuidesTableUpdateCompanionBuilder =
    GuidesCompanion Function({
      Value<int> id,
      Value<int> deviceId,
      Value<String> title,
      Value<DateTime> createdAt,
    });

final class $$GuidesTableReferences
    extends BaseReferences<_$AppDatabase, $GuidesTable, Guide> {
  $$GuidesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _deviceIdTable(_$AppDatabase db) => db.devices
      .createAlias($_aliasNameGenerator(db.guides.deviceId, db.devices.id));

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<int>('device_id')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StepsTable, List<Step>> _stepsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.steps,
    aliasName: $_aliasNameGenerator(db.guides.id, db.steps.guideId),
  );

  $$StepsTableProcessedTableManager get stepsRefs {
    final manager = $$StepsTableTableManager(
      $_db,
      $_db.steps,
    ).filter((f) => f.guideId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GuidesTableFilterComposer
    extends Composer<_$AppDatabase, $GuidesTable> {
  $$GuidesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> stepsRefs(
    Expression<bool> Function($$StepsTableFilterComposer f) f,
  ) {
    final $$StepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.steps,
      getReferencedColumn: (t) => t.guideId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepsTableFilterComposer(
            $db: $db,
            $table: $db.steps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GuidesTableOrderingComposer
    extends Composer<_$AppDatabase, $GuidesTable> {
  $$GuidesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GuidesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuidesTable> {
  $$GuidesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> stepsRefs<T extends Object>(
    Expression<T> Function($$StepsTableAnnotationComposer a) f,
  ) {
    final $$StepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.steps,
      getReferencedColumn: (t) => t.guideId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepsTableAnnotationComposer(
            $db: $db,
            $table: $db.steps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GuidesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GuidesTable,
          Guide,
          $$GuidesTableFilterComposer,
          $$GuidesTableOrderingComposer,
          $$GuidesTableAnnotationComposer,
          $$GuidesTableCreateCompanionBuilder,
          $$GuidesTableUpdateCompanionBuilder,
          (Guide, $$GuidesTableReferences),
          Guide,
          PrefetchHooks Function({bool deviceId, bool stepsRefs})
        > {
  $$GuidesTableTableManager(_$AppDatabase db, $GuidesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuidesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuidesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuidesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> deviceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GuidesCompanion(
                id: id,
                deviceId: deviceId,
                title: title,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int deviceId,
                required String title,
                Value<DateTime> createdAt = const Value.absent(),
              }) => GuidesCompanion.insert(
                id: id,
                deviceId: deviceId,
                title: title,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GuidesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({deviceId = false, stepsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (stepsRefs) db.steps],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deviceId,
                                referencedTable: $$GuidesTableReferences
                                    ._deviceIdTable(db),
                                referencedColumn: $$GuidesTableReferences
                                    ._deviceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stepsRefs)
                    await $_getPrefetchedData<Guide, $GuidesTable, Step>(
                      currentTable: table,
                      referencedTable: $$GuidesTableReferences._stepsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$GuidesTableReferences(db, table, p0).stepsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.guideId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GuidesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GuidesTable,
      Guide,
      $$GuidesTableFilterComposer,
      $$GuidesTableOrderingComposer,
      $$GuidesTableAnnotationComposer,
      $$GuidesTableCreateCompanionBuilder,
      $$GuidesTableUpdateCompanionBuilder,
      (Guide, $$GuidesTableReferences),
      Guide,
      PrefetchHooks Function({bool deviceId, bool stepsRefs})
    >;
typedef $$StepsTableCreateCompanionBuilder =
    StepsCompanion Function({
      Value<int> id,
      required int guideId,
      required int stepIndex,
      required String instructionText,
      Value<String?> photoPath,
      Value<DateTime> createdAt,
    });
typedef $$StepsTableUpdateCompanionBuilder =
    StepsCompanion Function({
      Value<int> id,
      Value<int> guideId,
      Value<int> stepIndex,
      Value<String> instructionText,
      Value<String?> photoPath,
      Value<DateTime> createdAt,
    });

final class $$StepsTableReferences
    extends BaseReferences<_$AppDatabase, $StepsTable, Step> {
  $$StepsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GuidesTable _guideIdTable(_$AppDatabase db) => db.guides.createAlias(
    $_aliasNameGenerator(db.steps.guideId, db.guides.id),
  );

  $$GuidesTableProcessedTableManager get guideId {
    final $_column = $_itemColumn<int>('guide_id')!;

    final manager = $$GuidesTableTableManager(
      $_db,
      $_db.guides,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_guideIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StepHighlightsTable, List<StepHighlight>>
  _stepHighlightsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stepHighlights,
    aliasName: $_aliasNameGenerator(db.steps.id, db.stepHighlights.stepId),
  );

  $$StepHighlightsTableProcessedTableManager get stepHighlightsRefs {
    final manager = $$StepHighlightsTableTableManager(
      $_db,
      $_db.stepHighlights,
    ).filter((f) => f.stepId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stepHighlightsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StepsTableFilterComposer extends Composer<_$AppDatabase, $StepsTable> {
  $$StepsTableFilterComposer({
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

  ColumnFilters<int> get stepIndex => $composableBuilder(
    column: $table.stepIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructionText => $composableBuilder(
    column: $table.instructionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GuidesTableFilterComposer get guideId {
    final $$GuidesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.guideId,
      referencedTable: $db.guides,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GuidesTableFilterComposer(
            $db: $db,
            $table: $db.guides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> stepHighlightsRefs(
    Expression<bool> Function($$StepHighlightsTableFilterComposer f) f,
  ) {
    final $$StepHighlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stepHighlights,
      getReferencedColumn: (t) => t.stepId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepHighlightsTableFilterComposer(
            $db: $db,
            $table: $db.stepHighlights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StepsTableOrderingComposer
    extends Composer<_$AppDatabase, $StepsTable> {
  $$StepsTableOrderingComposer({
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

  ColumnOrderings<int> get stepIndex => $composableBuilder(
    column: $table.stepIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructionText => $composableBuilder(
    column: $table.instructionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GuidesTableOrderingComposer get guideId {
    final $$GuidesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.guideId,
      referencedTable: $db.guides,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GuidesTableOrderingComposer(
            $db: $db,
            $table: $db.guides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StepsTable> {
  $$StepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get stepIndex =>
      $composableBuilder(column: $table.stepIndex, builder: (column) => column);

  GeneratedColumn<String> get instructionText => $composableBuilder(
    column: $table.instructionText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GuidesTableAnnotationComposer get guideId {
    final $$GuidesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.guideId,
      referencedTable: $db.guides,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GuidesTableAnnotationComposer(
            $db: $db,
            $table: $db.guides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> stepHighlightsRefs<T extends Object>(
    Expression<T> Function($$StepHighlightsTableAnnotationComposer a) f,
  ) {
    final $$StepHighlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stepHighlights,
      getReferencedColumn: (t) => t.stepId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepHighlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.stepHighlights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StepsTable,
          Step,
          $$StepsTableFilterComposer,
          $$StepsTableOrderingComposer,
          $$StepsTableAnnotationComposer,
          $$StepsTableCreateCompanionBuilder,
          $$StepsTableUpdateCompanionBuilder,
          (Step, $$StepsTableReferences),
          Step,
          PrefetchHooks Function({bool guideId, bool stepHighlightsRefs})
        > {
  $$StepsTableTableManager(_$AppDatabase db, $StepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> guideId = const Value.absent(),
                Value<int> stepIndex = const Value.absent(),
                Value<String> instructionText = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StepsCompanion(
                id: id,
                guideId: guideId,
                stepIndex: stepIndex,
                instructionText: instructionText,
                photoPath: photoPath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int guideId,
                required int stepIndex,
                required String instructionText,
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StepsCompanion.insert(
                id: id,
                guideId: guideId,
                stepIndex: stepIndex,
                instructionText: instructionText,
                photoPath: photoPath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$StepsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({guideId = false, stepHighlightsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stepHighlightsRefs) db.stepHighlights,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (guideId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.guideId,
                                    referencedTable: $$StepsTableReferences
                                        ._guideIdTable(db),
                                    referencedColumn: $$StepsTableReferences
                                        ._guideIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stepHighlightsRefs)
                        await $_getPrefetchedData<
                          Step,
                          $StepsTable,
                          StepHighlight
                        >(
                          currentTable: table,
                          referencedTable: $$StepsTableReferences
                              ._stepHighlightsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StepsTableReferences(
                                db,
                                table,
                                p0,
                              ).stepHighlightsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.stepId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StepsTable,
      Step,
      $$StepsTableFilterComposer,
      $$StepsTableOrderingComposer,
      $$StepsTableAnnotationComposer,
      $$StepsTableCreateCompanionBuilder,
      $$StepsTableUpdateCompanionBuilder,
      (Step, $$StepsTableReferences),
      Step,
      PrefetchHooks Function({bool guideId, bool stepHighlightsRefs})
    >;
typedef $$StepHighlightsTableCreateCompanionBuilder =
    StepHighlightsCompanion Function({
      Value<int> stepId,
      Value<int> shape,
      required double x,
      required double y,
      required double w,
      required double h,
      Value<DateTime> updatedAt,
    });
typedef $$StepHighlightsTableUpdateCompanionBuilder =
    StepHighlightsCompanion Function({
      Value<int> stepId,
      Value<int> shape,
      Value<double> x,
      Value<double> y,
      Value<double> w,
      Value<double> h,
      Value<DateTime> updatedAt,
    });

final class $$StepHighlightsTableReferences
    extends BaseReferences<_$AppDatabase, $StepHighlightsTable, StepHighlight> {
  $$StepHighlightsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StepsTable _stepIdTable(_$AppDatabase db) => db.steps.createAlias(
    $_aliasNameGenerator(db.stepHighlights.stepId, db.steps.id),
  );

  $$StepsTableProcessedTableManager get stepId {
    final $_column = $_itemColumn<int>('step_id')!;

    final manager = $$StepsTableTableManager(
      $_db,
      $_db.steps,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stepIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StepHighlightsTableFilterComposer
    extends Composer<_$AppDatabase, $StepHighlightsTable> {
  $$StepHighlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get shape => $composableBuilder(
    column: $table.shape,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get w => $composableBuilder(
    column: $table.w,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get h => $composableBuilder(
    column: $table.h,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StepsTableFilterComposer get stepId {
    final $$StepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stepId,
      referencedTable: $db.steps,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepsTableFilterComposer(
            $db: $db,
            $table: $db.steps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepHighlightsTableOrderingComposer
    extends Composer<_$AppDatabase, $StepHighlightsTable> {
  $$StepHighlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get shape => $composableBuilder(
    column: $table.shape,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get w => $composableBuilder(
    column: $table.w,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get h => $composableBuilder(
    column: $table.h,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StepsTableOrderingComposer get stepId {
    final $$StepsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stepId,
      referencedTable: $db.steps,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepsTableOrderingComposer(
            $db: $db,
            $table: $db.steps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepHighlightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StepHighlightsTable> {
  $$StepHighlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get shape =>
      $composableBuilder(column: $table.shape, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get w =>
      $composableBuilder(column: $table.w, builder: (column) => column);

  GeneratedColumn<double> get h =>
      $composableBuilder(column: $table.h, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StepsTableAnnotationComposer get stepId {
    final $$StepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stepId,
      referencedTable: $db.steps,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepsTableAnnotationComposer(
            $db: $db,
            $table: $db.steps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepHighlightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StepHighlightsTable,
          StepHighlight,
          $$StepHighlightsTableFilterComposer,
          $$StepHighlightsTableOrderingComposer,
          $$StepHighlightsTableAnnotationComposer,
          $$StepHighlightsTableCreateCompanionBuilder,
          $$StepHighlightsTableUpdateCompanionBuilder,
          (StepHighlight, $$StepHighlightsTableReferences),
          StepHighlight,
          PrefetchHooks Function({bool stepId})
        > {
  $$StepHighlightsTableTableManager(
    _$AppDatabase db,
    $StepHighlightsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepHighlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepHighlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepHighlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> stepId = const Value.absent(),
                Value<int> shape = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> w = const Value.absent(),
                Value<double> h = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StepHighlightsCompanion(
                stepId: stepId,
                shape: shape,
                x: x,
                y: y,
                w: w,
                h: h,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> stepId = const Value.absent(),
                Value<int> shape = const Value.absent(),
                required double x,
                required double y,
                required double w,
                required double h,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StepHighlightsCompanion.insert(
                stepId: stepId,
                shape: shape,
                x: x,
                y: y,
                w: w,
                h: h,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StepHighlightsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stepId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (stepId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.stepId,
                                referencedTable: $$StepHighlightsTableReferences
                                    ._stepIdTable(db),
                                referencedColumn:
                                    $$StepHighlightsTableReferences
                                        ._stepIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StepHighlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StepHighlightsTable,
      StepHighlight,
      $$StepHighlightsTableFilterComposer,
      $$StepHighlightsTableOrderingComposer,
      $$StepHighlightsTableAnnotationComposer,
      $$StepHighlightsTableCreateCompanionBuilder,
      $$StepHighlightsTableUpdateCompanionBuilder,
      (StepHighlight, $$StepHighlightsTableReferences),
      StepHighlight,
      PrefetchHooks Function({bool stepId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$GuidesTableTableManager get guides =>
      $$GuidesTableTableManager(_db, _db.guides);
  $$StepsTableTableManager get steps =>
      $$StepsTableTableManager(_db, _db.steps);
  $$StepHighlightsTableTableManager get stepHighlights =>
      $$StepHighlightsTableTableManager(_db, _db.stepHighlights);
}
