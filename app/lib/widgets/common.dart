import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// 琥珀渐变主按钮（设计文档 4.3：按压 scale 0.97）
class YPrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool danger;
  const YPrimaryButton({super.key, required this.label, this.icon, this.onPressed, this.danger = false});

  @override
  State<YPrimaryButton> createState() => _YPrimaryButtonState();
}

class _YPrimaryButtonState extends State<YPrimaryButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final colors = widget.danger
        ? const [Color(0xFFF87171), Color(0xFFDC2626)]
        : const [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)];
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (widget.danger ? Y.error : Y.primary).withOpacity(.45),
                blurRadius: 28, offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Opacity(
            opacity: widget.onPressed == null ? .45 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 19, color: Y.onPrimary), const SizedBox(width: 8)],
                Text(widget.label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Y.onPrimary, letterSpacing: .5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 统一卡片
class YCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  const YCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Y.rCard),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [color ?? Y.surfaceContainer, const Color(0xFF1B2431)],
            ),
            border: Border.all(color: Y.outline),
            borderRadius: BorderRadius.circular(Y.rCard),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 小字标签（caps）
class YCaps extends StatelessWidget {
  final String text;
  const YCaps(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: YText.labelCaps);
}

/// 确认弹窗（危险操作红色）
Future<bool> yConfirm(BuildContext context, {required String title, required String body, bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body, style: const TextStyle(color: Y.onSurface2, height: 1.6)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? Y.error : Y.primary, foregroundColor: Y.onPrimary),
          onPressed: () => Navigator.pop(c, true),
          child: const Text('确认'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
