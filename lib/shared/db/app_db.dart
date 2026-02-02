import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [Devices, Guides, Steps, StepHighlights])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        // StepHighlights structure changed (1 per step).
        await m.deleteTable('step_highlights');
        await m.createTable(stepHighlights);
      }
    },
  );

  // --- Devices ---
  Stream<List<Device>> watchDevices() {
    return (select(devices)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<int> createDevice({
    required String name,
    String? coverPhotoPath,
  }) {
    return into(devices).insert(
      DevicesCompanion.insert(
        name: name,
        coverPhotoPath: Value(coverPhotoPath),
      ),
    );
  }

  Future<Device?> getDeviceById(int id) {
    return (select(devices)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // --- Guides ---
  Stream<List<Guide>> watchGuidesForDevice(int deviceId) {
    return (select(guides)
      ..where((t) => t.deviceId.equals(deviceId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<int> createGuide({
    required int deviceId,
    required String title,
  }) {
    return into(guides).insert(
      GuidesCompanion.insert(
        deviceId: deviceId,
        title: title,
      ),
    );
  }

  Future<Guide?> getGuideById(int id) {
    return (select(guides)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // --- Steps ---
  Stream<List<Step>> watchStepsForGuide(int guideId) {
    return (select(steps)
      ..where((t) => t.guideId.equals(guideId))
      ..orderBy([(t) => OrderingTerm.asc(t.stepIndex)]))
        .watch();
  }

  Future<int> nextStepIndexForGuide(int guideId) async {
    final maxExpr = steps.stepIndex.max();
    final row = await (selectOnly(steps)
      ..addColumns([maxExpr])
      ..where(steps.guideId.equals(guideId)))
        .getSingle();
    final maxVal = row.read(maxExpr);
    return (maxVal ?? 0) + 1;
  }

  Future<int> createStep({
    required int guideId,
    required int stepIndex,
    required String instructionText,
    String? photoPath,
  }) {
    return into(steps).insert(
      StepsCompanion.insert(
        guideId: guideId,
        stepIndex: stepIndex,
        instructionText: instructionText,
        photoPath: Value(photoPath),
      ),
    );
  }

  // --- Highlights (1 per Step) ---
  Stream<StepHighlight?> watchHighlightForStep(int stepId) {
    return (select(stepHighlights)..where((t) => t.stepId.equals(stepId)))
        .watchSingleOrNull();
  }

  Future<StepHighlight?> getHighlightForStep(int stepId) {
    return (select(stepHighlights)..where((t) => t.stepId.equals(stepId)))
        .getSingleOrNull();
  }

  Future<void> upsertHighlight({
    required int stepId,
    required int shape, // 0 = rect (for now)
    required double x,
    required double y,
    required double w,
    required double h,
  }) async {
    double c(double v) => v.clamp(0.0, 1.0);

    // IMPORTANT: Use the Companion constructor (Value wrappers) instead of `.insert(...)`
    // to avoid factory-signature mismatches during schema changes.
    await into(stepHighlights).insertOnConflictUpdate(
      StepHighlightsCompanion(
        stepId: Value(stepId),
        shape: Value(shape),
        x: Value(c(x)),
        y: Value(c(y)),
        w: Value(c(w)),
        h: Value(c(h)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteHighlightForStep(int stepId) async {
    await (delete(stepHighlights)..where((t) => t.stepId.equals(stepId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'caregiver_guides.sqlite'));
    return NativeDatabase(file);
  });
}
