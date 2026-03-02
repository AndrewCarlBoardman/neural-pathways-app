import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [Devices, Guides, Steps, StepAnnotations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v4 introduces StepAnnotations and removes StepHighlights.
      if (from < 4) {
        await m.createTable(stepAnnotations);

        // migrate legacy step_highlights (single box per step) -> step_annotations (shape)
        try {
          final oldRows = await customSelect(
            'SELECT step_id, shape, x, y, w, h, updated_at FROM step_highlights;',
          ).get();

          for (final r in oldRows) {
            await into(stepAnnotations).insert(
              StepAnnotationsCompanion(
                stepId: Value(r.read<int>('step_id')),
                kind: const Value(0), // shape
                shapeType: Value(r.read<int>('shape')),
                color: const Value(0), // default yellow
                x: Value(r.read<double>('x')),
                y: Value(r.read<double>('y')),
                w: Value(r.read<double>('w')),
                h: Value(r.read<double>('h')),
                label: const Value(null),
                sortOrder: const Value(0),
                updatedAt: Value(r.read<DateTime>('updated_at')),
              ),
            );
          }

          await m.deleteTable('step_highlights');
        } catch (_) {
          // old table doesn't exist -> nothing to migrate
        }
      }
    },
  );

  // ----------------- Devices -----------------
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

  // ----------------- Guides -----------------
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

  // ----------------- Steps -----------------
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

  Future<Step?> getStepById(int stepId) {
    return (select(steps)..where((t) => t.id.equals(stepId))).getSingleOrNull();
  }

  Future<void> updateStep({
    required int stepId,
    required String instructionText,
    String? photoPath,
  }) async {
    await (update(steps)..where((t) => t.id.equals(stepId))).write(
      StepsCompanion(
        instructionText: Value(instructionText),
        photoPath: Value(photoPath),
      ),
    );
  }

  // ----------------- StepAnnotations -----------------
  Stream<List<StepAnnotation>> watchAnnotationsForStep(int stepId) {
    return (select(stepAnnotations)
      ..where((t) => t.stepId.equals(stepId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<List<StepAnnotation>> getAnnotationsForStep(int stepId) {
    return (select(stepAnnotations)
      ..where((t) => t.stepId.equals(stepId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<void> replaceAnnotationsForStep({
    required int stepId,
    required List<StepAnnotationsCompanion> rows,
  }) async {
    await transaction(() async {
      await (delete(stepAnnotations)..where((t) => t.stepId.equals(stepId))).go();
      for (final r in rows) {
        await into(stepAnnotations).insert(r);
      }
    });
  }

  Future<void> deleteAnnotationsForStep(int stepId) async {
    await (delete(stepAnnotations)..where((t) => t.stepId.equals(stepId))).go();
  }

  Future<void> deleteStep(int stepId) async {
    await transaction(() async {
      await deleteAnnotationsForStep(stepId);
      await (delete(steps)..where((t) => t.id.equals(stepId))).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'caregiver_guides.sqlite'));
    return NativeDatabase(file);
  });
}
