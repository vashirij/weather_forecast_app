import 'package:flutter/material.dart';

class SimpleLineChart extends StatelessWidget {
  final List<int> seriesA;
  final List<int> seriesB;
  final List<String> labels;
  final Color colorA;
  final Color colorB;

  const SimpleLineChart({
    super.key,
    required this.seriesA,
    required this.seriesB,
    required this.labels,
    this.colorA = Colors.red,
    this.colorB = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 140),
      painter: _SimpleLinePainter(
        seriesA: seriesA,
        seriesB: seriesB,
        labels: labels,
        colorA: colorA,
        colorB: colorB,
      ),
    );
  }
}

class _SimpleLinePainter extends CustomPainter {
  final List<int> seriesA;
  final List<int> seriesB;
  final List<String> labels;
  final Color colorA;
  final Color colorB;

  _SimpleLinePainter({
    required this.seriesA,
    required this.seriesB,
    required this.labels,
    required this.colorA,
    required this.colorB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()
      ..color = colorA
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final paintB = Paint()
      ..color = colorB
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final axis = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    final all = <int>[]
      ..addAll(seriesA)
      ..addAll(seriesB);
    if (all.isEmpty) return;
    final minV = all.reduce((a, b) => a < b ? a : b).toDouble();
    final maxV = all.reduce((a, b) => a > b ? a : b).toDouble();
    final vRange = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final left = 24.0;
    final bottom = 28.0;
    final w = size.width - left - 8;
    final h = size.height - bottom - 8;

    for (int i = 0; i <= 4; i++) {
      final y = 8 + h * (i / 4);
      canvas.drawLine(Offset(left, y), Offset(left + w, y), axis);
    }

    Offset map(int index, int value, int count) {
      final x = left + (w) * (index / (count - 1));
      final y = 8 + h * (1 - ((value - minV) / vRange));
      return Offset(x, y);
    }

    if (seriesA.isNotEmpty) {
      final pathA = Path();
      for (var i = 0; i < seriesA.length; i++) {
        final p = map(i, seriesA[i], seriesA.length);
        if (i == 0)
          pathA.moveTo(p.dx, p.dy);
        else
          pathA.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(pathA, paintA);
    }

    if (seriesB.isNotEmpty) {
      final pathB = Path();
      for (var i = 0; i < seriesB.length; i++) {
        final p = map(i, seriesB[i], seriesB.length);
        if (i == 0)
          pathB.moveTo(p.dx, p.dy);
        else
          pathB.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(pathB, paintB);
    }

    final dotA = Paint()..color = colorA;
    final dotB = Paint()..color = colorB;
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var i = 0; i < labels.length; i++) {
      final la = labels[i];
      final pA = seriesA.isNotEmpty
          ? map(i, seriesA[i], labels.length)
          : Offset.zero;
      final pB = seriesB.isNotEmpty
          ? map(i, seriesB[i], labels.length)
          : Offset.zero;
      if (seriesA.isNotEmpty) canvas.drawCircle(pA, 3, dotA);
      if (seriesB.isNotEmpty) canvas.drawCircle(pB, 3, dotB);
      tp.text = TextSpan(
        text: la,
        style: const TextStyle(color: Colors.black, fontSize: 11),
      );
      tp.layout(maxWidth: 60);
      final labelX = seriesA.isNotEmpty
          ? pA.dx
          : (seriesB.isNotEmpty ? pB.dx : left);
      tp.paint(canvas, Offset(labelX - tp.width / 2, size.height - bottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
