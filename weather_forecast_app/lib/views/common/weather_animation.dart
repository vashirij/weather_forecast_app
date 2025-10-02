import 'package:flutter/material.dart';

enum WeatherType { sun, clouds, rain }

/// A lightweight decorative weather overlay used on auth screens.
/// It's non-interactive (IgnorePointer) and uses simple animations so
/// no extra assets or packages are required.
class WeatherAnimation extends StatefulWidget {
  final WeatherType type;
  const WeatherAnimation({Key? key, this.type = WeatherType.sun})
    : super(key: key);

  @override
  State<WeatherAnimation> createState() => _WeatherAnimationState();
}

class _WeatherAnimationState extends State<WeatherAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _move;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _move = Tween(
      begin: -0.1,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return CustomPaint(
              painter: _WeatherPainter(widget.type, _move.value),
            );
          },
        ),
      ),
    );
  }
}

class _WeatherPainter extends CustomPainter {
  final WeatherType type;
  final double t;
  _WeatherPainter(this.type, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // Draw sun (top-left)
    if (type == WeatherType.sun || type == WeatherType.clouds) {
      paint.color = Colors.orange.withOpacity(0.9);
      final sunCenter = Offset(size.width * 0.15, size.height * 0.15);
      canvas.drawCircle(sunCenter, 28, paint);
    }

    // Draw moving clouds
    paint.color = Colors.white.withOpacity(0.85);
    final cloudY = size.height * 0.2;
    final cloudX1 = size.width * (t - 0.2);
    final cloudX2 = size.width * (t - 0.5);
    _drawCloud(canvas, Offset(cloudX1, cloudY), 80, paint);
    _drawCloud(canvas, Offset(cloudX2, cloudY + 30), 60, paint);

    // Rain drops
    if (type == WeatherType.rain) {
      final dropPaint = Paint()..color = Colors.lightBlue.withOpacity(0.7);
      for (int i = 0; i < 12; i++) {
        final x = (size.width * ((t + i * 0.07) % 1.0));
        final y = size.height * (0.35 + ((t + i * 0.12) % 1.0) * 0.4);
        canvas.drawLine(Offset(x, y), Offset(x + 2, y + 10), dropPaint);
      }
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double width, Paint paint) {
    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: width * 0.6,
    );
    canvas.drawOval(rect, paint);
    canvas.drawCircle(
      center.translate(-width * 0.25, -10),
      width * 0.28,
      paint,
    );
    canvas.drawCircle(center.translate(width * 0.2, -8), width * 0.24, paint);
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter old) =>
      old.t != t || old.type != type;
}
