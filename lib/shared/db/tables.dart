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

/// Replaces StepHighlights: multiple annotations per step (shapes + text).
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

  /// Relative coords 0..1 (same idea as before)
  RealColumn get x => real()(); // left
  RealColumn get y => real()(); // top
  RealColumn get w => real()(); // width
  RealColumn get h => real()(); // height

  /// For kind=text (renamed from `text` -> `label` to avoid drift analyzer crash)
  TextColumn get label => text().nullable()();

  /// Optional: simple ordering if needed later
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
