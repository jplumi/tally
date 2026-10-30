import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chart_slice.dart';

class PieChart extends StatelessWidget {
  const PieChart({
    super.key,
    required this.data,
    required this.nameStyle,
    required this.percentStyle,
    required this.lineColor,
  });

  final ChartData data;
  final TextStyle nameStyle;
  final TextStyle percentStyle;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth.isFinite
            ? math.min(constraints.maxWidth, 440.0)
            : 360.0;
        return SizedBox.square(
          dimension: side,
          child: CustomPaint(
            painter: _PieChartPainter(
              data: data,
              nameStyle: nameStyle,
              percentStyle: percentStyle,
              lineColor: lineColor,
            ),
          ),
        );
      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({
    required this.data,
    required this.nameStyle,
    required this.percentStyle,
    required this.lineColor,
  });

  final ChartData data;
  final TextStyle nameStyle;
  final TextStyle percentStyle;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.total <= 0 || data.slices.isEmpty) return;

    final center = size.center(Offset.zero);
    final outerRadius = math.min(size.width, size.height) * 0.28;
    final ringWidth = outerRadius * 0.36;
    final rect = Rect.fromCircle(
      center: center,
      radius: outerRadius - ringWidth / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    final separation = data.slices.length > 1 ? 0.03 : 0.0;
    var startAngle = -math.pi / 2;

    final labels = <_LabelLayout>[];

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

      labels.add(
        _layoutLabel(size, center, outerRadius, startAngle + sweep / 2, slice),
      );

      startAngle += sweep;
    }

    _resolveVerticalPositions(
      labels.where((label) => label.side < 0).toList(),
      size,
    );
    _resolveVerticalPositions(
      labels.where((label) => label.side > 0).toList(),
      size,
    );

    for (final label in labels) {
      _paintLabel(canvas, size, label);
    }
  }

  _LabelLayout _layoutLabel(
    Size size,
    Offset center,
    double outerRadius,
    double midAngle,
    ChartSlice slice,
  ) {
    final side = math.cos(midAngle) >= 0 ? 1.0 : -1.0;
    final direction = Offset(math.cos(midAngle), math.sin(midAngle));

    final radialStart = center + direction * (outerRadius + 2);
    final radialElbow = center + direction * (outerRadius + 16);

    final labelWidth = math.max(24.0, size.width / 2 - outerRadius - 32);

    final namePainter = TextPainter(
      text: TextSpan(text: slice.label, style: nameStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: labelWidth);

    final percentPainter = TextPainter(
      text: TextSpan(
        text: formatPercent(slice.value, data.total),
        style: percentStyle,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: labelWidth);

    final height = namePainter.height + 2 + percentPainter.height;

    return _LabelLayout(
      slice: slice,
      side: side,
      radialStart: radialStart,
      radialElbow: radialElbow,
      horizontalEndX: center.dx + side * (outerRadius + 28),
      labelWidth: labelWidth,
      height: height,
      desiredTop: radialElbow.dy - height / 2,
      namePainter: namePainter,
      percentPainter: percentPainter,
    );
  }

  void _resolveVerticalPositions(List<_LabelLayout> labels, Size size) {
    if (labels.isEmpty) return;

    labels.sort((a, b) => a.desiredTop.compareTo(b.desiredTop));

    const gap = 4.0;
    const margin = 4.0;
    final maxBottom = size.height - margin;

    var cursor = margin;
    for (final label in labels) {
      final maxTop = maxBottom - label.height;
      var top = label.desiredTop.clamp(margin, maxTop);
      if (top < cursor) top = cursor;
      if (top > maxTop) top = maxTop;
      label.top = top;
      cursor = top + label.height + gap;
    }

    cursor = maxBottom;
    for (var i = labels.length - 1; i >= 0; i--) {
      final label = labels[i];
      final bottom = label.top + label.height;
      if (bottom > cursor) {
        label.top = math.max(margin, cursor - label.height);
      }
      cursor = label.top - gap;
    }
  }

  void _paintLabel(Canvas canvas, Size size, _LabelLayout label) {
    final centerY = label.top + label.height / 2;
    final elbow = Offset(label.radialElbow.dx, centerY);
    final horizontalEnd = Offset(label.horizontalEndX, centerY);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = lineColor
      ..isAntiAlias = true;
    canvas.drawLine(label.radialStart, label.radialElbow, linePaint);
    canvas.drawLine(label.radialElbow, elbow, linePaint);
    canvas.drawLine(elbow, horizontalEnd, linePaint);

    final anchorX = horizontalEnd.dx + label.side * 4;
    final left = (label.side > 0 ? anchorX : anchorX - label.labelWidth)
        .clamp(4.0, math.max(4.0, size.width - label.labelWidth - 4))
        .toDouble();

    label.namePainter.paint(canvas, Offset(left, label.top));
    label.percentPainter.paint(
      canvas,
      Offset(left, label.top + label.namePainter.height + 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.nameStyle != nameStyle ||
        oldDelegate.percentStyle != percentStyle ||
        oldDelegate.lineColor != lineColor;
  }
}

class _LabelLayout {
  _LabelLayout({
    required this.slice,
    required this.side,
    required this.radialStart,
    required this.radialElbow,
    required this.horizontalEndX,
    required this.labelWidth,
    required this.height,
    required this.desiredTop,
    required this.namePainter,
    required this.percentPainter,
  });

  final ChartSlice slice;
  final double side;
  final Offset radialStart;
  final Offset radialElbow;
  final double horizontalEndX;
  final double labelWidth;
  final double height;
  final double desiredTop;
  double top = 0;
  final TextPainter namePainter;
  final TextPainter percentPainter;
}
