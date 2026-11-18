import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const _gold = Color(0xFFFFC857);

/// Full-bleed stage. Progress retains its original -1 .. 1 coordinates.
class PixelStage extends StatefulWidget {
  const PixelStage({super.key, required this.targetX});
  final double targetX;
  @override
  State<PixelStage> createState() => _PixelStageState();
}

class _PixelStageState extends State<PixelStage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final _Scene _scene;
  Duration? _last;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _scene = _Scene(widget.targetX);
    _ticker = createTicker((elapsed) {
      final dt = _last == null
          ? 0.0
          : ((elapsed - _last!).inMicroseconds / 1e6).clamp(0.0, .05).toDouble();
      _last = elapsed;
      _scene.advance(dt, widget.targetX);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    final active = TickerMode.of(context) && !_reducedMotion;
    _last = null;
    if (active && !_ticker.isActive) _ticker.start();
    if (!active && _ticker.isActive) _ticker.stop();
    if (_reducedMotion) _scene.jump(widget.targetX);
  }

  @override
  void didUpdateWidget(covariant PixelStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_reducedMotion) _scene.jump(widget.targetX);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: SizedBox.expand(
          child: CustomPaint(painter: _StagePainter(_scene)),
        ),
      );
}

class _Scene extends ChangeNotifier {
  _Scene(this.x);
  double x;
  double time = 0;
  double motion = 0;
  void advance(double dt, double target) {
    final delta = target.clamp(-1.0, 1.0) - x;
    x += delta * (1 - math.exp(-3 * dt));
    motion += ((delta.abs() * 25).clamp(0.0, 1.0) - motion) *
        (1 - math.exp(-6 * dt));
    time += dt;
    notifyListeners();
  }
  void jump(double target) {
    x = target.clamp(-1.0, 1.0).toDouble();
    motion = 0;
    notifyListeners();
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter(this.scene) : super(repaint: scene);
  final _Scene scene;
  static final _seeds = List.generate(110, (i) {
    final random = math.Random(i * 7919 + 23);
    return List.generate(5, (_) => random.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final mid = w / 2, y = h / 2, t = scene.time;
    canvas.drawColor(const Color(0xFF0B0C10), BlendMode.src);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final right = Rect.fromLTRB(mid, 0, w, h);
    canvas.save();
    canvas.clipRect(right);
    canvas.drawRect(right, Paint()..shader = LinearGradient(
      begin: Alignment(-1, math.sin(t * .17) * .4),
      end: Alignment(1, math.cos(t * .13) * .6),
      colors: const [Color(0x0025190A), Color(0x503E290E), Color(0x806C4517)],
    ).createShader(right));
    for (var i = 0; i < 3; i++) {
      final center = Offset(mid + mid * (.45 + .35 * math.sin(t * .12 + i * 2)),
          h * (.5 + .3 * math.cos(t * .15 + i * 2)));
      final halo = Rect.fromCircle(center: center, radius: math.max(mid, h * .55));
      canvas.drawRect(right, Paint()..shader = RadialGradient(
        colors: [const Color(0xFFFFBE47).withOpacity(.09), const Color(0x00FFBE47)],
      ).createShader(halo));
    }
    // Continuous paths with soft edge fades: no visible wrap or reset.
    for (final seed in _seeds) {
      final phase = (seed[0] + t * (.018 + seed[2] * .024)) % 1;
      final px = mid + phase * mid;
      final py = ((seed[1] * h - t * (5 + seed[3] * 9) +
          math.sin(phase * 6.28 + t * .35 + seed[4] * 6.28) * 18) % h);
      final fade = math.sin(phase * math.pi) *
          (py / 35).clamp(0.0, 1.0) * ((h - py) / 35).clamp(0.0, 1.0);
      final radius = .65 + seed[2] * 1.65;
      final p = Paint()..color = _gold.withOpacity(fade * .10);
      canvas.drawCircle(Offset(px, py), radius * 3, p);
      p.color = Color.lerp(_gold, const Color(0xFFFFF1C4), seed[4])!
          .withOpacity(fade * (.25 + seed[3] * .55));
      canvas.drawCircle(Offset(px, py), radius, p);
    }
    canvas.restore();

    final inset = (w * .055).clamp(30.0, 64.0).toDouble();
    final end = w - inset;
    final line = Paint()..strokeWidth = 2..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(inset, y), Offset(mid, y), line..color = const Color(0xFF555B6A));
    canvas.drawLine(Offset(mid, y), Offset(end, y), line..color = _gold.withOpacity(.08)..strokeWidth = 12);
    canvas.drawLine(Offset(mid, y), Offset(end, y), line..color = _gold..strokeWidth = 2);
    for (final point in [inset, mid, end]) {
      final half = point == mid ? 13.0 : 6.0;
      canvas.drawLine(Offset(point, y - half), Offset(point, y + half),
          line..color = point < mid ? const Color(0xFF555B6A) : _gold);
    }
    final label = TextPainter(text: const TextSpan(text: 'come on',
      style: TextStyle(color: _gold, fontSize: 14, letterSpacing: 3,
          fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr)..layout();
    label.paint(canvas, Offset(end - label.width, y + 22));
    label.dispose();
    _runner(canvas, Offset(mid + scene.x * (mid - inset), y), t);
    canvas.restore();
  }

  void _runner(Canvas canvas, Offset foot, double time) {
    final run = scene.motion;
    final stride = math.sin(time * 10) * run;
    final breath = math.sin(time * 2.4) * (1 - run);
    final bob = math.sin(time * 20).abs() * 2 * run + breath * .7;
    canvas.save();
    canvas.translate(foot.dx, foot.dy);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 1), width: 30, height: 5),
        Paint()..color = const Color(0x70000000));
    canvas.translate(0, -bob);
    final p = Paint()..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    void limb(List<Offset> points, Color color, double width) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) { path.lineTo(point.dx, point.dy); }
      canvas.drawPath(path, p..style = PaintingStyle.stroke..color = color..strokeWidth = width);
      p.style = PaintingStyle.fill;
    }
    limb([const Offset(-3, -27), Offset(-5 - stride * 8, -15), Offset(-6 - stride * 13, -3)], const Color(0xFF334C79), 7);
    limb([const Offset(3, -27), Offset(6 + stride * 8, -15), Offset(5 + stride * 13, -3)], const Color(0xFF678AC1), 7);
    limb([Offset(-7 - stride * 13, -2), Offset(-1 - stride * 13, -2)], const Color(0xFFD5DFEF), 4);
    limb([Offset(4 + stride * 13, -2), Offset(11 + stride * 13, -2)], const Color(0xFFF0F3FA), 4);
    limb([const Offset(-5, -44), Offset(-11 + stride * 7, -34), Offset(-8 + stride * 11, -27)], const Color(0xFFC18D68), 5);
    final torso = RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -49, 20, 25), const Radius.circular(7));
    canvas.drawRRect(torso, Paint()..shader = const LinearGradient(
        colors: [Color(0xFF3C74AE), Color(0xFF9DD5FF)])
        .createShader(torso.outerRect));
    limb([const Offset(6, -44), Offset(12 - stride * 7, -35), Offset(15 - stride * 11, -30)], const Color(0xFFF1BE95), 5);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -54, 8, 9), const Radius.circular(3)), p..color = const Color(0xFFDEA780));
    canvas.drawOval(const Rect.fromLTWH(-9, -72, 22, 23), Paint()..shader = const LinearGradient(
      colors: [Color(0xFFE0AA7E), Color(0xFFFFDAB7)])
      .createShader(const Rect.fromLTWH(-9, -72, 22, 23)));
    final hair = Path()..moveTo(-10, -59)..cubicTo(-15, -78, 8, -80, 14, -68)
      ..lineTo(5, -66)..lineTo(-2, -69)..lineTo(-6, -58)..close();
    canvas.drawPath(hair, p..color = const Color(0xFFDFAB45));
    canvas.drawCircle(const Offset(-5, -59), 3, p..color = const Color(0xFFF1BE95));
    final blink = time % 4.6 > 4.43;
    canvas.drawOval(Rect.fromCenter(center: const Offset(8, -61), width: 2.4, height: blink ? .8 : 3.4), p..color = const Color(0xFF242835));
    limb([const Offset(7, -55), const Offset(10, -55.5)], const Color(0xFFAC6B53), 1.2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StagePainter oldDelegate) => oldDelegate.scene != scene;
}
