import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';

typedef StackBoardWidgetBuilder = Widget Function(
  BuildContext context,
  bool selected,
  Map<String, dynamic> data,
  ValueChanged<Map<String, dynamic>> updateData,
);

enum StackBoardPlacement { topLeft, topRight, bottomLeft, bottomRight, center }

class StackBoardTemplate {
  const StackBoardTemplate({
    required this.templateId,
    required this.label,
    required this.builder,
    this.defaultSize = const Size(120, 56),
    this.defaultAllowOverlap = true,
    this.defaultDraggable = true,
    this.defaultData = const <String, dynamic>{},
    this.dataToJson,
    this.dataFromJson,
  });

  final String templateId;
  final String label;
  final Size defaultSize;
  final StackBoardWidgetBuilder builder;
  final bool defaultAllowOverlap;
  final bool defaultDraggable;
  final Map<String, dynamic> defaultData;
  final Map<String, dynamic> Function(Map<String, dynamic> data)? dataToJson;
  final Map<String, dynamic> Function(Map<String, dynamic> json)? dataFromJson;

  StackBoardItem createItem({
    required int id,
    Size? boardSize,
    Offset? initialPosition,
    StackBoardPlacement? placement,
    EdgeInsets placementMargin = EdgeInsets.zero,
    Size? size,
    bool? allowOverlap,
    bool? draggable,
  }) {
    final resolvedSize = size ?? defaultSize;
    final p = initialPosition ?? _resolvePlacementOffset(boardSize: boardSize, size: resolvedSize, placement: placement ?? StackBoardPlacement.topLeft, margin: placementMargin);
    return StackBoardItem(
      id: id,
      template: this,
      rect: Rect.fromLTWH(p.dx, p.dy, resolvedSize.width, resolvedSize.height),
      allowOverlap: allowOverlap ?? defaultAllowOverlap,
      draggable: draggable ?? defaultDraggable,
      data: Map<String, dynamic>.from(defaultData),
    );
  }

  Offset _resolvePlacementOffset({required Size? boardSize, required Size size, required StackBoardPlacement placement, required EdgeInsets margin}) {
    if (boardSize == null || boardSize.width <= 0 || boardSize.height <= 0) {
      return Offset(margin.left, margin.top);
    }
    final maxX = (boardSize.width - size.width - margin.right).clamp(0.0, double.infinity);
    final maxY = (boardSize.height - size.height - margin.bottom).clamp(0.0, double.infinity);
    switch (placement) {
      case StackBoardPlacement.topLeft:
        return Offset(margin.left, margin.top);
      case StackBoardPlacement.topRight:
        return Offset(maxX, margin.top);
      case StackBoardPlacement.bottomLeft:
        return Offset(margin.left, maxY);
      case StackBoardPlacement.bottomRight:
        return Offset(maxX, maxY);
      case StackBoardPlacement.center:
        final dx = ((boardSize.width - size.width) / 2).clamp(0.0, maxX);
        final dy = ((boardSize.height - size.height) / 2).clamp(0.0, maxY);
        return Offset(dx, dy);
    }
  }
}

class StackBoardController extends ChangeNotifier {
  StackBoardController({List<StackBoardItem>? initialItems, int seed = 0}) : _items = List<StackBoardItem>.from(initialItems ?? const []), _idSeed = seed;

  final List<StackBoardItem> _items;
  final Map<String, StackBoardTemplate> _registeredTemplates = <String, StackBoardTemplate>{};
  int _idSeed;
  int? _selectedId;
  Size _boardSize = Size.zero;

  List<StackBoardItem> get items => List<StackBoardItem>.unmodifiable(_items);

  int? get selectedId => _selectedId;

  Size get boardSize => _boardSize;

  void setBoardSize(Size size) {
    if (_boardSize == size) return;
    _boardSize = size;
  }

  void select(int? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  void replaceItems(List<StackBoardItem> nextItems) {
    _items
      ..clear()
      ..addAll(nextItems);
    notifyListeners();
  }

  StackBoardItem addFromTemplate(
    StackBoardTemplate template, {
    StackBoardPlacement placement = StackBoardPlacement.topLeft,
    Offset? initialPosition,
    EdgeInsets placementMargin = EdgeInsets.zero,
    bool? allowOverlap,
    bool? draggable,
    Size? size,
  }) {
    final item = template.createItem(
      id: ++_idSeed,
      boardSize: _boardSize,
      placement: placement,
      initialPosition: initialPosition,
      placementMargin: placementMargin,
      allowOverlap: allowOverlap,
      draggable: draggable,
      size: size,
    );
    _items.add(item);
    _selectedId = item.id;
    notifyListeners();
    return item;
  }

  void removeSelected() {
    if (_selectedId == null) return;
    _items.removeWhere((e) => e.id == _selectedId);
    _selectedId = null;
    notifyListeners();
  }

  void registerTemplate(StackBoardTemplate template) {
    _registeredTemplates[template.templateId] = template;
  }

  void registerTemplates(Iterable<StackBoardTemplate> templates) {
    for (final t in templates) {
      _registeredTemplates[t.templateId] = t;
    }
  }

  String toJsonString() {
    final payload = <String, dynamic>{
      'version': 1,
      'selectedId': _selectedId,
      'items': [
        for (final item in _items)
          {
            'id': item.id,
            'templateId': item.template.templateId,
            'x': item.rect.left,
            'y': item.rect.top,
            'width': item.rect.width,
            'height': item.rect.height,
            'allowOverlap': item.allowOverlap,
            'draggable': item.draggable,
            'data': item.template.dataToJson?.call(item.data) ?? item.data,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  void restoreFromJsonString(
    String jsonString, {
    Map<String, StackBoardTemplate> templatesById = const {},
    StackBoardTemplate? Function(String templateId, Map<String, dynamic> rawItem)? templateResolver,
  }) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON root must be an object');
    }
    final rawItems = decoded['items'];
    if (rawItems is! List) {
      throw const FormatException('`items` must be a list');
    }

    final restored = <StackBoardItem>[];
    var maxId = _idSeed;
    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) continue;
      final templateId = raw['templateId']?.toString();
      if (templateId == null) continue;
      StackBoardTemplate? template =
          templatesById[templateId] ?? _registeredTemplates[templateId];
      if (template == null && templateResolver != null) {
        template = templateResolver(templateId, raw);
        if (template != null) {
          _registeredTemplates[template.templateId] = template;
        }
      }
      if (template == null) continue;

      final id = (raw['id'] as num?)?.toInt() ?? (++maxId);
      final x = (raw['x'] as num?)?.toDouble() ?? 0;
      final y = (raw['y'] as num?)?.toDouble() ?? 0;
      final width = (raw['width'] as num?)?.toDouble() ?? template.defaultSize.width;
      final height = (raw['height'] as num?)?.toDouble() ?? template.defaultSize.height;
      final allowOverlap = (raw['allowOverlap'] as bool?) ?? template.defaultAllowOverlap;
      final draggable = (raw['draggable'] as bool?) ?? template.defaultDraggable;
      final rawData = raw['data'];
      final parsedData = rawData is Map<String, dynamic>
          ? rawData
          : rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : template.defaultData;
      final restoredData = template.dataFromJson?.call(parsedData) ?? parsedData;

      restored.add(
        StackBoardItem(
          id: id,
          template: template,
          rect: Rect.fromLTWH(x, y, width, height),
          allowOverlap: allowOverlap,
          draggable: draggable,
          data: Map<String, dynamic>.from(restoredData),
        ),
      );
      if (id > maxId) maxId = id;
    }

    _idSeed = maxId;
    _items
      ..clear()
      ..addAll(restored);
    final selected = (decoded['selectedId'] as num?)?.toInt();
    _selectedId = restored.any((e) => e.id == selected) ? selected : null;
    notifyListeners();
  }
}

class StackBoard extends StatefulWidget {
  const StackBoard({
    super.key,
    required this.controller,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.outerGap = 8,
    this.dragStateExitDelay = const Duration(seconds: 1),
    this.pointerEventsThrough = false,
    this.pointerEventsThroughEmptyOnly = false,
    this.keepEdgeAnchoredOnResize = false,
  });

  final StackBoardController controller;
  final Color backgroundColor;
  final double outerGap;
  final Duration dragStateExitDelay;
  final bool pointerEventsThrough;
  final bool pointerEventsThroughEmptyOnly;
  /// When enabled, items touching right/bottom edge stay attached there
  /// after board size changes.
  final bool keepEdgeAnchoredOnResize;

  @override
  State<StackBoard> createState() => _StackBoardState();
}

class StackBoardItem {
  const StackBoardItem({
    required this.id,
    required this.template,
    required this.rect,
    required this.allowOverlap,
    required this.draggable,
    required this.data,
  });

  final int id;
  final StackBoardTemplate template;
  final Rect rect;
  final bool allowOverlap;
  final bool draggable;
  final Map<String, dynamic> data;

  StackBoardItem copyWith({
    Rect? rect,
    bool? allowOverlap,
    bool? draggable,
    Map<String, dynamic>? data,
  }) {
    return StackBoardItem(
      id: id,
      template: template,
      rect: rect ?? this.rect,
      allowOverlap: allowOverlap ?? this.allowOverlap,
      draggable: draggable ?? this.draggable,
      data: data ?? this.data,
    );
  }
}

class _StackBoardState extends State<StackBoard> {
  Size _boardSize = Size.zero;
  int? _draggingItemId;
  Rect? _dragStartRect;
  Timer? _dragEndTimer;
  Size _lastLayoutBoardSize = Size.zero;

  @override
  void dispose() {
    _dragEndTimer?.cancel();
    super.dispose();
  }

  Rect _clampRect(Rect rect) {
    if (_boardSize.width <= 0 || _boardSize.height <= 0) return rect;
    final width = rect.width.clamp(40.0, _boardSize.width);
    final height = rect.height.clamp(40.0, _boardSize.height);
    final maxX = (_boardSize.width - width - 1).clamp(0.0, double.infinity);
    final maxY = (_boardSize.height - height - 1).clamp(0.0, double.infinity);
    final left = rect.left.clamp(0.0, maxX);
    final top = rect.top.clamp(0.0, maxY);
    return Rect.fromLTWH(left, top, width, height);
  }

  void _scheduleRelayoutClampIfNeeded(Size oldSize, Size newSize) {
    final currentItems = widget.controller.items;
    if (currentItems.isEmpty) return;
    var changed = false;
    final adjusted = <StackBoardItem>[];
    const edgeEpsilon = 1.5;
    for (final item in currentItems) {
      Rect nextRect = item.rect;
      if (widget.keepEdgeAnchoredOnResize &&
          oldSize.width > 0 &&
          oldSize.height > 0) {
        final wasAtRight = (oldSize.width - item.rect.right).abs() <= edgeEpsilon;
        final wasAtBottom = (oldSize.height - item.rect.bottom).abs() <= edgeEpsilon;
        if (wasAtRight) {
          nextRect = nextRect.shift(
            Offset((newSize.width - nextRect.width) - nextRect.left, 0),
          );
        }
        if (wasAtBottom) {
          nextRect = nextRect.shift(
            Offset(0, (newSize.height - nextRect.height) - nextRect.top),
          );
        }
      }
      final clamped = _clampRect(nextRect);
      if (clamped != item.rect) changed = true;
      adjusted.add(item.copyWith(rect: clamped));
    }
    if (!changed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.replaceItems(adjusted);
    });
  }

  bool _isOverlappingAny(Rect rect, StackBoardItem moving, List<StackBoardItem> items) {
    for (final other in items) {
      if (other.id == moving.id) continue;
      if (moving.allowOverlap && other.allowOverlap) continue;
      if (rect.overlaps(other.rect)) return true;
    }
    return false;
  }

  Rect _resolveRectForItem(StackBoardItem item, Rect candidate, List<StackBoardItem> items) {
    final clamped = _clampRect(candidate);
    if (_isOverlappingAny(clamped, item, items)) return item.rect;
    return clamped;
  }

  void _moveItemByDelta(int itemId, Offset delta) {
    final items = widget.controller.items.toList(growable: false);
    final index = items.indexWhere((e) => e.id == itemId);
    if (index < 0) return;
    final item = items[index];
    final nextRect = _resolveRectForItem(item, item.rect.shift(delta), items);
    final nextItems = items.toList(growable: true);
    nextItems[index] = item.copyWith(rect: nextRect);
    widget.controller.select(itemId);
    widget.controller.replaceItems(nextItems);
  }

  void _moveItemFromDragStart(int itemId, Offset offsetFromOrigin) {
    final startRect = _dragStartRect;
    if (_draggingItemId != itemId || startRect == null) return;
    final items = widget.controller.items.toList(growable: false);
    final index = items.indexWhere((e) => e.id == itemId);
    if (index < 0) return;
    final item = items[index];
    final nextRect = _resolveRectForItem(item, startRect.shift(offsetFromOrigin), items);
    final nextItems = items.toList(growable: true);
    nextItems[index] = item.copyWith(rect: nextRect);
    widget.controller.select(itemId);
    widget.controller.replaceItems(nextItems);
  }

  void _updateItemData(int itemId, Map<String, dynamic> nextData) {
    final items = widget.controller.items.toList(growable: false);
    final index = items.indexWhere((e) => e.id == itemId);
    if (index < 0) return;
    final item = items[index];
    final nextItems = items.toList(growable: true);
    nextItems[index] = item.copyWith(
      data: Map<String, dynamic>.from(nextData),
    );
    widget.controller.replaceItems(nextItems);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pointerEventsThrough) {
      return IgnorePointer(
        ignoring: true,
        child: _buildBoard(),
      );
    }
    return _buildBoard();
  }

  Widget _buildBoard() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final boardWidth = (constraints.maxWidth - (widget.outerGap * 2)).clamp(0.0, double.infinity);
          final boardHeight = (constraints.maxHeight - (widget.outerGap * 2)).clamp(0.0, double.infinity);
          _boardSize = Size(boardWidth, boardHeight);
          if (_boardSize != _lastLayoutBoardSize) {
            final oldSize = _lastLayoutBoardSize;
            _lastLayoutBoardSize = _boardSize;
            _scheduleRelayoutClampIfNeeded(oldSize, _boardSize);
          }
          widget.controller.setBoardSize(_boardSize);
          return Padding(
            padding: EdgeInsets.all(widget.outerGap),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: widget.pointerEventsThroughEmptyOnly,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.backgroundColor,
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                  ),
                ),
                for (final item in widget.controller.items)
                  Positioned(
                    left: item.rect.left,
                    top: item.rect.top,
                    width: item.rect.width,
                    height: item.rect.height,
                    child: Listener(
                      onPointerDown: (_) => widget.controller.select(item.id),
                      child: GestureDetector(
                        onLongPressStart: item.draggable
                            ? (_) {
                                _dragEndTimer?.cancel();
                                _draggingItemId = item.id;
                                _dragStartRect = item.rect;
                                widget.controller.select(item.id);
                              }
                            : null,
                        onPanStart: item.draggable && _draggingItemId == item.id
                            ? (_) {
                                _dragEndTimer?.cancel();
                              }
                            : null,
                        onPanUpdate: item.draggable && _draggingItemId == item.id ? (details) => _moveItemByDelta(item.id, details.delta) : null,
                        onPanEnd: item.draggable && _draggingItemId == item.id
                            ? (_) {
                                final endedId = item.id;
                                _dragEndTimer?.cancel();
                                _dragEndTimer = Timer(widget.dragStateExitDelay, () {
                                  if (!mounted) return;
                                  if (_draggingItemId == endedId) {
                                    setState(() {
                                      _draggingItemId = null;
                                    });
                                  }
                                });
                              }
                            : null,
                        onLongPressMoveUpdate: item.draggable ? (details) => _moveItemFromDragStart(item.id, details.offsetFromOrigin) : null,
                        onLongPressEnd: item.draggable
                            ? (_) {
                                final endedId = item.id;
                                _dragStartRect = null;
                                _dragEndTimer?.cancel();
                                _dragEndTimer = Timer(widget.dragStateExitDelay, () {
                                  if (!mounted) return;
                                  if (_draggingItemId == endedId) {
                                    setState(() {
                                      _draggingItemId = null;
                                    });
                                  }
                                });
                              }
                            : null,
                        child: item.template.builder(
                          context,
                          item.id == widget.controller.selectedId,
                          item.data,
                          (nextData) => _updateItemData(item.id, nextData),
                        ),
                      ),
                    ),
                  ),
                for (final item in widget.controller.items)
                  if (item.id == widget.controller.selectedId || item.id == _draggingItemId)
                    Positioned(
                      left: item.rect.left - 1,
                      top: item.rect.top - 1,
                      width: item.rect.width + 2,
                      height: item.rect.height + 2,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: _draggingItemId == item.id ? Colors.deepOrange : Colors.blue, width: _draggingItemId == item.id ? 3 : 2),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
