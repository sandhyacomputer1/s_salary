// lib/features/employee/expense_claims/widgets/expense_claim_summary_strip.dart

import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../utils/expense_colors.dart';

/// One small card in the strip.
class ExpenseSummaryItem {
  final String label;
  final double amount;
  final int count;
  final IconData icon;
  final Color color;

  const ExpenseSummaryItem({
    required this.label,
    required this.amount,
    required this.count,
    required this.icon,
    required this.color,
  });
}

/// 55555 -> ₹55,555 | 4454500 -> ₹44,54,500 | 1250.5 -> ₹1,250.50
String formatInrAmount(double amount) {
  final isNegative = amount < 0;
  final abs = amount.abs();

  final hasPaise = (abs - abs.truncateToDouble()).abs() > 0.004;
  final fixed = abs.toStringAsFixed(hasPaise ? 2 : 0);
  final parts = fixed.split('.');
  final whole = parts[0];

  String grouped;
  if (whole.length <= 3) {
    grouped = whole;
  } else {
    final last3 = whole.substring(whole.length - 3);
    var rest = whole.substring(0, whole.length - 3);
    final chunks = <String>[];
    while (rest.length > 2) {
      chunks.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) chunks.insert(0, rest);
    grouped = '${chunks.join(',')},$last3';
  }

  final decimals = parts.length > 1 ? '.${parts[1]}' : '';
  return '${isNegative ? '-' : ''}₹$grouped$decimals';
}

/// Compact summary cards in ONE horizontal line.
///
/// - If all cards fit the width (web), they share the row evenly.
/// - If not (phone), the row scrolls sideways and moves by itself.
///   Touching / dragging pauses the auto scroll for a few seconds.
class ExpenseClaimSummaryStrip extends StatefulWidget {
  final List<ExpenseSummaryItem> items;

  /// Time between automatic moves.
  final Duration interval;

  const ExpenseClaimSummaryStrip({
    super.key,
    required this.items,
    this.interval = const Duration(seconds: 3),
  });

  @override
  State<ExpenseClaimSummaryStrip> createState() =>
      _ExpenseClaimSummaryStripState();
}

class _ExpenseClaimSummaryStripState extends State<ExpenseClaimSummaryStrip> {
  static const double _minCardWidth = 172;
  static const double _scrollCardWidth = 168;
  static const double _gap = 10;
  static const double _height = 84;

  final ScrollController _controller = ScrollController();
  Timer? _timer;
  DateTime _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _pause() {
    _pausedUntil = DateTime.now().add(const Duration(seconds: 6));
  }

  void _tick() {
    if (!mounted || !_controller.hasClients) return;
    if (DateTime.now().isBefore(_pausedUntil)) return;

    final max = _controller.position.maxScrollExtent;
    if (max <= 0) return; // everything fits, nothing to scroll

    final step = _scrollCardWidth + _gap;

    double target;
    if (_controller.offset >= max - 1) {
      target = 0; // back to the start
    } else {
      target = (_controller.offset + step).clamp(0.0, max);
    }

    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final minTotal =
            items.length * _minCardWidth + (items.length - 1) * _gap;

        // Everything fits: even row, no scrolling.
        if (minTotal <= width) {
          return SizedBox(
            height: _height,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(child: _Card(item: items[i])),
                ],
              ],
            ),
          );
        }

        // Does not fit: one scrolling line that moves by itself.
        return SizedBox(
          height: _height,
          child: Listener(
            onPointerDown: (_) => _pause(),
            onPointerSignal: (_) => _pause(),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
                scrollbars: false,
              ),
              child: ListView.separated(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: _gap),
                itemBuilder: (_, i) => SizedBox(
                  width: _scrollCardWidth,
                  child: _Card(item: items[i]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final ExpenseSummaryItem item;
  const _Card({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ExpenseColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ExpenseColors.border),
        boxShadow: ExpenseColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: ExpenseColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatInrAmount(item.amount),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: item.color,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.count == 1 ? '1 claim' : '${item.count} claims',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: ExpenseColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}