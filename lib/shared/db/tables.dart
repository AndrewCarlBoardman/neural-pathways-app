import 'package:drift/drift.dart';

class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get coverPhotoPath => text().nullable()(); // local file path
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Guides extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deviceId => integer().references(Devices, #id)();
  TextColumn get title => text().withLength(min: 1, max: 160)();
  TextColumn get coverPhotoPath => text().nullable()(); // local file path
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Steps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get guideId => integer().references(Guides, #id)();
  IntColumn get stepIndex => integer()(); // 1..n

  /// Text shown above image 1.
  TextColumn get instructionText => text().withLength(min: 1, max: 300)();

  /// Optional text shown above image 2.
  TextColumn get instructionText2 => text().nullable().withLength(min: 0, max: 300)();

  TextColumn get photoPath => text().nullable()(); // local file path
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class StepAnnotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stepId => integer().references(Steps, #id)();

  /// 0 = shape, 1 = text
  IntColumn get kind => integer().withDefault(const Constant(0))();

  /// For kind=shape:
  /// 0 = rect, 1 = circle
  IntColumn get shapeType => integer().nullable()();

  /// 0 = yellow, 1 = red, 2 = blue
  IntColumn get color => integer().withDefault(const Constant(0))();

  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get w => real()();
  RealColumn get h => real()();

  TextColumn get label => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
