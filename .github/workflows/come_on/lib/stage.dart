import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const _gold = Color(0xFFFFC857);
const _pal = {
  'H': Color(0xFFFFC857),
  'S': Color(0xFFF3C6A0),
  'E': Color(0xFF1B1B1F),
  'B': Color(0xFF8AB4F8),
  'L': Color(0xFF5B6EE1),
};
// 8x10 sprite, run cycle: stride, passing, opposite stride, passing.
const _a = ['..HHHH..', '.HHHHHH.', '.SSSSES.', '.SSSSSS.', '..BBBB..', '.SBBBB..', '..BBBBS.', '..LL.LL.', '.LL...L.', 'LL....LL'];
const _b = ['..HHHH..', '.HHHHHH.', '.SSSSES.', '.SSSSSS.', '..BBBB..', '..BBBBS.', '.SBBBB..', '..LLLL..', '..LLLL..', '..L..L..'];
const _c = ['..HHHH..', '.HHHHHH.', '.SSSSES.', '.SSSSSS.', '..BBBB..', '..BBBBS.', '.SBBBB..', '..LL.LL.', '.L...LL.', 'L....LL.'];
const _frames = [_a, _b, _c, _b];

/// The line, the golden right side, "come on", and the running figure.
/// [targetX]: -1 (left end) .. 0 (center) .. 1 (right end). The figure eases to it.
class PixelStage extends StatefulWidget {
  const PixelStage({super.key, required this.targetX});
  final double targetX;
  @override
  State<PixelStage> createState() => _PixelStageState();
}

class _PixelStageState extends State<PixelStage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  late double _x = widget.targetX;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) {
      final dt = (e - _last).inMicroseconds / 1e6;
      _last = e;
      setState(() {
        _x += (widget.targetX - _x) * (1 - math.exp(-3 * dt));
        _frame = (e.inMilliseconds ~/ 120) % 4;
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF111114),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            borderRadius: BorderRadius.circular(28),
          ),
          child: CustomPaint(painter: _Painter(_x, _frame), size: Size.infinite),
        ),
      );
}

class _Painter extends CustomPainter {
  _Painter(this.x, this.frame);
  final double x;
  final int frame;

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2, ly = s.height * .66, l = 28.0, r = s.width - 28;

    // Golden glow covering the entire right side of center (from cx to s.width).
    final glow = Rect.fromLTRB(cx, 0, s.width, s.height);
    final sun = Rect.fromCircle(
      center: Offset(r, ly),
      radius: math.max(s.width - cx, s.height),
    );
    canvas.save();
    canvas.clipRect(glow);
    canvas.drawRect(
        glow,
        Paint()
          ..shader = const LinearGradient(
              colors: [Color(0x38FFC857), Color(0x52FFC857), Color(0x75FFB300)]).createShader(glow));
    canvas.drawRect(
        glow,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x48FFD36B), Color(0x18FFD36B)])
              .createShader(sun));
    canvas.restore();

    final lp = Paint()..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(l, ly), Offset(cx, ly), lp..color = const Color(0xFF6B6B73));
    canvas.drawLine(Offset(cx, ly), Offset(r, ly), lp..color = _gold);
    canvas.drawLine(Offset(cx, ly - 18), Offset(cx, ly + 18), lp..color = Colors.white70);
    canvas.drawLine(Offset(l, ly - 8), Offset(l, ly + 8), lp..color = const Color(0xFF6B6B73));
    canvas.drawLine(Offset(r, ly - 8), Offset(r, ly + 8), lp..color = _gold);

    final tp = TextPainter(
      text: const TextSpan(
          text: 'come on',
          style: TextStyle(color: _gold, fontFamily: 'monospace', fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r - tp.width, ly + 18));

    const px = 4.0;
    final sx = (cx + x * (cx - l) - 4 * px).roundToDouble();
    final sy = ly - 10 * px - 2 + (frame.isOdd ? -px : 0.0);
    canvas.drawOval(Rect.fromCenter(center: Offset(sx + 4 * px, ly - 1), width: 8 * px, height: 5),
        Paint()..color = const Color(0x55000000));
    final p = Paint()..isAntiAlias = false;
    final rows = _frames[frame];
    for (var y = 0; y < rows.length; y++) {
      for (var c = 0; c < 8; c++) {
        final col = _pal[rows[y][c]];
        if (col != null) canvas.drawRect(Rect.fromLTWH(sx + c * px, sy + y * px, px, px), p..color = col);
      }
    }
  }

  @override
  bool shouldRepaint(_Painter o) => true;
}
