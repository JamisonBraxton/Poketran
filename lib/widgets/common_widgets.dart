import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/models.dart';

class PokeballMark extends StatelessWidget {
  final double size;
  final Color color;
  const PokeballMark({super.key, this.size = 42, this.color = brandYellow});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _BallPainter(color)),
  );
}

class _BallPainter extends CustomPainter {
  final Color color;
  _BallPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075;
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.45, fill);
    canvas.drawCircle(center, size.width * 0.45, stroke);
    canvas.drawLine(Offset(size.width * 0.05, center.dy),
        Offset(size.width * 0.95, center.dy), stroke);
    canvas.drawCircle(center, size.width * 0.14, Paint()..color =
        const Color(0xFF171D33));
    canvas.drawCircle(center, size.width * 0.14, stroke);
  }

  @override
  bool shouldRepaint(covariant _BallPainter old) => old.color != color;
}

class TypePill extends StatelessWidget {
  final PokeType type;
  const TypePill({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.36)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('${typeEmoji(type)}  ${type.label}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class StatusPill extends StatelessWidget {
  final TeamStatus status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TeamStatus.planned => brandYellow,
      TeamStatus.active => brandBlue,
      TeamStatus.complete => const Color(0xFF54D6AD),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(99)),
      child: Text(status.label, style: TextStyle(color: color,
          fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionLabel(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800)),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ]),
  );
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  const EmptyState({super.key, required this.title, required this.message,
      this.buttonLabel, this.onPressed});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const PokeballMark(size: 78),
      const SizedBox(height: 20),
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center),
      if (buttonLabel != null && onPressed != null) ...[
        const SizedBox(height: 18),
        FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
      ],
    ]),
  ));
}

Future<bool> askConfirm(BuildContext context, {required String title,
    required String message, String action = 'Delete'}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
      ],
    ),
  );
  return result ?? false;
}

void showAppError(BuildContext context, Object error) {
  final message = error is ValidationException ? error.message :
      'Something went wrong. ${error.toString()}';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String shortDate(int millis) {
  final d = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${d.month}/${d.day}/${d.year}';
}
