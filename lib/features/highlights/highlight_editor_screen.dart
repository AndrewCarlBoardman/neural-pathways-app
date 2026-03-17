import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../shared/db/app_db.dart';

/// Tool modes (drawing tools only). Selection is always available by tapping an item.
enum EditorTool { none, rect, circle, arrow, text }

/// Draft item model.
///
/// Compatibility notes with your existing DB shape:
/// - `kind`: 0 = shape, 1 = text
/// - `shapeType`: 0 = rect, 1 = circle, 2 = arrow
/// - `color`:
///   - Rect/Circle: packed border+fill using _ShapeColorPack (backwards compatible)
///   - Arrow: a single palette index
///   - Text: packed border/bg/text using _TextColorPack
class AnnotationDraft {
  final int? id; // null = new
  final int kind; // 0 shape, 1 text
  final int? shapeType; // shape only: 0 rect, 1 circle, 2 arrow

  /// See notes above.
  final int color;

  /// Relative values 0..1.
  /// - Rect/Circle/Text: x,y,w,h are bounds.
  /// - Arrow: (x,y) is TIP; (w,h) is vector TIP->TAIL.
  final double x, y, w, h;

  final String? label; // text only
  final int sortOrder;

  const AnnotationDraft({
    required this.id,
    required this.kind,
    required this.shapeType,
    required this.color,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.label,
    required this.sortOrder,
  });

  AnnotationDraft copyWith({
    int? id,
    int? kind,
    int? shapeType,
    int? color,
    double? x,
    double? y,
    double? w,
    double? h,
    String? label,
    int? sortOrder,
  }) {
    return AnnotationDraft(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      shapeType: shapeType ?? this.shapeType,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  bool get isText => kind == 1;
  bool get isShape => kind == 0;
  bool get isArrow => isShape && (shapeType ?? 0) == 2;
  bool get isCircle => isShape && (shapeType ?? 0) == 1;
  bool get isRect => isShape && (shapeType ?? 0) == 0;
}

/// Palette indices (shared across shapes + text property pickers)
/// 0 yellow, 1 red, 2 blue, 3 white, 4 black
class Palette {
  static const int yellow = 0;
  static const int red = 1;
  static const int blue = 2;
  static const int white = 3;
  static const int black = 4;

  static const List<String> names = [
    'Yellow',
    'Red',
    'Blue',
    'White',
    'Black',
  ];

  static const List<Color> colors = [
    Colors.yellow,
    Colors.red,
    Colors.blue,
    Colors.white,
    Colors.black,
  ];

  static Color colorOf(int idx) {
    final i = idx.clamp(0, colors.length - 1);
    return colors[i];
  }

  static String nameOf(int idx) {
    final i = idx.clamp(0, names.length - 1);
    return names[i];
  }
}

class _TextColorPack {
  // pack three 0..4 values into an int.
  // border + bg*10 + text*100
  static int pack({required int border, required int bg, required int text}) {
    border = border.clamp(0, 4);
    bg = bg.clamp(0, 4);
    text = text.clamp(0, 4);
    return border + bg * 10 + text * 100;
  }

  static ({int border, int bg, int text}) unpack(int packed) {
    final border = packed % 10;
    final bg = (packed ~/ 10) % 10;
    final text = (packed ~/ 100) % 10;
    return (
    border: border.clamp(0, 4),
    bg: bg.clamp(0, 4),
    text: text.clamp(0, 4),
    );
  }
}

class _ShapeColorPack {
  // pack border+fill into an int.
  // border + fill*10
  static int pack({required int border, required int fill}) {
    border = border.clamp(0, 4);
    fill = fill.clamp(0, 4);
    return border + fill * 10;
  }

  static ({int border, int fill}) unpack(int packed) {
    // Backwards compatibility: if it's an old single palette value (0..4)
    // treat it as both border and fill.
    if (packed >= 0 && packed <= 4) {
      return (border: packed, fill: packed);
    }
    final border = packed % 10;
    final fill = (packed ~/ 10) % 10;
    return (
    border: border.clamp(0, 4),
    fill: fill.clamp(0, 4),
    );
  }
}

class HighlightEditorScreen extends StatefulWidget {
  final int stepId;
  final ImageProvider imageProvider;

  // Framing (normalized to square canvas)
  final double framingScale;
  final double framingTx;
  final double framingTy;
  final List<StepAnnotation> existing;
  final Future<void> Function(List<AnnotationDraft> items) onSave;

  const HighlightEditorScreen({
    super.key,
    required this.stepId,
    required this.imageProvider,
    this.framingScale = 1.0,
    this.framingTx = 0.0,
    this.framingTy = 0.0,
    required this.existing,
    required this.onSave,
  });

  @override
  State<HighlightEditorScreen> createState() => _HighlightEditorScreenState();
}

class _HighlightEditorScreenState extends State<HighlightEditorScreen> with TickerProviderStateMixin {
  final _tx = TransformationController();
  final _sceneKey = GlobalKey();
  final _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  bool _isEditingText = false;

  Size? _sceneSize;
  List<AnnotationDraft> _items = [];
  int? _selectedIndex;

  EditorTool _tool = EditorTool.rect;

  // Defaults for NEW rect/circle
  int _shapeBorder = Palette.yellow;
  int _shapeFill = Palette.yellow;

  // Defaults for NEW arrows
  int _arrowColor = Palette.yellow;

  // Defaults for NEW text
  int _textBorder = Palette.white;
  int _textBg = Palette.black;
  int _textFg = Palette.white;

  // Pointer interaction state
  int? _activePointerId;
  Offset? _lastScenePoint;
  _DragMode? _dragMode;

  int? _drawingIndex;
  Offset? _drawStartScene;

  // Panel
  bool _panelExpanded = false;

  // Haptics (throttled so rotate doesn't buzz constantly)
  int _lastHapticMs = 0;
  void _hapticThrottled([int minGapMs = 70]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticMs < minGapMs) return;
    _lastHapticMs = now;
    HapticFeedback.selectionClick();
  }

  @override
  void initState() {
    super.initState();

    _items = widget.existing
        .map(
          (a) => AnnotationDraft(
        id: a.id,
        kind: a.kind,
        shapeType: a.shapeType,
        color: a.color,
        x: a.x,
        y: a.y,
        w: a.w,
        h: a.h,
        label: a.label,
        sortOrder: a.sortOrder,
      ),
    )
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Prime defaults from last item if it exists
    for (int i = _items.length - 1; i >= 0; i--) {
      final d = _items[i];
      if (d.isRect || d.isCircle) {
        final p = _ShapeColorPack.unpack(d.color);
        _shapeBorder = p.border;
        _shapeFill = p.fill;
        break;
      }
      if (d.isArrow) {
        _arrowColor = d.color.clamp(0, 4);
        break;
      }
      if (d.isText) {
        final t = _TextColorPack.unpack(d.color);
        _textBorder = t.border;
        _textBg = t.bg;
        _textFg = t.text;
        break;
      }
    }
  }

  @override
  void dispose() {
    _tx.dispose();
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  AnnotationDraft? get _selected => (_selectedIndex == null) ? null : _items[_selectedIndex!];

  Future<void> _save() async {
    // If a text item is selected, auto-apply current controller content before saving.
    final sel = _selected;
    if (sel != null && sel.isText) {
      _applyTextLabel();
    }

    await widget.onSave(_items);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _items = [];
      _selectedIndex = null;
      _textController.text = '';
    });
  }

  void _deleteSelected() {
    final idx = _selectedIndex;
    if (idx == null) return;
    setState(() {
      _items.removeAt(idx);
      _selectedIndex = null;
      _textController.text = '';
      _items = [
        for (int i = 0; i < _items.length; i++) _items[i].copyWith(sortOrder: i),
      ];
    });
  }


  void _duplicateSelected() {
    final idx = _selectedIndex;
    if (idx == null) return;
    final d = _items[idx];

    // Small offset so the duplicate is visible and easy to grab
    final nx = (d.x + 0.02).clamp(0.0, 1.0 - d.w);
    final ny = (d.y + 0.02).clamp(0.0, 1.0 - d.h);

    final copy = d.copyWith(
      id: null,
      x: nx,
      y: ny,
      sortOrder: _items.length,
    );

    setState(() {
      _items.add(copy);
      _selectedIndex = _items.length - 1;
      if (copy.isText) {
        _textController.text = copy.label ?? '';
      }
    });
    HapticFeedback.lightImpact();
  }

  void _bringForward() {
    final idx = _selectedIndex;
    if (idx == null) return;
    if (idx >= _items.length - 1) return;

    setState(() {
      final item = _items.removeAt(idx);
      _items.insert(idx + 1, item);
      _selectedIndex = idx + 1;

      // refresh sortOrder so persistence matches visual Z-order
      _items = [
        for (int i = 0; i < _items.length; i++) _items[i].copyWith(sortOrder: i),
      ];
    });
    HapticFeedback.selectionClick();
  }

  void _sendBackward() {
    final idx = _selectedIndex;
    if (idx == null) return;
    if (idx <= 0) return;

    setState(() {
      final item = _items.removeAt(idx);
      _items.insert(idx - 1, item);
      _selectedIndex = idx - 1;

      _items = [
        for (int i = 0; i < _items.length; i++) _items[i].copyWith(sortOrder: i),
      ];
    });
    HapticFeedback.selectionClick();
  }

  // ----------------------------
  // Pointer interaction
  // ----------------------------

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointerId != null) return;
    _activePointerId = event.pointer;

    final scene = _globalToScene(event.position);
    if (scene == null || _sceneSize == null) {
      _activePointerId = null;
      return;
    }

    // 1) Hit existing => select + start move/resize/rotate
    for (int i = _items.length - 1; i >= 0; i--) {
      final d = _items[i];
      if (_hitTestItem(d, scene)) {
        final alreadySelected = _selectedIndex == i;
        _select(i);

        // Text editing is a *second tap* action:
        // 1st tap selects (so you can change colours).
        // 2nd tap (while already selected) enters edit mode.
        if (d.isText && alreadySelected && !_isEditingText &&
            (_tool == EditorTool.text || _tool == EditorTool.none)) {
          _isEditingText = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _textFocus.requestFocus();
          });
          // When editing text, we don't start move/resize until user drags outside the field.
        } else if (!alreadySelected && _isEditingText) {
          _isEditingText = false;
          _textFocus.unfocus();
        }
        _dragMode = _hitTestHandleForItem(d, scene);
        _lastScenePoint = scene;
        setState(() {});
        return;
      }
    }

    // 2) Empty space tap: deselect
    setState(() {
      _selectedIndex = null;
      _textController.text = '';
      _isEditingText = false;
      _textFocus.unfocus();
    });

    // 3) Create on empty space
    if (_tool == EditorTool.none) {
      return;
    }
    if (_tool == EditorTool.text || _tool == EditorTool.none) {
      _createTextAt(scene);
      return;
    }

    // Rect/Circle/Arrow => draw immediately
    _startDrawingAt(scene);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointerId != event.pointer) return;
    final scene = _globalToScene(event.position);
    if (scene == null || _sceneSize == null) return;

    // Drawing new item
    if (_drawingIndex != null && _drawStartScene != null) {
      _updateDrawing(scene);
      return;
    }

    // Transform existing
    if (_selectedIndex == null || _dragMode == null || _lastScenePoint == null) return;
    _updateTransform(scene);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_activePointerId != event.pointer) return;
    _activePointerId = null;

    if (_drawingIndex != null) {
      final idx = _drawingIndex!;
      _drawingIndex = null;
      _drawStartScene = null;
      setState(() {
        _selectedIndex = idx;
        // Require explicit re-select of a tool before placing again.
        _tool = EditorTool.none;
      });
      return;
    }

    _dragMode = null;
    _lastScenePoint = null;
    setState(() {});
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_activePointerId != event.pointer) return;
    _activePointerId = null;
    _drawingIndex = null;
    _drawStartScene = null;
    _dragMode = null;
    _lastScenePoint = null;
    setState(() {});
  }

  // ----------------------------
  // Creation
  // ----------------------------

  void _createTextAt(Offset scenePoint) {
    final s = _sceneSize;
    if (s == null) return;

    const defaultW = 0.26;
    const defaultH = 0.11;

    double x = scenePoint.dx / s.width - defaultW / 2;
    double y = scenePoint.dy / s.height - defaultH / 2;

    x = x.clamp(0.0, 1.0 - defaultW);
    y = y.clamp(0.0, 1.0 - defaultH);

    final packed = _TextColorPack.pack(border: _textBorder, bg: _textBg, text: _textFg);

    final draft = _fitTextDraftToLabel(
      AnnotationDraft(
        id: null,
        kind: 1,
        shapeType: null,
        color: packed,
        x: x,
        y: y,
        w: defaultW,
        h: defaultH,
        label: 'Label',
        sortOrder: _items.length,
      ),
      'Label',
    );

    setState(() {
      _items.add(draft);
      _selectedIndex = _items.length - 1;
      _textController.text = draft.label ?? '';
      // Require explicit re-select of a tool before placing again.
      _tool = EditorTool.none;
    });
    HapticFeedback.lightImpact();
  }

  void _startDrawingAt(Offset scenePoint) {
    final s = _sceneSize;
    if (s == null) return;

    final startX = (scenePoint.dx / s.width).clamp(0.0, 1.0);
    final startY = (scenePoint.dy / s.height).clamp(0.0, 1.0);

    if (_tool == EditorTool.arrow) {
      final draft = AnnotationDraft(
        id: null,
        kind: 0,
        shapeType: 2,
        color: _arrowColor,
        x: startX,
        y: startY,
        w: 0.001,
        h: 0.001,
        label: null,
        sortOrder: _items.length,
      );
      setState(() {
        _items.add(draft);
        _drawingIndex = _items.length - 1;
        _selectedIndex = _drawingIndex;
        _drawStartScene = scenePoint; // tip in scene coords
      });
      return;
    }

    // Rect / Circle
    final shapeType = _tool == EditorTool.circle ? 1 : 0;
    final packed = _ShapeColorPack.pack(border: _shapeBorder, fill: _shapeFill);

    final draft = AnnotationDraft(
      id: null,
      kind: 0,
      shapeType: shapeType,
      color: packed,
      x: startX,
      y: startY,
      w: 0.001,
      h: 0.001,
      label: null,
      sortOrder: _items.length,
    );

    setState(() {
      _items.add(draft);
      _drawingIndex = _items.length - 1;
      _selectedIndex = _drawingIndex;
      _drawStartScene = scenePoint;
    });
    HapticFeedback.lightImpact();
  }

  void _updateDrawing(Offset scenePoint) {
    final s = _sceneSize!;
    final idx = _drawingIndex!;
    final d = _items[idx];

    const minSize = 0.03;

    if (d.isArrow) {
      // tip is where touch started
      final tip = _sceneToRel(scenePoint: _drawStartScene!, size: s);
      final cur = _sceneToRel(scenePoint: scenePoint, size: s);

      // vector TIP->TAIL should be from tip to current
      var dx = (cur.dx - tip.dx).clamp(-1.0, 1.0);
      var dy = (cur.dy - tip.dy).clamp(-1.0, 1.0);

      final len = math.sqrt(dx * dx + dy * dy);
      final scale = len < minSize ? (minSize / (len == 0 ? 0.0001 : len)) : 1.0;
      dx = (dx * scale).clamp(-1.0, 1.0);
      dy = (dy * scale).clamp(-1.0, 1.0);

      setState(() {
        _items[idx] = d.copyWith(
          x: tip.dx,
          y: tip.dy,
          w: dx,
          h: dy,
        );
      });
      return;
    }

    // Rect/Circle bounds
    final start = _drawStartScene!;
    final x1 = (start.dx / s.width).clamp(0.0, 1.0);
    final y1 = (start.dy / s.height).clamp(0.0, 1.0);
    final x2 = (scenePoint.dx / s.width).clamp(0.0, 1.0);
    final y2 = (scenePoint.dy / s.height).clamp(0.0, 1.0);

    final left = math.min(x1, x2);
    final top = math.min(y1, y2);
    final right = math.max(x1, x2);
    final bottom = math.max(y1, y2);

    final w = (right - left).clamp(minSize, 1.0);
    final h = (bottom - top).clamp(minSize, 1.0);

    setState(() {
      _items[idx] = d.copyWith(
        x: left,
        y: top,
        w: w.clamp(0.0, 1.0 - left),
        h: h.clamp(0.0, 1.0 - top),
      );
    });
  }

  // ----------------------------
  // Move/resize/rotate
  // ----------------------------

  void _updateTransform(Offset scenePoint) {
    final s = _sceneSize!;
    final idx = _selectedIndex!;
    final mode = _dragMode!;
    final last = _lastScenePoint!;

    var d = _items[idx];

    if (d.isArrow) {
      final tip = Offset(d.x, d.y);
      final tail = Offset(d.x + d.w, d.y + d.h);

      if (mode == _DragMode.rotateHandle) {
        // tail drag rotates/lengthens
        var newTail = _sceneToRel(scenePoint: scenePoint, size: s);
        newTail = Offset(newTail.dx.clamp(0.0, 1.0), newTail.dy.clamp(0.0, 1.0));

        var dx = (newTail.dx - tip.dx).clamp(-1.0, 1.0);
        var dy = (newTail.dy - tip.dy).clamp(-1.0, 1.0);

        const minLen = 0.05;
        final len = math.sqrt(dx * dx + dy * dy);
        final scale = len < minLen ? (minLen / (len == 0 ? 0.0001 : len)) : 1.0;
        dx *= scale;
        dy *= scale;

        setState(() {
          _items[idx] = d.copyWith(w: dx, h: dy);
          _lastScenePoint = scenePoint;
        });
        _hapticThrottled(90);
        return;
      }

      // move arrow
      final dxScene = (scenePoint.dx - last.dx) / s.width;
      final dyScene = (scenePoint.dy - last.dy) / s.height;

      var newTip = Offset(tip.dx + dxScene, tip.dy + dyScene);
      var newTail = Offset(tail.dx + dxScene, tail.dy + dyScene);

      // clamp by shifting back into 0..1
      double shiftX = 0;
      double shiftY = 0;
      if (newTip.dx < 0) shiftX = -newTip.dx;
      if (newTail.dx < 0) shiftX = math.max(shiftX, -newTail.dx);
      if (newTip.dy < 0) shiftY = -newTip.dy;
      if (newTail.dy < 0) shiftY = math.max(shiftY, -newTail.dy);

      if (newTip.dx > 1) shiftX = math.min(shiftX, 1 - newTip.dx);
      if (newTail.dx > 1) shiftX = math.min(shiftX, 1 - newTail.dx);
      if (newTip.dy > 1) shiftY = math.min(shiftY, 1 - newTip.dy);
      if (newTail.dy > 1) shiftY = math.min(shiftY, 1 - newTail.dy);

      newTip = Offset((newTip.dx + shiftX).clamp(0.0, 1.0), (newTip.dy + shiftY).clamp(0.0, 1.0));
      newTail = Offset((newTail.dx + shiftX).clamp(0.0, 1.0), (newTail.dy + shiftY).clamp(0.0, 1.0));

      setState(() {
        _items[idx] = d.copyWith(
          x: newTip.dx,
          y: newTip.dy,
          w: newTail.dx - newTip.dx,
          h: newTail.dy - newTip.dy,
        );
        _lastScenePoint = scenePoint;
      });
      return;
    }

    // Rect/Circle/Text handles
    final dx = (scenePoint.dx - last.dx) / s.width;
    final dy = (scenePoint.dy - last.dy) / s.height;

    switch (mode) {
      case _DragMode.move:
        d = d.copyWith(
          x: (d.x + dx).clamp(0.0, 1.0 - d.w),
          y: (d.y + dy).clamp(0.0, 1.0 - d.h),
        );
        break;

      case _DragMode.resizeNW:
        final newX = (d.x + dx).clamp(0.0, d.x + d.w - 0.05);
        final newY = (d.y + dy).clamp(0.0, d.y + d.h - 0.05);
        final newW = (d.x + d.w - newX).clamp(0.05, 1.0);
        final newH = (d.y + d.h - newY).clamp(0.05, 1.0);
        d = d.copyWith(x: newX, y: newY, w: newW, h: newH);
        break;

      case _DragMode.resizeNE:
        final newY = (d.y + dy).clamp(0.0, d.y + d.h - 0.05);
        final newW = (d.w + dx).clamp(0.05, 1.0 - d.x);
        final newH = (d.y + d.h - newY).clamp(0.05, 1.0);
        d = d.copyWith(y: newY, w: newW, h: newH);
        break;

      case _DragMode.resizeSW:
        final newX = (d.x + dx).clamp(0.0, d.x + d.w - 0.05);
        final newW = (d.x + d.w - newX).clamp(0.05, 1.0);
        final newH = (d.h + dy).clamp(0.05, 1.0 - d.y);
        d = d.copyWith(x: newX, w: newW, h: newH);
        break;

      case _DragMode.resizeSE:
        final newW = (d.w + dx).clamp(0.05, 1.0 - d.x);
        final newH = (d.h + dy).clamp(0.05, 1.0 - d.y);
        d = d.copyWith(w: newW, h: newH);
        break;

      case _DragMode.rotateHandle:
        break;
    }

    setState(() {
      _items[idx] = d;
      _lastScenePoint = scenePoint;
    });
  }

  void _select(int index) {
    HapticFeedback.selectionClick();
    final d = _items[index];

    setState(() {
      _selectedIndex = index;

      // Prime defaults UI from selection
      if (d.isText) {
        final t = _TextColorPack.unpack(d.color);
        _textBorder = t.border;
        _textBg = t.bg;
        _textFg = t.text;
        _textController.text = d.label ?? '';
        if (_tool == EditorTool.text) {
          _isEditingText = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _textFocus.requestFocus();
          });
        } else {
          _isEditingText = false;
          _textFocus.unfocus();
        }
      } else if (d.isArrow) {
        _isEditingText = false;
        _textFocus.unfocus();
        _arrowColor = d.color.clamp(0, 4);
      } else if (d.isRect || d.isCircle) {
        final s = _ShapeColorPack.unpack(d.color);
        _shapeBorder = s.border;
        _shapeFill = s.fill;
      }
    });
  }

  // ----------------------------
  // Hit testing + geometry
  // ----------------------------

  Offset? _globalToScene(Offset global) {
    final box = _sceneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final local = box.globalToLocal(global);

    final Matrix4 inv = Matrix4.inverted(_tx.value);
    final v = inv.transform3(Vector3(local.dx, local.dy, 0));
    return Offset(v.x, v.y);
  }

  Offset _sceneToRel({required Offset scenePoint, required Size size}) {
    return Offset(
      (scenePoint.dx / size.width).clamp(0.0, 1.0),
      (scenePoint.dy / size.height).clamp(0.0, 1.0),
    );
  }

  Rect _relToSceneRect(AnnotationDraft d) {
    final s = _sceneSize!;
    return Rect.fromLTWH(d.x * s.width, d.y * s.height, d.w * s.width, d.h * s.height);
  }

  bool _hitTestItem(AnnotationDraft d, Offset scene) {
    if (_sceneSize == null) return false;

    if (d.isArrow) {
      final s = _sceneSize!;
      final tip = Offset(d.x * s.width, d.y * s.height);
      final tail = Offset((d.x + d.w) * s.width, (d.y + d.h) * s.height);

      // Forgiving hit area
      final dist = _distancePointToSegment(scene, tail, tip);
      if (dist <= 20) return true;

      final handle = Rect.fromCenter(center: tail, width: 38, height: 38);
      return handle.contains(scene);
    }

    final r = _relToSceneRect(d);
    return r.contains(scene);
  }

  _DragMode _hitTestHandleForItem(AnnotationDraft d, Offset scene) {
    if (_sceneSize == null) return _DragMode.move;

    if (d.isArrow) {
      final s = _sceneSize!;
      final tail = Offset((d.x + d.w) * s.width, (d.y + d.h) * s.height);
      final handle = Rect.fromCenter(center: tail, width: 38, height: 38);
      if (handle.contains(scene)) return _DragMode.rotateHandle;
      return _DragMode.move;
    }

    final r = _relToSceneRect(d);
    const handle = 26.0;
    final nw = Rect.fromLTWH(r.left - handle / 2, r.top - handle / 2, handle, handle);
    final ne = Rect.fromLTWH(r.right - handle / 2, r.top - handle / 2, handle, handle);
    final sw = Rect.fromLTWH(r.left - handle / 2, r.bottom - handle / 2, handle, handle);
    final se = Rect.fromLTWH(r.right - handle / 2, r.bottom - handle / 2, handle, handle);

    if (nw.contains(scene)) return _DragMode.resizeNW;
    if (ne.contains(scene)) return _DragMode.resizeNE;
    if (sw.contains(scene)) return _DragMode.resizeSW;
    if (se.contains(scene)) return _DragMode.resizeSE;

    return _DragMode.move;
  }

  double _distancePointToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (ab2 == 0) return (p - a).distance;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / ab2).clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  // ----------------------------
  // Properties application
  // ----------------------------

  void _setShapeBorder(int paletteIdx) {
    setState(() {
      _shapeBorder = paletteIdx;
      final idx = _selectedIndex;
      if (idx != null) {
        final d = _items[idx];
        if (d.isRect || d.isCircle) {
          final p = _ShapeColorPack.unpack(d.color);
          _items[idx] = d.copyWith(color: _ShapeColorPack.pack(border: paletteIdx, fill: p.fill));
        }
      }
    });
  }

  void _setShapeFill(int paletteIdx) {
    setState(() {
      _shapeFill = paletteIdx;
      final idx = _selectedIndex;
      if (idx != null) {
        final d = _items[idx];
        if (d.isRect || d.isCircle) {
          final p = _ShapeColorPack.unpack(d.color);
          _items[idx] = d.copyWith(color: _ShapeColorPack.pack(border: p.border, fill: paletteIdx));
        }
      }
    });
  }

  void _setArrowColor(int paletteIdx) {
    setState(() {
      _arrowColor = paletteIdx;
      final idx = _selectedIndex;
      if (idx != null) {
        final d = _items[idx];
        if (d.isArrow) {
          _items[idx] = d.copyWith(color: paletteIdx);
        }
      }
    });
  }


  void _applyShapeColors({int? border, int? fill}) {
    final idx = _selectedIndex;

    setState(() {
      // Update defaults for next shapes
      if (border != null) _shapeBorder = border;
      if (fill != null) _shapeFill = fill;

      // If a shape (rect/circle) is selected, update it immediately
      if (idx != null) {
        final d = _items[idx];
        if (d.isShape && !d.isArrow) {
          final packed = _ShapeColorPack.pack(border: _shapeBorder, fill: _shapeFill);
          _items[idx] = d.copyWith(color: packed);
        }
      }
    });
  }

  void _applyArrowColor(int color) {
    final idx = _selectedIndex;

    setState(() {
      _arrowColor = color;

      if (idx != null) {
        final d = _items[idx];
        if (d.isArrow) {
          _items[idx] = d.copyWith(color: _arrowColor);
        }
      }
    });
  }

  void _applyTextColors({int? border, int? bg, int? text}) {
    final idx = _selectedIndex;

    setState(() {
      if (border != null) _textBorder = border;
      if (bg != null) _textBg = bg;
      if (text != null) _textFg = text;

      if (idx != null) {
        final d = _items[idx];
        if (d.isText) {
          final packed = _TextColorPack.pack(border: _textBorder, bg: _textBg, text: _textFg);
          _items[idx] = d.copyWith(color: packed);
        }
      }
    });
  }


  AnnotationDraft _fitTextDraftToLabel(AnnotationDraft d, String rawLabel) {
    final scene = _sceneSize;
    final label = rawLabel.trim().isEmpty ? 'Label' : rawLabel.trim();
    if (scene == null) {
      return d.copyWith(label: label);
    }

    final maxWidthPx = scene.width * 0.42;
    const minWidthPx = 72.0;
    const minHeightPx = 44.0;
    const padX = 18.0;
    const padY = 12.0;

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 5,
    )..layout(maxWidth: maxWidthPx - padX * 2);

    final widthPx = (tp.width + padX * 2).clamp(minWidthPx, maxWidthPx);
    final heightPx = (tp.height + padY * 2).clamp(minHeightPx, scene.height * 0.26);

    final newW = widthPx / scene.width;
    final newH = heightPx / scene.height;

    final centerX = d.x + d.w / 2;
    final centerY = d.y + d.h / 2;

    final newX = (centerX - newW / 2).clamp(0.0, 1.0 - newW);
    final newY = (centerY - newH / 2).clamp(0.0, 1.0 - newH);

    return d.copyWith(
      label: label,
      x: newX,
      y: newY,
      w: newW,
      h: newH,
    );
  }

  void _applyTextLabel() {
    final idx = _selectedIndex;
    if (idx == null) return;
    final d = _items[idx];
    if (!d.isText) return;

    setState(() {
      _items[idx] = _fitTextDraftToLabel(d, _textController.text);
    });
  }

  // ----------------------------
  // UI
  // ----------------------------

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Edit Highlights'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(64, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(90, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _clearAll,
                  child: const Text('Start over'),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final box = _sceneKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box != null) {
                                final size = box.size;
                                if (_sceneSize != size) {
                                  setState(() => _sceneSize = size);
                                }
                              }
                            });

                            return Listener(
                              onPointerDown: _onPointerDown,
                              onPointerMove: _onPointerMove,
                              onPointerUp: _onPointerUp,
                              onPointerCancel: _onPointerCancel,
                              child: Container(
                                key: _sceneKey,
                                color: Colors.black12,
                                child: InteractiveViewer(
                                  transformationController: _tx,
                                  panEnabled: false,
                                  scaleEnabled: false,
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final s = constraints.biggest;
                                            final m = Matrix4.identity()
                                              ..translate(widget.framingTx * s.width,
                                                  widget.framingTy * s.height)
                                              ..scale(widget.framingScale);
                                            return Transform(
                                              alignment: Alignment.topLeft,
                                              transform: m,
                                              child: SizedBox.expand(
                                                child: Image(
                                                  image: widget.imageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        for (int i = 0; i < _items.length; i++)
                                          _ItemLayer(
                                            draft: _items[i],
                                            selected: i == _selectedIndex,
                                            editingText: _isEditingText && i == _selectedIndex,
                                            textController: _textController,
                                            textFocus: _textFocus,
                                            onTextCommitted: _applyTextLabel,
                                            sceneSize: _sceneSize ?? constraints.biggest,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Palette
                      SafeArea(
                        top: false,
                        child: _BottomPanel(
                          expanded: _panelExpanded,
                          onToggleExpanded: () => setState(() => _panelExpanded = !_panelExpanded),
                          tool: _tool,
                          onToolChanged: (t) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tool = t;
                              _selectedIndex = null;
                              _textController.text = '';
                              _isEditingText = false;
                              _textFocus.unfocus();
                            });
                          },
                          selected: selected,
                          shapeBorder: _shapeBorder,
                          shapeFill: _shapeFill,
                          arrowColor: _arrowColor,
                          textBorder: _textBorder,
                          textBg: _textBg,
                          textFg: _textFg,
                          textController: _textController,
                          onShapeBorder: (c) => _applyShapeColors(border: c),
                          onShapeFill: (c) => _applyShapeColors(fill: c),
                          onArrowColor: (c) => _applyArrowColor(c),
                          onTextBorder: (c) => _applyTextColors(border: c),
                          onTextBg: (c) => _applyTextColors(bg: c),
                          onTextFg: (c) => _applyTextColors(text: c),
                          onApplyText: _applyTextLabel,
                          onDeleteSelected: _deleteSelected,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DragMode { move, resizeNW, resizeNE, resizeSW, resizeSE, rotateHandle }

class _BottomPanel extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggleExpanded;

  final EditorTool tool;
  final ValueChanged<EditorTool> onToolChanged;

  final AnnotationDraft? selected;

  final int shapeBorder;
  final int shapeFill;
  final int arrowColor;
  final int textBorder;
  final int textBg;
  final int textFg;

  final TextEditingController textController;

  final ValueChanged<int> onShapeBorder;
  final ValueChanged<int> onShapeFill;
  final ValueChanged<int> onArrowColor;
  final ValueChanged<int> onTextBorder;
  final ValueChanged<int> onTextBg;
  final ValueChanged<int> onTextFg;

  final VoidCallback onApplyText;
  final VoidCallback onDeleteSelected;

  const _BottomPanel({
    required this.expanded,
    required this.onToggleExpanded,
    required this.tool,
    required this.onToolChanged,
    required this.selected,
    required this.shapeBorder,
    required this.shapeFill,
    required this.arrowColor,
    required this.textBorder,
    required this.textBg,
    required this.textFg,
    required this.textController,
    required this.onShapeBorder,
    required this.onShapeFill,
    required this.onArrowColor,
    required this.onTextBorder,
    required this.onTextBg,
    required this.onTextFg,
    required this.onApplyText,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.32;

    // What properties are we editing?
    final d = selected;

    // If something is selected, show selected properties; otherwise show tool defaults.
    final mode = _propsMode(selected: d, tool: tool);

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxH),
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.78),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconToolRail(tool: tool, onToolChanged: onToolChanged),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                if (mode == _PropertiesMode.shape)
                                  _ShapeProps(
                                    border: shapeBorder,
                                    fill: shapeFill,
                                    onBorder: onShapeBorder,
                                    onFill: onShapeFill,
                                  ),

                                if (mode == _PropertiesMode.arrow)
                                  _ArrowProps(
                                    color: arrowColor,
                                    onColor: onArrowColor,
                                  ),

                                if (mode == _PropertiesMode.text)
                                  _TextProps(
                                    border: textBorder,
                                    bg: textBg,
                                    fg: textFg,
                                    controller: textController,
                                    onBorder: onTextBorder,
                                    onBg: onTextBg,
                                    onFg: onTextFg,
                                    onApply: onApplyText,
                                  ),

                                const SizedBox(height: 8),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    onPressed: selected == null ? null : onDeleteSelected,
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete selected',
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PropertiesMode { shape, arrow, text }

_PropertiesMode _propsMode({required AnnotationDraft? selected, required EditorTool tool}) {
  if (selected != null) {
    if (selected.isText) return _PropertiesMode.text;
    if (selected.isArrow) return _PropertiesMode.arrow;
    return _PropertiesMode.shape;
  }

  if (tool == EditorTool.arrow) return _PropertiesMode.arrow;
  if (tool == EditorTool.text) return _PropertiesMode.text;
  return _PropertiesMode.shape;
}

class _PropertiesHeader extends StatelessWidget {
  final _PropertiesMode mode;
  final AnnotationDraft? selected;

  const _PropertiesHeader({
    required this.mode,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (mode) {
      _PropertiesMode.shape => 'Shape properties',
      _PropertiesMode.arrow => 'Arrow properties',
      _PropertiesMode.text => 'Text properties',
    };

    final String? subtitle = null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _IconToolRail extends StatelessWidget {
  final EditorTool tool;
  final ValueChanged<EditorTool> onToolChanged;

  const _IconToolRail({required this.tool, required this.onToolChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget btn({required EditorTool t, required IconData icon, required String tip}) {
      final sel = tool == t;
      return Tooltip(
        message: tip,
        child: InkResponse(
          onTap: () => onToolChanged(t),
          radius: 26,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: sel ? cs.primary.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: sel
                  ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ]
                  : const [],
            ),
            child: Icon(
              icon,
              size: 22,
              color: sel ? cs.primary : Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 60),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            btn(t: EditorTool.rect, icon: Icons.crop_square, tip: 'Rectangle'),
            const SizedBox(height: 10),
            btn(t: EditorTool.circle, icon: Icons.circle_outlined, tip: 'Circle'),
            const SizedBox(height: 10),
            btn(t: EditorTool.arrow, icon: Icons.arrow_right_alt, tip: 'Arrow'),
            const SizedBox(height: 10),
            btn(t: EditorTool.text, icon: Icons.text_fields, tip: 'Text'),
          ],
        ),
      ),
    );
  }
}


class _ColorChip extends StatelessWidget {
  final Color color;
  final double size;
  const _ColorChip({required this.color, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26, width: 1),
      ),
    );
  }
}


class _ColorPickerRow extends StatelessWidget {
  final String label;
  final int value;
  final List<int> allowed;
  final ValueChanged<int> onChanged;

  const _ColorPickerRow({
    required this.label,
    required this.value,
    required this.allowed,
    required this.onChanged,
  });

  Future<void> _showPicker(BuildContext context, Offset globalPos) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final size = overlay?.size ?? const Size(0, 0);

    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPos.dx, globalPos.dy, 1, 1),
        Offset.zero & size,
      ),
      items: [
        PopupMenuItem<int>(
          enabled: false,
          padding: const EdgeInsets.all(10),
          child: _ColorGrid(
            allowed: allowed,
            current: value,
            onPick: (v) => Navigator.pop(context, v),
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
    );

    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final v = allowed.contains(value) ? value : allowed.first;

    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(width: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _showPicker(context, d.globalPosition),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ColorChip(color: Palette.colorOf(v), size: 20),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorGrid extends StatelessWidget {
  final List<int> allowed;
  final int current;
  final ValueChanged<int> onPick;

  const _ColorGrid({
    required this.allowed,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final idx in allowed)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onPick(idx),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: idx == current
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _ColorChip(color: Palette.colorOf(idx), size: 22),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShapeProps extends StatelessWidget {
  final int border;
  final int fill;
  final ValueChanged<int> onBorder;
  final ValueChanged<int> onFill;

  const _ShapeProps({
    required this.border,
    required this.fill,
    required this.onBorder,
    required this.onFill,
  });

  @override
  Widget build(BuildContext context) {
    const allowed = [Palette.yellow, Palette.red, Palette.blue, Palette.white];
    return Column(
      children: [
        _ColorPickerRow(label: 'Border colour', value: border, allowed: allowed, onChanged: onBorder),
        const SizedBox(height: 10),
        _ColorPickerRow(label: 'Fill colour', value: fill, allowed: allowed, onChanged: onFill),
      ],
    );
  }
}

class _ArrowProps extends StatelessWidget {
  final int color;
  final ValueChanged<int> onColor;

  const _ArrowProps({
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    const allowed = [Palette.yellow, Palette.red, Palette.blue, Palette.white, Palette.black];
    return _ColorPickerRow(label: 'Arrow colour', value: color, allowed: allowed, onChanged: onColor);
  }
}

class _TextProps extends StatelessWidget {
  final int border;
  final int bg;
  final int fg;

  final TextEditingController controller;

  final ValueChanged<int> onBorder;
  final ValueChanged<int> onBg;
  final ValueChanged<int> onFg;
  final VoidCallback onApply;

  const _TextProps({
    required this.border,
    required this.bg,
    required this.fg,
    required this.controller,
    required this.onBorder,
    required this.onBg,
    required this.onFg,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    const allowed = [Palette.yellow, Palette.red, Palette.blue, Palette.white, Palette.black];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ColorPickerRow(label: 'Border colour', value: border, allowed: allowed, onChanged: onBorder),
        const SizedBox(height: 10),
        _ColorPickerRow(label: 'Background colour', value: bg, allowed: allowed, onChanged: onBg),
        const SizedBox(height: 10),
        _ColorPickerRow(label: 'Text colour', value: fg, allowed: allowed, onChanged: onFg),
      ],
    );
  }
}

class _ItemLayer extends StatelessWidget {
  final AnnotationDraft draft;
  final bool selected;
  final bool editingText;
  final TextEditingController textController;
  final FocusNode textFocus;
  final VoidCallback onTextCommitted;
  final Size sceneSize;

  const _ItemLayer({
    required this.draft,
    required this.selected,
    required this.editingText,
    required this.textController,
    required this.textFocus,
    required this.onTextCommitted,
    required this.sceneSize,
  });

  @override
  Widget build(BuildContext context) {
    if (draft.isArrow) {
      return _ArrowOverlay(draft: draft, selected: selected);
    }

    Color borderColor;
    Color bgColor;
    Color textColor = Colors.white;

    if (draft.isText) {
      final t = _TextColorPack.unpack(draft.color);
      borderColor = Palette.colorOf(t.border);
      bgColor = Palette.colorOf(t.bg);
      textColor = Palette.colorOf(t.text);
    } else {
      final s = _ShapeColorPack.unpack(draft.color);
      borderColor = Palette.colorOf(s.border);
      bgColor = Palette.colorOf(s.fill);
    }

    final border = Border.all(
      color: borderColor.withOpacity(0.95),
      width: selected ? 4 : 3,
    );

    final bg = draft.isText ? bgColor.withOpacity(0.6) : bgColor.withOpacity(0.18);

    final isCircle = draft.isCircle;

    final rect = _rectFromRel(draft);

    // In-place text editing when selected
    if (draft.isText && selected && editingText) {
      return Positioned.fromRect(
        rect: rect,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              border: border,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            child: TextField(
              controller: textController,
              focusNode: textFocus,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => onTextCommitted(),
              onEditingComplete: onTextCommitted,
            ),
          ),
        ),
      );
    }

    final base = Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: border,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: draft.isText
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                (draft.label ?? '').trim(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          )
              : null,
        ),
      ),
    );

    // Handles for rect + text only (circles stay clean)
    if (!selected || draft.isCircle) return base;

    return Stack(
      children: [
        base,
        Positioned.fromRect(
          rect: _rectFromRel(draft),
          child: IgnorePointer(
            child: _CornerHandles(color: borderColor),
          ),
        ),
      ],
    );
  }

  Rect _rectFromRel(AnnotationDraft d) {
    final size = sceneSize;
    return Rect.fromLTWH(d.x * size.width, d.y * size.height, d.w * size.width, d.h * size.height);
  }
}

class _CornerHandles extends StatelessWidget {
  final Color color;
  const _CornerHandles({required this.color});

  @override
  Widget build(BuildContext context) {
    const double handleSize = 14;

    Widget dot() {
      return Container(
        width: handleSize,
        height: handleSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.95), width: 2),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(left: 2, top: 2, child: dot()),
        Positioned(right: 2, top: 2, child: dot()),
        Positioned(left: 2, bottom: 2, child: dot()),
        Positioned(right: 2, bottom: 2, child: dot()),
      ],
    );
  }
}

class _ArrowOverlay extends StatelessWidget {
  final AnnotationDraft draft;
  final bool selected;

  const _ArrowOverlay({
    required this.draft,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final color = Palette.colorOf(draft.color).withOpacity(0.95);

    return IgnorePointer(
      child: CustomPaint(
        painter: _ArrowPainter(
          x: draft.x,
          y: draft.y,
          dx: draft.w,
          dy: draft.h,
          color: color,
          selected: selected,
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final double x;
  final double y;
  final double dx;
  final double dy;
  final Color color;
  final bool selected;

  _ArrowPainter({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.color,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tip = Offset(x * size.width, y * size.height);
    final tail = Offset((x + dx) * size.width, (y + dy) * size.height);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Stem
    canvas.drawLine(tail, tip, paint);

    // Arrow head at tip pointing from tail -> tip
    final dir = (tip - tail);
    final len = dir.distance;
    if (len > 0.01) {
      final u = dir / len;
      const headLen = 18.0;
      const headAngle = 0.55; // radians

      Offset rot(Offset v, double a) {
        return Offset(
          v.dx * math.cos(a) - v.dy * math.sin(a),
          v.dx * math.sin(a) + v.dy * math.cos(a),
        );
      }

      final left = rot(u, headAngle);
      final right = rot(u, -headAngle);

      canvas.drawLine(tip, tip - left * headLen, paint);
      canvas.drawLine(tip, tip - right * headLen, paint);
    }

    if (selected) {
      // rotation/move grabber at tail
      final grabPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final border = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(tail, 10, grabPaint);
      canvas.drawCircle(tail, 10, border);
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return x != oldDelegate.x ||
        y != oldDelegate.y ||
        dx != oldDelegate.dx ||
        dy != oldDelegate.dy ||
        color != oldDelegate.color ||
        selected != oldDelegate.selected;
  }
}