// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_database.dart';

// ignore_for_file: type=lint
class Profile extends Table with TableInfo<Profile, ProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Profile(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonMeta = const VerificationMeta(
    'singleton',
  );
  late final GeneratedColumn<int> singleton = GeneratedColumn<int>(
    'singleton',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (singleton = 1)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  late final GeneratedColumn<String> dateOfBirth = GeneratedColumn<String>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [singleton, name, dateOfBirth];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton')) {
      context.handle(
        _singletonMeta,
        singleton.isAcceptableOrUnknown(data['singleton']!, _singletonMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singleton};
  @override
  ProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileData(
      singleton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_of_birth'],
      ),
    );
  }

  @override
  Profile createAlias(String alias) {
    return Profile(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ProfileData extends DataClass implements Insertable<ProfileData> {
  final int singleton;
  final String? name;
  final String? dateOfBirth;
  const ProfileData({required this.singleton, this.name, this.dateOfBirth});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton'] = Variable<int>(singleton);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<String>(dateOfBirth);
    }
    return map;
  }

  ProfileCompanion toCompanion(bool nullToAbsent) {
    return ProfileCompanion(
      singleton: Value(singleton),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
    );
  }

  factory ProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileData(
      singleton: serializer.fromJson<int>(json['singleton']),
      name: serializer.fromJson<String?>(json['name']),
      dateOfBirth: serializer.fromJson<String?>(json['date_of_birth']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singleton': serializer.toJson<int>(singleton),
      'name': serializer.toJson<String?>(name),
      'date_of_birth': serializer.toJson<String?>(dateOfBirth),
    };
  }

  ProfileData copyWith({
    int? singleton,
    Value<String?> name = const Value.absent(),
    Value<String?> dateOfBirth = const Value.absent(),
  }) => ProfileData(
    singleton: singleton ?? this.singleton,
    name: name.present ? name.value : this.name,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
  );
  ProfileData copyWithCompanion(ProfileCompanion data) {
    return ProfileData(
      singleton: data.singleton.present ? data.singleton.value : this.singleton,
      name: data.name.present ? data.name.value : this.name,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileData(')
          ..write('singleton: $singleton, ')
          ..write('name: $name, ')
          ..write('dateOfBirth: $dateOfBirth')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(singleton, name, dateOfBirth);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileData &&
          other.singleton == this.singleton &&
          other.name == this.name &&
          other.dateOfBirth == this.dateOfBirth);
}

class ProfileCompanion extends UpdateCompanion<ProfileData> {
  final Value<int> singleton;
  final Value<String?> name;
  final Value<String?> dateOfBirth;
  const ProfileCompanion({
    this.singleton = const Value.absent(),
    this.name = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
  });
  ProfileCompanion.insert({
    this.singleton = const Value.absent(),
    this.name = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
  });
  static Insertable<ProfileData> custom({
    Expression<int>? singleton,
    Expression<String>? name,
    Expression<String>? dateOfBirth,
  }) {
    return RawValuesInsertable({
      if (singleton != null) 'singleton': singleton,
      if (name != null) 'name': name,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
    });
  }

  ProfileCompanion copyWith({
    Value<int>? singleton,
    Value<String?>? name,
    Value<String?>? dateOfBirth,
  }) {
    return ProfileCompanion(
      singleton: singleton ?? this.singleton,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singleton.present) {
      map['singleton'] = Variable<int>(singleton.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(dateOfBirth.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileCompanion(')
          ..write('singleton: $singleton, ')
          ..write('name: $name, ')
          ..write('dateOfBirth: $dateOfBirth')
          ..write(')'))
        .toString();
  }
}

class Medications extends Table with TableInfo<Medications, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Medications(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) > 0)',
  );
  static const VerificationMeta _strengthMeta = const VerificationMeta(
    'strength',
  );
  late final GeneratedColumn<String> strength = GeneratedColumn<String>(
    'strength',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  late final GeneratedColumn<int> archived = GeneratedColumn<int>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (archived IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    strength,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Medication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('strength')) {
      context.handle(
        _strengthMeta,
        strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta),
      );
    } else if (isInserting) {
      context.missing(_strengthMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      strength: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strength'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  Medications createAlias(String alias) {
    return Medications(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Medication extends DataClass implements Insertable<Medication> {
  final String id;
  final String name;
  final String strength;
  final int archived;
  final int createdAt;
  final int updatedAt;
  const Medication({
    required this.id,
    required this.name,
    required this.strength,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['strength'] = Variable<String>(strength);
    map['archived'] = Variable<int>(archived);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      name: Value(name),
      strength: Value(strength),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Medication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      strength: serializer.fromJson<String>(json['strength']),
      archived: serializer.fromJson<int>(json['archived']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'strength': serializer.toJson<String>(strength),
      'archived': serializer.toJson<int>(archived),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
    };
  }

  Medication copyWith({
    String? id,
    String? name,
    String? strength,
    int? archived,
    int? createdAt,
    int? updatedAt,
  }) => Medication(
    id: id ?? this.id,
    name: name ?? this.name,
    strength: strength ?? this.strength,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      strength: data.strength.present ? data.strength.value : this.strength,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('strength: $strength, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, strength, archived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.name == this.name &&
          other.strength == this.strength &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> strength;
  final Value<int> archived;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.strength = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String name,
    required String strength,
    this.archived = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       strength = Value(strength),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Medication> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? strength,
    Expression<int>? archived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (strength != null) 'strength': strength,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? strength,
    Value<int>? archived,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (strength.present) {
      map['strength'] = Variable<String>(strength.value);
    }
    if (archived.present) {
      map['archived'] = Variable<int>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('strength: $strength, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MedicationRegimens extends Table
    with TableInfo<MedicationRegimens, MedicationRegimen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MedicationRegimens(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES medications(id)',
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount > 0)',
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(unit)) > 0)',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (kind IN (\'fixed\', \'prn\', \'course\'))',
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  late final GeneratedColumn<int> effectiveFrom = GeneratedColumn<int>(
    'effective_from',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _effectiveToMeta = const VerificationMeta(
    'effectiveTo',
  );
  late final GeneratedColumn<int> effectiveTo = GeneratedColumn<int>(
    'effective_to',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (effective_to >= effective_from)',
  );
  static const VerificationMeta _instructionsSnapshotMeta =
      const VerificationMeta('instructionsSnapshot');
  late final GeneratedColumn<String> instructionsSnapshot =
      GeneratedColumn<String>(
        'instructions_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    amount,
    unit,
    kind,
    effectiveFrom,
    effectiveTo,
    instructionsSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_regimens';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationRegimen> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveFromMeta);
    }
    if (data.containsKey('effective_to')) {
      context.handle(
        _effectiveToMeta,
        effectiveTo.isAcceptableOrUnknown(
          data['effective_to']!,
          _effectiveToMeta,
        ),
      );
    }
    if (data.containsKey('instructions_snapshot')) {
      context.handle(
        _instructionsSnapshotMeta,
        instructionsSnapshot.isAcceptableOrUnknown(
          data['instructions_snapshot']!,
          _instructionsSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instructionsSnapshotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationRegimen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationRegimen(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effective_from'],
      )!,
      effectiveTo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effective_to'],
      ),
      instructionsSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions_snapshot'],
      )!,
    );
  }

  @override
  MedicationRegimens createAlias(String alias) {
    return MedicationRegimens(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class MedicationRegimen extends DataClass
    implements Insertable<MedicationRegimen> {
  final String id;
  final String medicationId;
  final double amount;
  final String unit;
  final String kind;
  final int effectiveFrom;
  final int? effectiveTo;
  final String instructionsSnapshot;
  const MedicationRegimen({
    required this.id,
    required this.medicationId,
    required this.amount,
    required this.unit,
    required this.kind,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.instructionsSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['amount'] = Variable<double>(amount);
    map['unit'] = Variable<String>(unit);
    map['kind'] = Variable<String>(kind);
    map['effective_from'] = Variable<int>(effectiveFrom);
    if (!nullToAbsent || effectiveTo != null) {
      map['effective_to'] = Variable<int>(effectiveTo);
    }
    map['instructions_snapshot'] = Variable<String>(instructionsSnapshot);
    return map;
  }

  MedicationRegimensCompanion toCompanion(bool nullToAbsent) {
    return MedicationRegimensCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      amount: Value(amount),
      unit: Value(unit),
      kind: Value(kind),
      effectiveFrom: Value(effectiveFrom),
      effectiveTo: effectiveTo == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveTo),
      instructionsSnapshot: Value(instructionsSnapshot),
    );
  }

  factory MedicationRegimen.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationRegimen(
      id: serializer.fromJson<String>(json['id']),
      medicationId: serializer.fromJson<String>(json['medication_id']),
      amount: serializer.fromJson<double>(json['amount']),
      unit: serializer.fromJson<String>(json['unit']),
      kind: serializer.fromJson<String>(json['kind']),
      effectiveFrom: serializer.fromJson<int>(json['effective_from']),
      effectiveTo: serializer.fromJson<int?>(json['effective_to']),
      instructionsSnapshot: serializer.fromJson<String>(
        json['instructions_snapshot'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medication_id': serializer.toJson<String>(medicationId),
      'amount': serializer.toJson<double>(amount),
      'unit': serializer.toJson<String>(unit),
      'kind': serializer.toJson<String>(kind),
      'effective_from': serializer.toJson<int>(effectiveFrom),
      'effective_to': serializer.toJson<int?>(effectiveTo),
      'instructions_snapshot': serializer.toJson<String>(instructionsSnapshot),
    };
  }

  MedicationRegimen copyWith({
    String? id,
    String? medicationId,
    double? amount,
    String? unit,
    String? kind,
    int? effectiveFrom,
    Value<int?> effectiveTo = const Value.absent(),
    String? instructionsSnapshot,
  }) => MedicationRegimen(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    kind: kind ?? this.kind,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    effectiveTo: effectiveTo.present ? effectiveTo.value : this.effectiveTo,
    instructionsSnapshot: instructionsSnapshot ?? this.instructionsSnapshot,
  );
  MedicationRegimen copyWithCompanion(MedicationRegimensCompanion data) {
    return MedicationRegimen(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      kind: data.kind.present ? data.kind.value : this.kind,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      effectiveTo: data.effectiveTo.present
          ? data.effectiveTo.value
          : this.effectiveTo,
      instructionsSnapshot: data.instructionsSnapshot.present
          ? data.instructionsSnapshot.value
          : this.instructionsSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRegimen(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('kind: $kind, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveTo: $effectiveTo, ')
          ..write('instructionsSnapshot: $instructionsSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    amount,
    unit,
    kind,
    effectiveFrom,
    effectiveTo,
    instructionsSnapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationRegimen &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.kind == this.kind &&
          other.effectiveFrom == this.effectiveFrom &&
          other.effectiveTo == this.effectiveTo &&
          other.instructionsSnapshot == this.instructionsSnapshot);
}

class MedicationRegimensCompanion extends UpdateCompanion<MedicationRegimen> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<double> amount;
  final Value<String> unit;
  final Value<String> kind;
  final Value<int> effectiveFrom;
  final Value<int?> effectiveTo;
  final Value<String> instructionsSnapshot;
  final Value<int> rowid;
  const MedicationRegimensCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.kind = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.effectiveTo = const Value.absent(),
    this.instructionsSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationRegimensCompanion.insert({
    required String id,
    required String medicationId,
    required double amount,
    required String unit,
    required String kind,
    required int effectiveFrom,
    this.effectiveTo = const Value.absent(),
    required String instructionsSnapshot,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicationId = Value(medicationId),
       amount = Value(amount),
       unit = Value(unit),
       kind = Value(kind),
       effectiveFrom = Value(effectiveFrom),
       instructionsSnapshot = Value(instructionsSnapshot);
  static Insertable<MedicationRegimen> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<String>? kind,
    Expression<int>? effectiveFrom,
    Expression<int>? effectiveTo,
    Expression<String>? instructionsSnapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (kind != null) 'kind': kind,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (effectiveTo != null) 'effective_to': effectiveTo,
      if (instructionsSnapshot != null)
        'instructions_snapshot': instructionsSnapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationRegimensCompanion copyWith({
    Value<String>? id,
    Value<String>? medicationId,
    Value<double>? amount,
    Value<String>? unit,
    Value<String>? kind,
    Value<int>? effectiveFrom,
    Value<int?>? effectiveTo,
    Value<String>? instructionsSnapshot,
    Value<int>? rowid,
  }) {
    return MedicationRegimensCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      kind: kind ?? this.kind,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      instructionsSnapshot: instructionsSnapshot ?? this.instructionsSnapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<int>(effectiveFrom.value);
    }
    if (effectiveTo.present) {
      map['effective_to'] = Variable<int>(effectiveTo.value);
    }
    if (instructionsSnapshot.present) {
      map['instructions_snapshot'] = Variable<String>(
        instructionsSnapshot.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRegimensCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('kind: $kind, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveTo: $effectiveTo, ')
          ..write('instructionsSnapshot: $instructionsSnapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MedicationEvents extends Table
    with TableInfo<MedicationEvents, MedicationEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MedicationEvents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _regimenIdMeta = const VerificationMeta(
    'regimenId',
  );
  late final GeneratedColumn<String> regimenId = GeneratedColumn<String>(
    'regimen_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES medication_regimens(id)',
  );
  static const VerificationMeta _occurrenceKeyMeta = const VerificationMeta(
    'occurrenceKey',
  );
  late final GeneratedColumn<String> occurrenceKey = GeneratedColumn<String>(
    'occurrence_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'taken\', \'skipped\', \'missed\', \'unknown\'))',
  );
  static const VerificationMeta _intendedAtMeta = const VerificationMeta(
    'intendedAt',
  );
  late final GeneratedColumn<int> intendedAt = GeneratedColumn<int>(
    'intended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  late final GeneratedColumn<int> takenAt = GeneratedColumn<int>(
    'taken_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  late final GeneratedColumn<int> recordedAt = GeneratedColumn<int>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount > 0)',
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(unit)) > 0)',
  );
  static const VerificationMeta _medicationSnapshotMeta =
      const VerificationMeta('medicationSnapshot');
  late final GeneratedColumn<String> medicationSnapshot =
      GeneratedColumn<String>(
        'medication_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    regimenId,
    occurrenceKey,
    status,
    intendedAt,
    takenAt,
    recordedAt,
    amount,
    unit,
    medicationSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('regimen_id')) {
      context.handle(
        _regimenIdMeta,
        regimenId.isAcceptableOrUnknown(data['regimen_id']!, _regimenIdMeta),
      );
    } else if (isInserting) {
      context.missing(_regimenIdMeta);
    }
    if (data.containsKey('occurrence_key')) {
      context.handle(
        _occurrenceKeyMeta,
        occurrenceKey.isAcceptableOrUnknown(
          data['occurrence_key']!,
          _occurrenceKeyMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('intended_at')) {
      context.handle(
        _intendedAtMeta,
        intendedAt.isAcceptableOrUnknown(data['intended_at']!, _intendedAtMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('medication_snapshot')) {
      context.handle(
        _medicationSnapshotMeta,
        medicationSnapshot.isAcceptableOrUnknown(
          data['medication_snapshot']!,
          _medicationSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationSnapshotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      regimenId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regimen_id'],
      )!,
      occurrenceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_key'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      intendedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intended_at'],
      ),
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taken_at'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      medicationSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_snapshot'],
      )!,
    );
  }

  @override
  MedicationEvents createAlias(String alias) {
    return MedicationEvents(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((status = \'taken\' AND taken_at IS NOT NULL)OR(status != \'taken\' AND taken_at IS NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class MedicationEvent extends DataClass implements Insertable<MedicationEvent> {
  final String id;
  final String regimenId;
  final String? occurrenceKey;
  final String status;
  final int? intendedAt;
  final int? takenAt;
  final int recordedAt;
  final double amount;
  final String unit;
  final String medicationSnapshot;
  const MedicationEvent({
    required this.id,
    required this.regimenId,
    this.occurrenceKey,
    required this.status,
    this.intendedAt,
    this.takenAt,
    required this.recordedAt,
    required this.amount,
    required this.unit,
    required this.medicationSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['regimen_id'] = Variable<String>(regimenId);
    if (!nullToAbsent || occurrenceKey != null) {
      map['occurrence_key'] = Variable<String>(occurrenceKey);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || intendedAt != null) {
      map['intended_at'] = Variable<int>(intendedAt);
    }
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<int>(takenAt);
    }
    map['recorded_at'] = Variable<int>(recordedAt);
    map['amount'] = Variable<double>(amount);
    map['unit'] = Variable<String>(unit);
    map['medication_snapshot'] = Variable<String>(medicationSnapshot);
    return map;
  }

  MedicationEventsCompanion toCompanion(bool nullToAbsent) {
    return MedicationEventsCompanion(
      id: Value(id),
      regimenId: Value(regimenId),
      occurrenceKey: occurrenceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceKey),
      status: Value(status),
      intendedAt: intendedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(intendedAt),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      recordedAt: Value(recordedAt),
      amount: Value(amount),
      unit: Value(unit),
      medicationSnapshot: Value(medicationSnapshot),
    );
  }

  factory MedicationEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationEvent(
      id: serializer.fromJson<String>(json['id']),
      regimenId: serializer.fromJson<String>(json['regimen_id']),
      occurrenceKey: serializer.fromJson<String?>(json['occurrence_key']),
      status: serializer.fromJson<String>(json['status']),
      intendedAt: serializer.fromJson<int?>(json['intended_at']),
      takenAt: serializer.fromJson<int?>(json['taken_at']),
      recordedAt: serializer.fromJson<int>(json['recorded_at']),
      amount: serializer.fromJson<double>(json['amount']),
      unit: serializer.fromJson<String>(json['unit']),
      medicationSnapshot: serializer.fromJson<String>(
        json['medication_snapshot'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'regimen_id': serializer.toJson<String>(regimenId),
      'occurrence_key': serializer.toJson<String?>(occurrenceKey),
      'status': serializer.toJson<String>(status),
      'intended_at': serializer.toJson<int?>(intendedAt),
      'taken_at': serializer.toJson<int?>(takenAt),
      'recorded_at': serializer.toJson<int>(recordedAt),
      'amount': serializer.toJson<double>(amount),
      'unit': serializer.toJson<String>(unit),
      'medication_snapshot': serializer.toJson<String>(medicationSnapshot),
    };
  }

  MedicationEvent copyWith({
    String? id,
    String? regimenId,
    Value<String?> occurrenceKey = const Value.absent(),
    String? status,
    Value<int?> intendedAt = const Value.absent(),
    Value<int?> takenAt = const Value.absent(),
    int? recordedAt,
    double? amount,
    String? unit,
    String? medicationSnapshot,
  }) => MedicationEvent(
    id: id ?? this.id,
    regimenId: regimenId ?? this.regimenId,
    occurrenceKey: occurrenceKey.present
        ? occurrenceKey.value
        : this.occurrenceKey,
    status: status ?? this.status,
    intendedAt: intendedAt.present ? intendedAt.value : this.intendedAt,
    takenAt: takenAt.present ? takenAt.value : this.takenAt,
    recordedAt: recordedAt ?? this.recordedAt,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    medicationSnapshot: medicationSnapshot ?? this.medicationSnapshot,
  );
  MedicationEvent copyWithCompanion(MedicationEventsCompanion data) {
    return MedicationEvent(
      id: data.id.present ? data.id.value : this.id,
      regimenId: data.regimenId.present ? data.regimenId.value : this.regimenId,
      occurrenceKey: data.occurrenceKey.present
          ? data.occurrenceKey.value
          : this.occurrenceKey,
      status: data.status.present ? data.status.value : this.status,
      intendedAt: data.intendedAt.present
          ? data.intendedAt.value
          : this.intendedAt,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      medicationSnapshot: data.medicationSnapshot.present
          ? data.medicationSnapshot.value
          : this.medicationSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationEvent(')
          ..write('id: $id, ')
          ..write('regimenId: $regimenId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('status: $status, ')
          ..write('intendedAt: $intendedAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('medicationSnapshot: $medicationSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    regimenId,
    occurrenceKey,
    status,
    intendedAt,
    takenAt,
    recordedAt,
    amount,
    unit,
    medicationSnapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationEvent &&
          other.id == this.id &&
          other.regimenId == this.regimenId &&
          other.occurrenceKey == this.occurrenceKey &&
          other.status == this.status &&
          other.intendedAt == this.intendedAt &&
          other.takenAt == this.takenAt &&
          other.recordedAt == this.recordedAt &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.medicationSnapshot == this.medicationSnapshot);
}

class MedicationEventsCompanion extends UpdateCompanion<MedicationEvent> {
  final Value<String> id;
  final Value<String> regimenId;
  final Value<String?> occurrenceKey;
  final Value<String> status;
  final Value<int?> intendedAt;
  final Value<int?> takenAt;
  final Value<int> recordedAt;
  final Value<double> amount;
  final Value<String> unit;
  final Value<String> medicationSnapshot;
  final Value<int> rowid;
  const MedicationEventsCompanion({
    this.id = const Value.absent(),
    this.regimenId = const Value.absent(),
    this.occurrenceKey = const Value.absent(),
    this.status = const Value.absent(),
    this.intendedAt = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.medicationSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationEventsCompanion.insert({
    required String id,
    required String regimenId,
    this.occurrenceKey = const Value.absent(),
    required String status,
    this.intendedAt = const Value.absent(),
    this.takenAt = const Value.absent(),
    required int recordedAt,
    required double amount,
    required String unit,
    required String medicationSnapshot,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       regimenId = Value(regimenId),
       status = Value(status),
       recordedAt = Value(recordedAt),
       amount = Value(amount),
       unit = Value(unit),
       medicationSnapshot = Value(medicationSnapshot);
  static Insertable<MedicationEvent> custom({
    Expression<String>? id,
    Expression<String>? regimenId,
    Expression<String>? occurrenceKey,
    Expression<String>? status,
    Expression<int>? intendedAt,
    Expression<int>? takenAt,
    Expression<int>? recordedAt,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<String>? medicationSnapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (regimenId != null) 'regimen_id': regimenId,
      if (occurrenceKey != null) 'occurrence_key': occurrenceKey,
      if (status != null) 'status': status,
      if (intendedAt != null) 'intended_at': intendedAt,
      if (takenAt != null) 'taken_at': takenAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (medicationSnapshot != null) 'medication_snapshot': medicationSnapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? regimenId,
    Value<String?>? occurrenceKey,
    Value<String>? status,
    Value<int?>? intendedAt,
    Value<int?>? takenAt,
    Value<int>? recordedAt,
    Value<double>? amount,
    Value<String>? unit,
    Value<String>? medicationSnapshot,
    Value<int>? rowid,
  }) {
    return MedicationEventsCompanion(
      id: id ?? this.id,
      regimenId: regimenId ?? this.regimenId,
      occurrenceKey: occurrenceKey ?? this.occurrenceKey,
      status: status ?? this.status,
      intendedAt: intendedAt ?? this.intendedAt,
      takenAt: takenAt ?? this.takenAt,
      recordedAt: recordedAt ?? this.recordedAt,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      medicationSnapshot: medicationSnapshot ?? this.medicationSnapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (regimenId.present) {
      map['regimen_id'] = Variable<String>(regimenId.value);
    }
    if (occurrenceKey.present) {
      map['occurrence_key'] = Variable<String>(occurrenceKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (intendedAt.present) {
      map['intended_at'] = Variable<int>(intendedAt.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<int>(takenAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<int>(recordedAt.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (medicationSnapshot.present) {
      map['medication_snapshot'] = Variable<String>(medicationSnapshot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationEventsCompanion(')
          ..write('id: $id, ')
          ..write('regimenId: $regimenId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('status: $status, ')
          ..write('intendedAt: $intendedAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('medicationSnapshot: $medicationSnapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SymptomEntries extends Table
    with TableInfo<SymptomEntries, SymptomEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SymptomEntries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(title)) > 0)',
  );
  static const VerificationMeta _onsetAtMeta = const VerificationMeta(
    'onsetAt',
  );
  late final GeneratedColumn<int> onsetAt = GeneratedColumn<int>(
    'onset_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  late final GeneratedColumn<int> endAt = GeneratedColumn<int>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (end_at >= onset_at)',
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  late final GeneratedColumn<int> recordedAt = GeneratedColumn<int>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
    'severity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (severity BETWEEN 0 AND 10)',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    onsetAt,
    endAt,
    recordedAt,
    updatedAt,
    severity,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symptom_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SymptomEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('onset_at')) {
      context.handle(
        _onsetAtMeta,
        onsetAt.isAcceptableOrUnknown(data['onset_at']!, _onsetAtMeta),
      );
    } else if (isInserting) {
      context.missing(_onsetAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SymptomEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SymptomEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      onsetAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}onset_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}severity'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  SymptomEntries createAlias(String alias) {
    return SymptomEntries(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SymptomEntry extends DataClass implements Insertable<SymptomEntry> {
  final String id;
  final String title;
  final int onsetAt;
  final int? endAt;
  final int recordedAt;
  final int updatedAt;
  final int? severity;
  final String notes;
  const SymptomEntry({
    required this.id,
    required this.title,
    required this.onsetAt,
    this.endAt,
    required this.recordedAt,
    required this.updatedAt,
    this.severity,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['onset_at'] = Variable<int>(onsetAt);
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<int>(endAt);
    }
    map['recorded_at'] = Variable<int>(recordedAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || severity != null) {
      map['severity'] = Variable<int>(severity);
    }
    map['notes'] = Variable<String>(notes);
    return map;
  }

  SymptomEntriesCompanion toCompanion(bool nullToAbsent) {
    return SymptomEntriesCompanion(
      id: Value(id),
      title: Value(title),
      onsetAt: Value(onsetAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      recordedAt: Value(recordedAt),
      updatedAt: Value(updatedAt),
      severity: severity == null && nullToAbsent
          ? const Value.absent()
          : Value(severity),
      notes: Value(notes),
    );
  }

  factory SymptomEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SymptomEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      onsetAt: serializer.fromJson<int>(json['onset_at']),
      endAt: serializer.fromJson<int?>(json['end_at']),
      recordedAt: serializer.fromJson<int>(json['recorded_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      severity: serializer.fromJson<int?>(json['severity']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'onset_at': serializer.toJson<int>(onsetAt),
      'end_at': serializer.toJson<int?>(endAt),
      'recorded_at': serializer.toJson<int>(recordedAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'severity': serializer.toJson<int?>(severity),
      'notes': serializer.toJson<String>(notes),
    };
  }

  SymptomEntry copyWith({
    String? id,
    String? title,
    int? onsetAt,
    Value<int?> endAt = const Value.absent(),
    int? recordedAt,
    int? updatedAt,
    Value<int?> severity = const Value.absent(),
    String? notes,
  }) => SymptomEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    onsetAt: onsetAt ?? this.onsetAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    recordedAt: recordedAt ?? this.recordedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    severity: severity.present ? severity.value : this.severity,
    notes: notes ?? this.notes,
  );
  SymptomEntry copyWithCompanion(SymptomEntriesCompanion data) {
    return SymptomEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      onsetAt: data.onsetAt.present ? data.onsetAt.value : this.onsetAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      severity: data.severity.present ? data.severity.value : this.severity,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('onsetAt: $onsetAt, ')
          ..write('endAt: $endAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    onsetAt,
    endAt,
    recordedAt,
    updatedAt,
    severity,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymptomEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.onsetAt == this.onsetAt &&
          other.endAt == this.endAt &&
          other.recordedAt == this.recordedAt &&
          other.updatedAt == this.updatedAt &&
          other.severity == this.severity &&
          other.notes == this.notes);
}

class SymptomEntriesCompanion extends UpdateCompanion<SymptomEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> onsetAt;
  final Value<int?> endAt;
  final Value<int> recordedAt;
  final Value<int> updatedAt;
  final Value<int?> severity;
  final Value<String> notes;
  final Value<int> rowid;
  const SymptomEntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.onsetAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.severity = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SymptomEntriesCompanion.insert({
    required String id,
    required String title,
    required int onsetAt,
    this.endAt = const Value.absent(),
    required int recordedAt,
    required int updatedAt,
    this.severity = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       onsetAt = Value(onsetAt),
       recordedAt = Value(recordedAt),
       updatedAt = Value(updatedAt);
  static Insertable<SymptomEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? onsetAt,
    Expression<int>? endAt,
    Expression<int>? recordedAt,
    Expression<int>? updatedAt,
    Expression<int>? severity,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (onsetAt != null) 'onset_at': onsetAt,
      if (endAt != null) 'end_at': endAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (severity != null) 'severity': severity,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SymptomEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? onsetAt,
    Value<int?>? endAt,
    Value<int>? recordedAt,
    Value<int>? updatedAt,
    Value<int?>? severity,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return SymptomEntriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      onsetAt: onsetAt ?? this.onsetAt,
      endAt: endAt ?? this.endAt,
      recordedAt: recordedAt ?? this.recordedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (onsetAt.present) {
      map['onset_at'] = Variable<int>(onsetAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(endAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<int>(recordedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('onsetAt: $onsetAt, ')
          ..write('endAt: $endAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PainMarkers extends Table with TableInfo<PainMarkers, PainMarker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PainMarkers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _symptomIdMeta = const VerificationMeta(
    'symptomId',
  );
  late final GeneratedColumn<String> symptomId = GeneratedColumn<String>(
    'symptom_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES symptom_entries(id)',
  );
  static const VerificationMeta _bodyViewMeta = const VerificationMeta(
    'bodyView',
  );
  late final GeneratedColumn<String> bodyView = GeneratedColumn<String>(
    'body_view',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (body_view IN (\'front\', \'back\'))',
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (x BETWEEN 0 AND 1)',
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (y BETWEEN 0 AND 1)',
  );
  static const VerificationMeta _radiusMeta = const VerificationMeta('radius');
  late final GeneratedColumn<double> radius = GeneratedColumn<double>(
    'radius',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (radius BETWEEN 0 AND 1)',
  );
  static const VerificationMeta _bodyAssetVersionMeta = const VerificationMeta(
    'bodyAssetVersion',
  );
  late final GeneratedColumn<String> bodyAssetVersion = GeneratedColumn<String>(
    'body_asset_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _regionCodeMeta = const VerificationMeta(
    'regionCode',
  );
  late final GeneratedColumn<String> regionCode = GeneratedColumn<String>(
    'region_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lateralityMeta = const VerificationMeta(
    'laterality',
  );
  late final GeneratedColumn<String> laterality = GeneratedColumn<String>(
    'laterality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (laterality IN (\'left\', \'right\', \'midline\', \'bilateral\', \'unspecified\'))',
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (severity BETWEEN 0 AND 10)',
  );
  static const VerificationMeta _painTypeMeta = const VerificationMeta(
    'painType',
  );
  late final GeneratedColumn<String> painType = GeneratedColumn<String>(
    'pain_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (pain_type IN (\'aching\', \'sharp\', \'burning\', \'throbbing\', \'tingling\', \'other\'))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    symptomId,
    bodyView,
    x,
    y,
    radius,
    bodyAssetVersion,
    regionCode,
    laterality,
    severity,
    painType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pain_markers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PainMarker> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('symptom_id')) {
      context.handle(
        _symptomIdMeta,
        symptomId.isAcceptableOrUnknown(data['symptom_id']!, _symptomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_symptomIdMeta);
    }
    if (data.containsKey('body_view')) {
      context.handle(
        _bodyViewMeta,
        bodyView.isAcceptableOrUnknown(data['body_view']!, _bodyViewMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyViewMeta);
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
    if (data.containsKey('radius')) {
      context.handle(
        _radiusMeta,
        radius.isAcceptableOrUnknown(data['radius']!, _radiusMeta),
      );
    }
    if (data.containsKey('body_asset_version')) {
      context.handle(
        _bodyAssetVersionMeta,
        bodyAssetVersion.isAcceptableOrUnknown(
          data['body_asset_version']!,
          _bodyAssetVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bodyAssetVersionMeta);
    }
    if (data.containsKey('region_code')) {
      context.handle(
        _regionCodeMeta,
        regionCode.isAcceptableOrUnknown(data['region_code']!, _regionCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_regionCodeMeta);
    }
    if (data.containsKey('laterality')) {
      context.handle(
        _lateralityMeta,
        laterality.isAcceptableOrUnknown(data['laterality']!, _lateralityMeta),
      );
    } else if (isInserting) {
      context.missing(_lateralityMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('pain_type')) {
      context.handle(
        _painTypeMeta,
        painType.isAcceptableOrUnknown(data['pain_type']!, _painTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_painTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PainMarker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PainMarker(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      symptomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptom_id'],
      )!,
      bodyView: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_view'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      radius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius'],
      ),
      bodyAssetVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_asset_version'],
      )!,
      regionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_code'],
      )!,
      laterality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}laterality'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}severity'],
      )!,
      painType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pain_type'],
      )!,
    );
  }

  @override
  PainMarkers createAlias(String alias) {
    return PainMarkers(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PainMarker extends DataClass implements Insertable<PainMarker> {
  final String id;
  final String symptomId;
  final String bodyView;
  final double x;
  final double y;
  final double? radius;
  final String bodyAssetVersion;
  final String regionCode;
  final String laterality;
  final int severity;
  final String painType;
  const PainMarker({
    required this.id,
    required this.symptomId,
    required this.bodyView,
    required this.x,
    required this.y,
    this.radius,
    required this.bodyAssetVersion,
    required this.regionCode,
    required this.laterality,
    required this.severity,
    required this.painType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['symptom_id'] = Variable<String>(symptomId);
    map['body_view'] = Variable<String>(bodyView);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    if (!nullToAbsent || radius != null) {
      map['radius'] = Variable<double>(radius);
    }
    map['body_asset_version'] = Variable<String>(bodyAssetVersion);
    map['region_code'] = Variable<String>(regionCode);
    map['laterality'] = Variable<String>(laterality);
    map['severity'] = Variable<int>(severity);
    map['pain_type'] = Variable<String>(painType);
    return map;
  }

  PainMarkersCompanion toCompanion(bool nullToAbsent) {
    return PainMarkersCompanion(
      id: Value(id),
      symptomId: Value(symptomId),
      bodyView: Value(bodyView),
      x: Value(x),
      y: Value(y),
      radius: radius == null && nullToAbsent
          ? const Value.absent()
          : Value(radius),
      bodyAssetVersion: Value(bodyAssetVersion),
      regionCode: Value(regionCode),
      laterality: Value(laterality),
      severity: Value(severity),
      painType: Value(painType),
    );
  }

  factory PainMarker.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PainMarker(
      id: serializer.fromJson<String>(json['id']),
      symptomId: serializer.fromJson<String>(json['symptom_id']),
      bodyView: serializer.fromJson<String>(json['body_view']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      radius: serializer.fromJson<double?>(json['radius']),
      bodyAssetVersion: serializer.fromJson<String>(json['body_asset_version']),
      regionCode: serializer.fromJson<String>(json['region_code']),
      laterality: serializer.fromJson<String>(json['laterality']),
      severity: serializer.fromJson<int>(json['severity']),
      painType: serializer.fromJson<String>(json['pain_type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'symptom_id': serializer.toJson<String>(symptomId),
      'body_view': serializer.toJson<String>(bodyView),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'radius': serializer.toJson<double?>(radius),
      'body_asset_version': serializer.toJson<String>(bodyAssetVersion),
      'region_code': serializer.toJson<String>(regionCode),
      'laterality': serializer.toJson<String>(laterality),
      'severity': serializer.toJson<int>(severity),
      'pain_type': serializer.toJson<String>(painType),
    };
  }

  PainMarker copyWith({
    String? id,
    String? symptomId,
    String? bodyView,
    double? x,
    double? y,
    Value<double?> radius = const Value.absent(),
    String? bodyAssetVersion,
    String? regionCode,
    String? laterality,
    int? severity,
    String? painType,
  }) => PainMarker(
    id: id ?? this.id,
    symptomId: symptomId ?? this.symptomId,
    bodyView: bodyView ?? this.bodyView,
    x: x ?? this.x,
    y: y ?? this.y,
    radius: radius.present ? radius.value : this.radius,
    bodyAssetVersion: bodyAssetVersion ?? this.bodyAssetVersion,
    regionCode: regionCode ?? this.regionCode,
    laterality: laterality ?? this.laterality,
    severity: severity ?? this.severity,
    painType: painType ?? this.painType,
  );
  PainMarker copyWithCompanion(PainMarkersCompanion data) {
    return PainMarker(
      id: data.id.present ? data.id.value : this.id,
      symptomId: data.symptomId.present ? data.symptomId.value : this.symptomId,
      bodyView: data.bodyView.present ? data.bodyView.value : this.bodyView,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      radius: data.radius.present ? data.radius.value : this.radius,
      bodyAssetVersion: data.bodyAssetVersion.present
          ? data.bodyAssetVersion.value
          : this.bodyAssetVersion,
      regionCode: data.regionCode.present
          ? data.regionCode.value
          : this.regionCode,
      laterality: data.laterality.present
          ? data.laterality.value
          : this.laterality,
      severity: data.severity.present ? data.severity.value : this.severity,
      painType: data.painType.present ? data.painType.value : this.painType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PainMarker(')
          ..write('id: $id, ')
          ..write('symptomId: $symptomId, ')
          ..write('bodyView: $bodyView, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('radius: $radius, ')
          ..write('bodyAssetVersion: $bodyAssetVersion, ')
          ..write('regionCode: $regionCode, ')
          ..write('laterality: $laterality, ')
          ..write('severity: $severity, ')
          ..write('painType: $painType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    symptomId,
    bodyView,
    x,
    y,
    radius,
    bodyAssetVersion,
    regionCode,
    laterality,
    severity,
    painType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PainMarker &&
          other.id == this.id &&
          other.symptomId == this.symptomId &&
          other.bodyView == this.bodyView &&
          other.x == this.x &&
          other.y == this.y &&
          other.radius == this.radius &&
          other.bodyAssetVersion == this.bodyAssetVersion &&
          other.regionCode == this.regionCode &&
          other.laterality == this.laterality &&
          other.severity == this.severity &&
          other.painType == this.painType);
}

class PainMarkersCompanion extends UpdateCompanion<PainMarker> {
  final Value<String> id;
  final Value<String> symptomId;
  final Value<String> bodyView;
  final Value<double> x;
  final Value<double> y;
  final Value<double?> radius;
  final Value<String> bodyAssetVersion;
  final Value<String> regionCode;
  final Value<String> laterality;
  final Value<int> severity;
  final Value<String> painType;
  final Value<int> rowid;
  const PainMarkersCompanion({
    this.id = const Value.absent(),
    this.symptomId = const Value.absent(),
    this.bodyView = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.radius = const Value.absent(),
    this.bodyAssetVersion = const Value.absent(),
    this.regionCode = const Value.absent(),
    this.laterality = const Value.absent(),
    this.severity = const Value.absent(),
    this.painType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PainMarkersCompanion.insert({
    required String id,
    required String symptomId,
    required String bodyView,
    required double x,
    required double y,
    this.radius = const Value.absent(),
    required String bodyAssetVersion,
    required String regionCode,
    required String laterality,
    required int severity,
    required String painType,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       symptomId = Value(symptomId),
       bodyView = Value(bodyView),
       x = Value(x),
       y = Value(y),
       bodyAssetVersion = Value(bodyAssetVersion),
       regionCode = Value(regionCode),
       laterality = Value(laterality),
       severity = Value(severity),
       painType = Value(painType);
  static Insertable<PainMarker> custom({
    Expression<String>? id,
    Expression<String>? symptomId,
    Expression<String>? bodyView,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? radius,
    Expression<String>? bodyAssetVersion,
    Expression<String>? regionCode,
    Expression<String>? laterality,
    Expression<int>? severity,
    Expression<String>? painType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (symptomId != null) 'symptom_id': symptomId,
      if (bodyView != null) 'body_view': bodyView,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (radius != null) 'radius': radius,
      if (bodyAssetVersion != null) 'body_asset_version': bodyAssetVersion,
      if (regionCode != null) 'region_code': regionCode,
      if (laterality != null) 'laterality': laterality,
      if (severity != null) 'severity': severity,
      if (painType != null) 'pain_type': painType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PainMarkersCompanion copyWith({
    Value<String>? id,
    Value<String>? symptomId,
    Value<String>? bodyView,
    Value<double>? x,
    Value<double>? y,
    Value<double?>? radius,
    Value<String>? bodyAssetVersion,
    Value<String>? regionCode,
    Value<String>? laterality,
    Value<int>? severity,
    Value<String>? painType,
    Value<int>? rowid,
  }) {
    return PainMarkersCompanion(
      id: id ?? this.id,
      symptomId: symptomId ?? this.symptomId,
      bodyView: bodyView ?? this.bodyView,
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius ?? this.radius,
      bodyAssetVersion: bodyAssetVersion ?? this.bodyAssetVersion,
      regionCode: regionCode ?? this.regionCode,
      laterality: laterality ?? this.laterality,
      severity: severity ?? this.severity,
      painType: painType ?? this.painType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (symptomId.present) {
      map['symptom_id'] = Variable<String>(symptomId.value);
    }
    if (bodyView.present) {
      map['body_view'] = Variable<String>(bodyView.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (radius.present) {
      map['radius'] = Variable<double>(radius.value);
    }
    if (bodyAssetVersion.present) {
      map['body_asset_version'] = Variable<String>(bodyAssetVersion.value);
    }
    if (regionCode.present) {
      map['region_code'] = Variable<String>(regionCode.value);
    }
    if (laterality.present) {
      map['laterality'] = Variable<String>(laterality.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    if (painType.present) {
      map['pain_type'] = Variable<String>(painType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PainMarkersCompanion(')
          ..write('id: $id, ')
          ..write('symptomId: $symptomId, ')
          ..write('bodyView: $bodyView, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('radius: $radius, ')
          ..write('bodyAssetVersion: $bodyAssetVersion, ')
          ..write('regionCode: $regionCode, ')
          ..write('laterality: $laterality, ')
          ..write('severity: $severity, ')
          ..write('painType: $painType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$JournalDatabase extends GeneratedDatabase {
  _$JournalDatabase(QueryExecutor e) : super(e);
  $JournalDatabaseManager get managers => $JournalDatabaseManager(this);
  late final Profile profile = Profile(this);
  late final Medications medications = Medications(this);
  late final MedicationRegimens medicationRegimens = MedicationRegimens(this);
  late final MedicationEvents medicationEvents = MedicationEvents(this);
  late final Index medicationEventsTime = Index(
    'medication_events_time',
    'CREATE INDEX medication_events_time ON medication_events (recorded_at)',
  );
  late final SymptomEntries symptomEntries = SymptomEntries(this);
  late final PainMarkers painMarkers = PainMarkers(this);
  late final Index symptomsTime = Index(
    'symptoms_time',
    'CREATE INDEX symptoms_time ON symptom_entries (onset_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profile,
    medications,
    medicationRegimens,
    medicationEvents,
    medicationEventsTime,
    symptomEntries,
    painMarkers,
    symptomsTime,
  ];
}

typedef $ProfileCreateCompanionBuilder = ProfileCompanion Function({
  Value<int> singleton,
  Value<String?> name,
  Value<String?> dateOfBirth,
});
typedef $ProfileUpdateCompanionBuilder = ProfileCompanion Function({
  Value<int> singleton,
  Value<String?> name,
  Value<String?> dateOfBirth,
});

class $ProfileFilterComposer extends Composer<_$JournalDatabase, Profile> {
  $ProfileFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );
}

class $ProfileOrderingComposer extends Composer<_$JournalDatabase, Profile> {
  $ProfileOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ProfileAnnotationComposer extends Composer<_$JournalDatabase, Profile> {
  $ProfileAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singleton =>
      $composableBuilder(column: $table.singleton, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );
}

class $ProfileTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          Profile,
          ProfileData,
          $ProfileFilterComposer,
          $ProfileOrderingComposer,
          $ProfileAnnotationComposer,
          $ProfileCreateCompanionBuilder,
          $ProfileUpdateCompanionBuilder,
          (
            ProfileData,
            BaseReferences<_$JournalDatabase, Profile, ProfileData>,
          ),
          ProfileData,
          PrefetchHooks Function()
        > {
  $ProfileTableManager(_$JournalDatabase db, Profile table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ProfileFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ProfileOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ProfileAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> singleton = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> dateOfBirth = const Value.absent(),
              }) => ProfileCompanion(
                singleton: singleton,
                name: name,
                dateOfBirth: dateOfBirth,
              ),
          createCompanionCallback:
              ({
                Value<int> singleton = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> dateOfBirth = const Value.absent(),
              }) => ProfileCompanion.insert(
                singleton: singleton,
                name: name,
                dateOfBirth: dateOfBirth,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Profile, ProfileData>(table),
                  BaseReferences<_$JournalDatabase, Profile, ProfileData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ProfileProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      Profile,
      ProfileData,
      $ProfileFilterComposer,
      $ProfileOrderingComposer,
      $ProfileAnnotationComposer,
      $ProfileCreateCompanionBuilder,
      $ProfileUpdateCompanionBuilder,
      (ProfileData, BaseReferences<_$JournalDatabase, Profile, ProfileData>),
      ProfileData,
      PrefetchHooks Function()
    >;
typedef $MedicationsCreateCompanionBuilder = MedicationsCompanion Function({
  required String id,
  required String name,
  required String strength,
  Value<int> archived,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $MedicationsUpdateCompanionBuilder = MedicationsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> strength,
  Value<int> archived,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $MedicationsReferences
    extends BaseReferences<_$JournalDatabase, Medications, Medication> {
  $MedicationsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<MedicationRegimens, List<MedicationRegimen>>
  _medicationRegimensRefsTable(_$JournalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationRegimens,
        aliasName: 'medications__id__medication_regimens__medication_id',
      );

  $MedicationRegimensProcessedTableManager get medicationRegimensRefs {
    final manager = $MedicationRegimensTableManager(
      $_db,
      $_db.medicationRegimens,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationRegimensRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $MedicationsFilterComposer
    extends Composer<_$JournalDatabase, Medications> {
  $MedicationsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> medicationRegimensRefs(
    Expression<bool> Function($MedicationRegimensFilterComposer f) f,
  ) {
    final $MedicationRegimensFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationRegimens,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationRegimensFilterComposer(
            $db: $db,
            $table: $db.medicationRegimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $MedicationsOrderingComposer
    extends Composer<_$JournalDatabase, Medications> {
  $MedicationsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MedicationsAnnotationComposer
    extends Composer<_$JournalDatabase, Medications> {
  $MedicationsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<int> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> medicationRegimensRefs<T extends Object>(
    Expression<T> Function($MedicationRegimensAnnotationComposer a) f,
  ) {
    final $MedicationRegimensAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationRegimens,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationRegimensAnnotationComposer(
            $db: $db,
            $table: $db.medicationRegimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $MedicationsTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          Medications,
          Medication,
          $MedicationsFilterComposer,
          $MedicationsOrderingComposer,
          $MedicationsAnnotationComposer,
          $MedicationsCreateCompanionBuilder,
          $MedicationsUpdateCompanionBuilder,
          (Medication, $MedicationsReferences),
          Medication,
          PrefetchHooks Function({bool medicationRegimensRefs})
        > {
  $MedicationsTableManager(_$JournalDatabase db, Medications table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MedicationsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MedicationsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MedicationsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> strength = const Value.absent(),
                Value<int> archived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                name: name,
                strength: strength,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String strength,
                Value<int> archived = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                name: name,
                strength: strength,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Medications, Medication>(table),
                  $MedicationsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({medicationRegimensRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (medicationRegimensRefs) db.medicationRegimens,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (medicationRegimensRefs)
                    await $_getPrefetchedDataByColumns<
                      Medication,
                      Medications,
                      MedicationRegimen,
                      MedicationRegimens
                    >(
                      currentTable: table,
                      referencedTable: $MedicationsReferences
                          ._medicationRegimensRefsTable(db),
                      managerFromTypedResult: (p0) => $MedicationsReferences(
                        db,
                        table,
                        p0,
                      ).medicationRegimensRefs,
                      currentColumn: 'id',
                      referencedColumn: 'medication_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $MedicationsProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      Medications,
      Medication,
      $MedicationsFilterComposer,
      $MedicationsOrderingComposer,
      $MedicationsAnnotationComposer,
      $MedicationsCreateCompanionBuilder,
      $MedicationsUpdateCompanionBuilder,
      (Medication, $MedicationsReferences),
      Medication,
      PrefetchHooks Function({bool medicationRegimensRefs})
    >;
typedef $MedicationRegimensCreateCompanionBuilder =
    MedicationRegimensCompanion Function({
      required String id,
      required String medicationId,
      required double amount,
      required String unit,
      required String kind,
      required int effectiveFrom,
      Value<int?> effectiveTo,
      required String instructionsSnapshot,
      Value<int> rowid,
    });
typedef $MedicationRegimensUpdateCompanionBuilder =
    MedicationRegimensCompanion Function({
      Value<String> id,
      Value<String> medicationId,
      Value<double> amount,
      Value<String> unit,
      Value<String> kind,
      Value<int> effectiveFrom,
      Value<int?> effectiveTo,
      Value<String> instructionsSnapshot,
      Value<int> rowid,
    });

final class $MedicationRegimensReferences
    extends
        BaseReferences<
          _$JournalDatabase,
          MedicationRegimens,
          MedicationRegimen
        > {
  $MedicationRegimensReferences(super.$_db, super.$_table, super.$_typedResult);

  static Medications _medicationIdTable(_$JournalDatabase db) => db.medications
      .createAlias('medication_regimens__medication_id__medications__id');

  $MedicationsProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $MedicationsTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<MedicationEvents, List<MedicationEvent>>
  _medicationEventsRefsTable(_$JournalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationEvents,
        aliasName: 'medication_regimens__id__medication_events__regimen_id',
      );

  $MedicationEventsProcessedTableManager get medicationEventsRefs {
    final manager = $MedicationEventsTableManager(
      $_db,
      $_db.medicationEvents,
    ).filter((f) => f.regimenId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $MedicationRegimensFilterComposer
    extends Composer<_$JournalDatabase, MedicationRegimens> {
  $MedicationRegimensFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructionsSnapshot => $composableBuilder(
    column: $table.instructionsSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  $MedicationsFilterComposer get medicationId {
    final $MedicationsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationsFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> medicationEventsRefs(
    Expression<bool> Function($MedicationEventsFilterComposer f) f,
  ) {
    final $MedicationEventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationEvents,
      getReferencedColumn: (t) => t.regimenId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationEventsFilterComposer(
            $db: $db,
            $table: $db.medicationEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $MedicationRegimensOrderingComposer
    extends Composer<_$JournalDatabase, MedicationRegimens> {
  $MedicationRegimensOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructionsSnapshot => $composableBuilder(
    column: $table.instructionsSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  $MedicationsOrderingComposer get medicationId {
    final $MedicationsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationsOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MedicationRegimensAnnotationComposer
    extends Composer<_$JournalDatabase, MedicationRegimens> {
  $MedicationRegimensAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<int> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instructionsSnapshot => $composableBuilder(
    column: $table.instructionsSnapshot,
    builder: (column) => column,
  );

  $MedicationsAnnotationComposer get medicationId {
    final $MedicationsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationsAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> medicationEventsRefs<T extends Object>(
    Expression<T> Function($MedicationEventsAnnotationComposer a) f,
  ) {
    final $MedicationEventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationEvents,
      getReferencedColumn: (t) => t.regimenId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationEventsAnnotationComposer(
            $db: $db,
            $table: $db.medicationEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $MedicationRegimensTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          MedicationRegimens,
          MedicationRegimen,
          $MedicationRegimensFilterComposer,
          $MedicationRegimensOrderingComposer,
          $MedicationRegimensAnnotationComposer,
          $MedicationRegimensCreateCompanionBuilder,
          $MedicationRegimensUpdateCompanionBuilder,
          (MedicationRegimen, $MedicationRegimensReferences),
          MedicationRegimen,
          PrefetchHooks Function({bool medicationId, bool medicationEventsRefs})
        > {
  $MedicationRegimensTableManager(
    _$JournalDatabase db,
    MedicationRegimens table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MedicationRegimensFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MedicationRegimensOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MedicationRegimensAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> effectiveFrom = const Value.absent(),
                Value<int?> effectiveTo = const Value.absent(),
                Value<String> instructionsSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationRegimensCompanion(
                id: id,
                medicationId: medicationId,
                amount: amount,
                unit: unit,
                kind: kind,
                effectiveFrom: effectiveFrom,
                effectiveTo: effectiveTo,
                instructionsSnapshot: instructionsSnapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String medicationId,
                required double amount,
                required String unit,
                required String kind,
                required int effectiveFrom,
                Value<int?> effectiveTo = const Value.absent(),
                required String instructionsSnapshot,
                Value<int> rowid = const Value.absent(),
              }) => MedicationRegimensCompanion.insert(
                id: id,
                medicationId: medicationId,
                amount: amount,
                unit: unit,
                kind: kind,
                effectiveFrom: effectiveFrom,
                effectiveTo: effectiveTo,
                instructionsSnapshot: instructionsSnapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<MedicationRegimens, MedicationRegimen>(table),
                  $MedicationRegimensReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({medicationId = false, medicationEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (medicationEventsRefs) db.medicationEvents,
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
                        if (medicationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.medicationId,
                            referencedTable: $MedicationRegimensReferences
                                ._medicationIdTable(db),
                            referencedColumn: $MedicationRegimensReferences
                                ._medicationIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (medicationEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          MedicationRegimen,
                          MedicationRegimens,
                          MedicationEvent,
                          MedicationEvents
                        >(
                          currentTable: table,
                          referencedTable: $MedicationRegimensReferences
                              ._medicationEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $MedicationRegimensReferences(
                                db,
                                table,
                                p0,
                              ).medicationEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'regimen_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $MedicationRegimensProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      MedicationRegimens,
      MedicationRegimen,
      $MedicationRegimensFilterComposer,
      $MedicationRegimensOrderingComposer,
      $MedicationRegimensAnnotationComposer,
      $MedicationRegimensCreateCompanionBuilder,
      $MedicationRegimensUpdateCompanionBuilder,
      (MedicationRegimen, $MedicationRegimensReferences),
      MedicationRegimen,
      PrefetchHooks Function({bool medicationId, bool medicationEventsRefs})
    >;
typedef $MedicationEventsCreateCompanionBuilder =
    MedicationEventsCompanion Function({
      required String id,
      required String regimenId,
      Value<String?> occurrenceKey,
      required String status,
      Value<int?> intendedAt,
      Value<int?> takenAt,
      required int recordedAt,
      required double amount,
      required String unit,
      required String medicationSnapshot,
      Value<int> rowid,
    });
typedef $MedicationEventsUpdateCompanionBuilder =
    MedicationEventsCompanion Function({
      Value<String> id,
      Value<String> regimenId,
      Value<String?> occurrenceKey,
      Value<String> status,
      Value<int?> intendedAt,
      Value<int?> takenAt,
      Value<int> recordedAt,
      Value<double> amount,
      Value<String> unit,
      Value<String> medicationSnapshot,
      Value<int> rowid,
    });

final class $MedicationEventsReferences
    extends
        BaseReferences<_$JournalDatabase, MedicationEvents, MedicationEvent> {
  $MedicationEventsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MedicationRegimens _regimenIdTable(_$JournalDatabase db) => db
      .medicationRegimens
      .createAlias('medication_events__regimen_id__medication_regimens__id');

  $MedicationRegimensProcessedTableManager get regimenId {
    final $_column = $_itemColumn<String>('regimen_id')!;

    final manager = $MedicationRegimensTableManager(
      $_db,
      $_db.medicationRegimens,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_regimenIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $MedicationEventsFilterComposer
    extends Composer<_$JournalDatabase, MedicationEvents> {
  $MedicationEventsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intendedAt => $composableBuilder(
    column: $table.intendedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationSnapshot => $composableBuilder(
    column: $table.medicationSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  $MedicationRegimensFilterComposer get regimenId {
    final $MedicationRegimensFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.regimenId,
      referencedTable: $db.medicationRegimens,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationRegimensFilterComposer(
            $db: $db,
            $table: $db.medicationRegimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MedicationEventsOrderingComposer
    extends Composer<_$JournalDatabase, MedicationEvents> {
  $MedicationEventsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intendedAt => $composableBuilder(
    column: $table.intendedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationSnapshot => $composableBuilder(
    column: $table.medicationSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  $MedicationRegimensOrderingComposer get regimenId {
    final $MedicationRegimensOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.regimenId,
      referencedTable: $db.medicationRegimens,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationRegimensOrderingComposer(
            $db: $db,
            $table: $db.medicationRegimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MedicationEventsAnnotationComposer
    extends Composer<_$JournalDatabase, MedicationEvents> {
  $MedicationEventsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get intendedAt => $composableBuilder(
    column: $table.intendedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get medicationSnapshot => $composableBuilder(
    column: $table.medicationSnapshot,
    builder: (column) => column,
  );

  $MedicationRegimensAnnotationComposer get regimenId {
    final $MedicationRegimensAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.regimenId,
      referencedTable: $db.medicationRegimens,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationRegimensAnnotationComposer(
            $db: $db,
            $table: $db.medicationRegimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MedicationEventsTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          MedicationEvents,
          MedicationEvent,
          $MedicationEventsFilterComposer,
          $MedicationEventsOrderingComposer,
          $MedicationEventsAnnotationComposer,
          $MedicationEventsCreateCompanionBuilder,
          $MedicationEventsUpdateCompanionBuilder,
          (MedicationEvent, $MedicationEventsReferences),
          MedicationEvent,
          PrefetchHooks Function({bool regimenId})
        > {
  $MedicationEventsTableManager(_$JournalDatabase db, MedicationEvents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MedicationEventsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MedicationEventsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MedicationEventsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> regimenId = const Value.absent(),
                Value<String?> occurrenceKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> intendedAt = const Value.absent(),
                Value<int?> takenAt = const Value.absent(),
                Value<int> recordedAt = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> medicationSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationEventsCompanion(
                id: id,
                regimenId: regimenId,
                occurrenceKey: occurrenceKey,
                status: status,
                intendedAt: intendedAt,
                takenAt: takenAt,
                recordedAt: recordedAt,
                amount: amount,
                unit: unit,
                medicationSnapshot: medicationSnapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String regimenId,
                Value<String?> occurrenceKey = const Value.absent(),
                required String status,
                Value<int?> intendedAt = const Value.absent(),
                Value<int?> takenAt = const Value.absent(),
                required int recordedAt,
                required double amount,
                required String unit,
                required String medicationSnapshot,
                Value<int> rowid = const Value.absent(),
              }) => MedicationEventsCompanion.insert(
                id: id,
                regimenId: regimenId,
                occurrenceKey: occurrenceKey,
                status: status,
                intendedAt: intendedAt,
                takenAt: takenAt,
                recordedAt: recordedAt,
                amount: amount,
                unit: unit,
                medicationSnapshot: medicationSnapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<MedicationEvents, MedicationEvent>(table),
                  $MedicationEventsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({regimenId = false}) {
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
                    if (regimenId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.regimenId,
                        referencedTable: $MedicationEventsReferences
                            ._regimenIdTable(db),
                        referencedColumn: $MedicationEventsReferences
                            ._regimenIdTable(db)
                            .id,
                      ) as T;
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

typedef $MedicationEventsProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      MedicationEvents,
      MedicationEvent,
      $MedicationEventsFilterComposer,
      $MedicationEventsOrderingComposer,
      $MedicationEventsAnnotationComposer,
      $MedicationEventsCreateCompanionBuilder,
      $MedicationEventsUpdateCompanionBuilder,
      (MedicationEvent, $MedicationEventsReferences),
      MedicationEvent,
      PrefetchHooks Function({bool regimenId})
    >;
typedef $SymptomEntriesCreateCompanionBuilder =
    SymptomEntriesCompanion Function({
      required String id,
      required String title,
      required int onsetAt,
      Value<int?> endAt,
      required int recordedAt,
      required int updatedAt,
      Value<int?> severity,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $SymptomEntriesUpdateCompanionBuilder =
    SymptomEntriesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> onsetAt,
      Value<int?> endAt,
      Value<int> recordedAt,
      Value<int> updatedAt,
      Value<int?> severity,
      Value<String> notes,
      Value<int> rowid,
    });

final class $SymptomEntriesReferences
    extends BaseReferences<_$JournalDatabase, SymptomEntries, SymptomEntry> {
  $SymptomEntriesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<PainMarkers, List<PainMarker>>
  _painMarkersRefsTable(_$JournalDatabase db) => MultiTypedResultKey.fromTable(
    db.painMarkers,
    aliasName: 'symptom_entries__id__pain_markers__symptom_id',
  );

  $PainMarkersProcessedTableManager get painMarkersRefs {
    final manager = $PainMarkersTableManager(
      $_db,
      $_db.painMarkers,
    ).filter((f) => f.symptomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_painMarkersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $SymptomEntriesFilterComposer
    extends Composer<_$JournalDatabase, SymptomEntries> {
  $SymptomEntriesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onsetAt => $composableBuilder(
    column: $table.onsetAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> painMarkersRefs(
    Expression<bool> Function($PainMarkersFilterComposer f) f,
  ) {
    final $PainMarkersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.painMarkers,
      getReferencedColumn: (t) => t.symptomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PainMarkersFilterComposer(
            $db: $db,
            $table: $db.painMarkers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SymptomEntriesOrderingComposer
    extends Composer<_$JournalDatabase, SymptomEntries> {
  $SymptomEntriesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onsetAt => $composableBuilder(
    column: $table.onsetAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SymptomEntriesAnnotationComposer
    extends Composer<_$JournalDatabase, SymptomEntries> {
  $SymptomEntriesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get onsetAt =>
      $composableBuilder(column: $table.onsetAt, builder: (column) => column);

  GeneratedColumn<int> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> painMarkersRefs<T extends Object>(
    Expression<T> Function($PainMarkersAnnotationComposer a) f,
  ) {
    final $PainMarkersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.painMarkers,
      getReferencedColumn: (t) => t.symptomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PainMarkersAnnotationComposer(
            $db: $db,
            $table: $db.painMarkers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SymptomEntriesTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          SymptomEntries,
          SymptomEntry,
          $SymptomEntriesFilterComposer,
          $SymptomEntriesOrderingComposer,
          $SymptomEntriesAnnotationComposer,
          $SymptomEntriesCreateCompanionBuilder,
          $SymptomEntriesUpdateCompanionBuilder,
          (SymptomEntry, $SymptomEntriesReferences),
          SymptomEntry,
          PrefetchHooks Function({bool painMarkersRefs})
        > {
  $SymptomEntriesTableManager(_$JournalDatabase db, SymptomEntries table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SymptomEntriesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SymptomEntriesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SymptomEntriesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> onsetAt = const Value.absent(),
                Value<int?> endAt = const Value.absent(),
                Value<int> recordedAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> severity = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SymptomEntriesCompanion(
                id: id,
                title: title,
                onsetAt: onsetAt,
                endAt: endAt,
                recordedAt: recordedAt,
                updatedAt: updatedAt,
                severity: severity,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int onsetAt,
                Value<int?> endAt = const Value.absent(),
                required int recordedAt,
                required int updatedAt,
                Value<int?> severity = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SymptomEntriesCompanion.insert(
                id: id,
                title: title,
                onsetAt: onsetAt,
                endAt: endAt,
                recordedAt: recordedAt,
                updatedAt: updatedAt,
                severity: severity,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SymptomEntries, SymptomEntry>(table),
                  $SymptomEntriesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({painMarkersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (painMarkersRefs) db.painMarkers],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (painMarkersRefs)
                    await $_getPrefetchedDataByColumns<
                      SymptomEntry,
                      SymptomEntries,
                      PainMarker,
                      PainMarkers
                    >(
                      currentTable: table,
                      referencedTable: $SymptomEntriesReferences
                          ._painMarkersRefsTable(db),
                      managerFromTypedResult: (p0) => $SymptomEntriesReferences(
                        db,
                        table,
                        p0,
                      ).painMarkersRefs,
                      currentColumn: 'id',
                      referencedColumn: 'symptom_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $SymptomEntriesProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      SymptomEntries,
      SymptomEntry,
      $SymptomEntriesFilterComposer,
      $SymptomEntriesOrderingComposer,
      $SymptomEntriesAnnotationComposer,
      $SymptomEntriesCreateCompanionBuilder,
      $SymptomEntriesUpdateCompanionBuilder,
      (SymptomEntry, $SymptomEntriesReferences),
      SymptomEntry,
      PrefetchHooks Function({bool painMarkersRefs})
    >;
typedef $PainMarkersCreateCompanionBuilder = PainMarkersCompanion Function({
  required String id,
  required String symptomId,
  required String bodyView,
  required double x,
  required double y,
  Value<double?> radius,
  required String bodyAssetVersion,
  required String regionCode,
  required String laterality,
  required int severity,
  required String painType,
  Value<int> rowid,
});
typedef $PainMarkersUpdateCompanionBuilder = PainMarkersCompanion Function({
  Value<String> id,
  Value<String> symptomId,
  Value<String> bodyView,
  Value<double> x,
  Value<double> y,
  Value<double?> radius,
  Value<String> bodyAssetVersion,
  Value<String> regionCode,
  Value<String> laterality,
  Value<int> severity,
  Value<String> painType,
  Value<int> rowid,
});

final class $PainMarkersReferences
    extends BaseReferences<_$JournalDatabase, PainMarkers, PainMarker> {
  $PainMarkersReferences(super.$_db, super.$_table, super.$_typedResult);

  static SymptomEntries _symptomIdTable(_$JournalDatabase db) => db
      .symptomEntries
      .createAlias('pain_markers__symptom_id__symptom_entries__id');

  $SymptomEntriesProcessedTableManager get symptomId {
    final $_column = $_itemColumn<String>('symptom_id')!;

    final manager = $SymptomEntriesTableManager(
      $_db,
      $_db.symptomEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_symptomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $PainMarkersFilterComposer
    extends Composer<_$JournalDatabase, PainMarkers> {
  $PainMarkersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyView => $composableBuilder(
    column: $table.bodyView,
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

  ColumnFilters<double> get radius => $composableBuilder(
    column: $table.radius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyAssetVersion => $composableBuilder(
    column: $table.bodyAssetVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get laterality => $composableBuilder(
    column: $table.laterality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get painType => $composableBuilder(
    column: $table.painType,
    builder: (column) => ColumnFilters(column),
  );

  $SymptomEntriesFilterComposer get symptomId {
    final $SymptomEntriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.symptomId,
      referencedTable: $db.symptomEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SymptomEntriesFilterComposer(
            $db: $db,
            $table: $db.symptomEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PainMarkersOrderingComposer
    extends Composer<_$JournalDatabase, PainMarkers> {
  $PainMarkersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyView => $composableBuilder(
    column: $table.bodyView,
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

  ColumnOrderings<double> get radius => $composableBuilder(
    column: $table.radius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyAssetVersion => $composableBuilder(
    column: $table.bodyAssetVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get laterality => $composableBuilder(
    column: $table.laterality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get painType => $composableBuilder(
    column: $table.painType,
    builder: (column) => ColumnOrderings(column),
  );

  $SymptomEntriesOrderingComposer get symptomId {
    final $SymptomEntriesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.symptomId,
      referencedTable: $db.symptomEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SymptomEntriesOrderingComposer(
            $db: $db,
            $table: $db.symptomEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PainMarkersAnnotationComposer
    extends Composer<_$JournalDatabase, PainMarkers> {
  $PainMarkersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bodyView =>
      $composableBuilder(column: $table.bodyView, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get radius =>
      $composableBuilder(column: $table.radius, builder: (column) => column);

  GeneratedColumn<String> get bodyAssetVersion => $composableBuilder(
    column: $table.bodyAssetVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get laterality => $composableBuilder(
    column: $table.laterality,
    builder: (column) => column,
  );

  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get painType =>
      $composableBuilder(column: $table.painType, builder: (column) => column);

  $SymptomEntriesAnnotationComposer get symptomId {
    final $SymptomEntriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.symptomId,
      referencedTable: $db.symptomEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SymptomEntriesAnnotationComposer(
            $db: $db,
            $table: $db.symptomEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PainMarkersTableManager
    extends
        RootTableManager<
          _$JournalDatabase,
          PainMarkers,
          PainMarker,
          $PainMarkersFilterComposer,
          $PainMarkersOrderingComposer,
          $PainMarkersAnnotationComposer,
          $PainMarkersCreateCompanionBuilder,
          $PainMarkersUpdateCompanionBuilder,
          (PainMarker, $PainMarkersReferences),
          PainMarker,
          PrefetchHooks Function({bool symptomId})
        > {
  $PainMarkersTableManager(_$JournalDatabase db, PainMarkers table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PainMarkersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PainMarkersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PainMarkersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> symptomId = const Value.absent(),
                Value<String> bodyView = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double?> radius = const Value.absent(),
                Value<String> bodyAssetVersion = const Value.absent(),
                Value<String> regionCode = const Value.absent(),
                Value<String> laterality = const Value.absent(),
                Value<int> severity = const Value.absent(),
                Value<String> painType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PainMarkersCompanion(
                id: id,
                symptomId: symptomId,
                bodyView: bodyView,
                x: x,
                y: y,
                radius: radius,
                bodyAssetVersion: bodyAssetVersion,
                regionCode: regionCode,
                laterality: laterality,
                severity: severity,
                painType: painType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String symptomId,
                required String bodyView,
                required double x,
                required double y,
                Value<double?> radius = const Value.absent(),
                required String bodyAssetVersion,
                required String regionCode,
                required String laterality,
                required int severity,
                required String painType,
                Value<int> rowid = const Value.absent(),
              }) => PainMarkersCompanion.insert(
                id: id,
                symptomId: symptomId,
                bodyView: bodyView,
                x: x,
                y: y,
                radius: radius,
                bodyAssetVersion: bodyAssetVersion,
                regionCode: regionCode,
                laterality: laterality,
                severity: severity,
                painType: painType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PainMarkers, PainMarker>(table),
                  $PainMarkersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({symptomId = false}) {
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
                    if (symptomId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.symptomId,
                        referencedTable: $PainMarkersReferences._symptomIdTable(
                          db,
                        ),
                        referencedColumn: $PainMarkersReferences
                            ._symptomIdTable(db)
                            .id,
                      ) as T;
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

typedef $PainMarkersProcessedTableManager =
    ProcessedTableManager<
      _$JournalDatabase,
      PainMarkers,
      PainMarker,
      $PainMarkersFilterComposer,
      $PainMarkersOrderingComposer,
      $PainMarkersAnnotationComposer,
      $PainMarkersCreateCompanionBuilder,
      $PainMarkersUpdateCompanionBuilder,
      (PainMarker, $PainMarkersReferences),
      PainMarker,
      PrefetchHooks Function({bool symptomId})
    >;

class $JournalDatabaseManager {
  final _$JournalDatabase _db;
  $JournalDatabaseManager(this._db);
  $ProfileTableManager get profile => $ProfileTableManager(_db, _db.profile);
  $MedicationsTableManager get medications =>
      $MedicationsTableManager(_db, _db.medications);
  $MedicationRegimensTableManager get medicationRegimens =>
      $MedicationRegimensTableManager(_db, _db.medicationRegimens);
  $MedicationEventsTableManager get medicationEvents =>
      $MedicationEventsTableManager(_db, _db.medicationEvents);
  $SymptomEntriesTableManager get symptomEntries =>
      $SymptomEntriesTableManager(_db, _db.symptomEntries);
  $PainMarkersTableManager get painMarkers =>
      $PainMarkersTableManager(_db, _db.painMarkers);
}
