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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Steps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get guideId => integer().references(Guides, #id)();
  IntColumn get stepIndex => integer()(); // 1..n
  TextColumn get instructionText => text().withLength(min: 1, max: 300)();
  TextColumn get photoPath => text().nullable()(); // local file path
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class StepHighlights extends Table {
  // 1 highlight per step => stepId is PRIMARY KEY
  IntColumn get stepId => integer().references(Steps, #id)();

  // 0 = rect (circle later)
  IntColumn get shape => integer().withDefault(const Constant(0))();

  // Relative coords 0..1
  RealColumn get x => real()(); // left
  RealColumn get y => real()(); // top
  RealColumn get w => real()(); // width
  RealColumn get h => real()(); // height

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {stepId};
}
