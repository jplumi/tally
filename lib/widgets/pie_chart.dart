import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chart_slice.dart';
import '../utils/currency_formatter.dart';

const double _outerRadiusFactor = 0.42;
const double _ringWidthFactor = 0.36;

class PieChart extends StatefulWidget {
  const PieChart({super.key, required this.data});

  final ChartData data;

  @override
  State<PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<PieChart> {
  OverlayEntry? _tooltip;
  Timer? _tooltipTimer;

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  void _hideTooltip() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _tooltip?.remove();
    _tooltip = null;
  }

  void _showTooltip(ChartSlice slice, Offset globalPosition) {
    _hideTooltip();
    _tooltip = OverlayEntry(
      builder: (context) => _SliceTooltip(
        slice: slice,
        total: widget.data.total,
        target: globalPosition,
      ),
    );
    Overlay.of(context).insert(_tooltip!);
    _tooltipTimer = Timer(const Duration(seconds: 3), _hideTooltip);
  }

  ChartSlice? _sliceAt(Offset position, Size size) {
    final data = widget.data;
    if (data.total <= 0 || data.slices.isEmpty) return null;

    final geometry = _PieGeometry.of(size);
    if (!geometry.containsPoint(position)) return null;

    if (data.slices.length == 1) return data.slices.first;

    final angle = math.atan2(
      position.dy - geometry.center.dy,
      position.dx - geometry.center.dx,
    );
    var normalized = angle + math.pi / 2;
    if (normalized < 0) normalized += 2 * math.pi;

    var start = 0.0;
    for (final slice in data.slices) {
      final sweep = slice.value / data.total * 2 * math.pi;
      if (sweep <= 0) continue;
      if (normalized >= start && normalized < start + sweep) return slice;
      start += sweep;
    }

    return data.slices.last;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth.isFinite
            ? math.min(constraints.maxWidth, 520.0)
            : 440.0;
        return SizedBox.square(
          dimension: side,
          child: GestureDetector(
            onTapUp: (details) {
              final slice = _sliceAt(details.localPosition, Size.square(side));
              if (slice == null) {
                _hideTooltip();
              } else {
                _showTooltip(slice, details.globalPosition);
              }
            },
            child: CustomPaint(
              painter: _PieChartPainter(data: widget.data),
            ),
          ),
        );
      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({required this.data});

  final ChartData data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.total <= 0 || data.slices.isEmpty) return;

    final geometry = _PieGeometry.of(size);
    final rect = Rect.fromCircle(
      center: geometry.center,
      radius: geometry.midRadius,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = geometry.ringWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    final separation = data.slices.length > 1 ? 0.03 : 0.0;
    var startAngle = -math.pi / 2;

    for (final slice in data.slices) {
      final sweep = slice.value / data.total * 2 * math.pi;
      if (sweep <= 0) continue;

      paint.color = slice.color;

      if (sweep >= 2 * math.pi - 0.0001) {
        canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      } else {
        final drawSweep = sweep > separation ? sweep - separation : sweep;
        final drawStart = startAngle + (sweep - drawSweep) / 2;
        canvas.drawArc(rect, drawStart, drawSweep, false, paint);
      }

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _PieGeometry {
  const _PieGeometry({
    required this.center,
    required this.outerRadius,
    required this.ringWidth,
  });

  factory _PieGeometry.of(Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = math.min(size.width, size.height) * _outerRadiusFactor;
    final ringWidth = outerRadius * _ringWidthFactor;
    return _PieGeometry(
      center: center,
      outerRadius: outerRadius,
      ringWidth: ringWidth,
    );
  }

  final Offset center;
  final double outerRadius;
  final double ringWidth;

  double get innerRadius => outerRadius - ringWidth;
  double get midRadius => outerRadius - ringWidth / 2;

  bool containsPoint(Offset point) {
    final distance = (point - center).distance;
    return distance >= innerRadius && distance <= outerRadius;
  }
}

class _SliceTooltip extends StatefulWidget {
  const _SliceTooltip({
    required this.slice,
    required this.total,
    required this.target,
  });

  final ChartSlice slice;
  final double total;
  final Offset target;

  @override
  State<_SliceTooltip> createState() => _SliceTooltipState();
}

class _SliceTooltipState extends State<_SliceTooltip> {
  final GlobalKey _key = GlobalKey();
  late Offset _position;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _position = widget.target;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final size = box.size;
    final screen = MediaQuery.sizeOf(context);
    const margin = 12.0;
    const gap = 12.0;

    var left = widget.target.dx - size.width / 2;
    var top = widget.target.dy - size.height - gap;
    if (top < margin) {
      top = widget.target.dy + gap;
    }

    left = left.clamp(margin, math.max(margin, screen.width - size.width - margin));
    top = top.clamp(margin, math.max(margin, screen.height - size.height - margin));

    setState(() {
      _position = Offset(left, top);
      _visible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: IgnorePointer(
        child: Opacity(
          opacity: _visible ? 1 : 0,
          child: Container(
            key: _key,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.slice.label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPercent(widget.slice.value, widget.total),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatBRL(widget.slice.value),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onInverseSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
