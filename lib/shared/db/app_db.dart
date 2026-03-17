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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 4) {
        await m.createTable(stepAnnotations);

        try {
          final oldRows = await customSelect(
            'SELECT step_id, shape, x, y, w, h, updated_at FROM step_highlights;',
          ).get();

          for (final r in oldRows) {
            await into(stepAnnotations).insert(
              StepAnnotationsCompanion(
                stepId: Value(r.read<int>('step_id')),
                kind: const Value(0),
                shapeType: Value(r.read<int>('shape')),
                color: const Value(0),
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
          // old table doesn't exist
        }
      }

      if (from < 5) {
        await m.addColumn(guides, guides.coverPhotoPath);
      }

      if (from < 6) {
        await m.addColumn(steps, steps.instructionText2);
      }
    },
  );

  Stream<List<Device>> watchDevices() {
    return (select(devices)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
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

  Future<int> ensureDefaultDeviceId() async {
    final existing = await (select(devices)
      ..where((t) => t.name.equals('General'))
      ..limit(1))
        .getSingleOrNull();

    if (existing != null) return existing.id;

    return into(devices).insert(
      DevicesCompanion.insert(
        name: 'General',
        coverPhotoPath: const Value(null),
      ),
    );
  }

  Stream<List<Guide>> watchAllGuides() {
    return (select(guides)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<Guide>> watchGuidesForDevice(int deviceId) {
    return (select(guides)
      ..where((t) => t.deviceId.equals(deviceId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<int> createGuide({
    required int deviceId,
    required String title,
    String? coverPhotoPath,
  }) {
    return into(guides).insert(
      GuidesCompanion.insert(
        deviceId: deviceId,
        title: title,
        coverPhotoPath: Value(coverPhotoPath),
      ),
    );
  }

  Future<int> createGuideInDefaultBucket({
    required String title,
    String? coverPhotoPath,
  }) async {
    final deviceId = await ensureDefaultDeviceId();
    return createGuide(
      deviceId: deviceId,
      title: title,
      coverPhotoPath: coverPhotoPath,
    );
  }

  Future<Guide?> getGuideById(int id) {
    return (select(guides)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateGuide({
    required int guideId,
    required String title,
    String? coverPhotoPath,
  }) async {
    await (update(guides)..where((t) => t.id.equals(guideId))).write(
      GuidesCompanion(
        title: Value(title),
        coverPhotoPath: Value(coverPhotoPath),
      ),
    );
  }

  Future<int> duplicateGuide(int guideId) async {
    return transaction(() async {
      final originalGuide =
      await (select(guides)..where((t) => t.id.equals(guideId))).getSingle();

      final originalSteps = await (select(steps)
        ..where((t) => t.guideId.equals(guideId))
        ..orderBy([(t) => OrderingTerm.asc(t.stepIndex)]))
          .get();

      final newGuideId = await into(guides).insert(
        GuidesCompanion.insert(
          deviceId: originalGuide.deviceId,
          title: '${originalGuide.title} (Copy)',
          coverPhotoPath: Value(originalGuide.coverPhotoPath),
        ),
      );

      for (final step in originalSteps) {
        final newStepId = await into(steps).insert(
          StepsCompanion.insert(
            guideId: newGuideId,
            stepIndex: step.stepIndex,
            instructionText: step.instructionText,
            instructionText2: Value(step.instructionText2),
            photoPath: Value(step.photoPath),
          ),
        );

        final annotations = await (select(stepAnnotations)
          ..where((t) => t.stepId.equals(step.id))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();

        for (final a in annotations) {
          await into(stepAnnotations).insert(
            StepAnnotationsCompanion.insert(
              stepId: newStepId,
              kind: Value(a.kind),
              shapeType: Value(a.shapeType),
              color: Value(a.color),
              x: a.x,
              y: a.y,
              w: a.w,
              h: a.h,
              label: Value(a.label),
              sortOrder: Value(a.sortOrder),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }

      return newGuideId;
    });
  }

  Future<void> deleteGuide(int guideId) async {
    await transaction(() async {
      final guideSteps =
      await (select(steps)..where((t) => t.guideId.equals(guideId))).get();

      for (final step in guideSteps) {
        await deleteAnnotationsForStep(step.id);
      }

      await (delete(steps)..where((t) => t.guideId.equals(guideId))).go();
      await (delete(guides)..where((t) => t.id.equals(guideId))).go();
    });
  }

  Stream<List<Step>> watchStepsForGuide(int guideId) {
    return (select(steps)
      ..where((t) => t.guideId.equals(guideId))
      ..orderBy([(t) => OrderingTerm.asc(t.stepIndex)]))
        .watch();
  }

  Future<List<Step>> getStepsForGuide(int guideId) {
    return (select(steps)
      ..where((t) => t.guideId.equals(guideId))
      ..orderBy([(t) => OrderingTerm.asc(t.stepIndex)]))
        .get();
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
    String? instructionText2,
    String? photoPath,
  }) {
    return into(steps).insert(
      StepsCompanion.insert(
        guideId: guideId,
        stepIndex: stepIndex,
        instructionText: instructionText,
        instructionText2: Value(instructionText2),
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
    String? instructionText2,
    String? photoPath,
  }) async {
    await (update(steps)..where((t) => t.id.equals(stepId))).write(
      StepsCompanion(
        instructionText: Value(instructionText),
        instructionText2: Value(instructionText2),
        photoPath: Value(photoPath),
      ),
    );
  }

  Future<void> reorderSteps({
    required int guideId,
    required List<int> orderedStepIds,
  }) async {
    await transaction(() async {
      final existing = await getStepsForGuide(guideId);
      final existingIds = existing.map((s) => s.id).toSet();

      final filtered = orderedStepIds.where(existingIds.contains).toList();

      final missing = existing.where((s) => !filtered.contains(s.id)).toList()
        ..sort((a, b) => a.stepIndex.compareTo(b.stepIndex));

      final finalOrder = <int>[
        ...filtered,
        ...missing.map((s) => s.id),
      ];

      int tmp = -1;
      for (final id in finalOrder) {
        await (update(steps)..where((t) => t.id.equals(id))).write(
          StepsCompanion(stepIndex: Value(tmp)),
        );
        tmp--;
      }

      for (int i = 0; i < finalOrder.length; i++) {
        await (update(steps)..where((t) => t.id.equals(finalOrder[i]))).write(
          StepsCompanion(stepIndex: Value(i + 1)),
        );
      }
    });
  }

  Future<int> duplicateStep(int stepId) async {
    return transaction(() async {
      final original =
      await (select(steps)..where((t) => t.id.equals(stepId))).getSingle();

      final originalAnnotations = await (select(stepAnnotations)
        ..where((t) => t.stepId.equals(stepId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

      await customUpdate(
        'UPDATE steps SET step_index = step_index + 1 WHERE guide_id = ? AND step_index > ?;',
        variables: [
          Variable<int>(original.guideId),
          Variable<int>(original.stepIndex),
        ],
        updates: {steps},
      );

      final newStepId = await into(steps).insert(
        StepsCompanion.insert(
          guideId: original.guideId,
          stepIndex: original.stepIndex + 1,
          instructionText: original.instructionText,
          instructionText2: Value(original.instructionText2),
          photoPath: Value(original.photoPath),
        ),
      );

      for (final a in originalAnnotations) {
        await into(stepAnnotations).insert(
          StepAnnotationsCompanion.insert(
            stepId: newStepId,
            kind: Value(a.kind),
            shapeType: Value(a.shapeType),
            color: Value(a.color),
            x: a.x,
            y: a.y,
            w: a.w,
            h: a.h,
            label: Value(a.label),
            sortOrder: Value(a.sortOrder),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      return newStepId;
    });
  }

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
      final step =
      await (select(steps)..where((t) => t.id.equals(stepId))).getSingle();

      await deleteAnnotationsForStep(stepId);
      await (delete(steps)..where((t) => t.id.equals(stepId))).go();

      await customUpdate(
        'UPDATE steps SET step_index = step_index - 1 WHERE guide_id = ? AND step_index > ?;',
        variables: [
          Variable<int>(step.guideId),
          Variable<int>(step.stepIndex),
        ],
        updates: {steps},
      );
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
