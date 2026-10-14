import 'package:flutter/material.dart';

const Color _kTextDark = Color(0xFF18212F);

/// "Page 1 of 21" on the left, "← Previous" and "Next →" on the right.
class AuditPagination extends StatelessWidget {
  const AuditPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    required this.busy,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;

  /// null when the backend response carries no page count.
  final int? totalPages;

  final bool hasPrevious;
  final bool hasNext;

  /// True while a request is running; disables both buttons so a page can't
  /// be requested twice.
  final bool busy;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label =
    totalPages == null ? 'Page $page' : 'Page $page of $totalPages';

    ButtonStyle style() => OutlinedButton.styleFrom(
      foregroundColor: _kTextDark,
      side: const BorderSide(color: Color(0xFFD9DEE7)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
            ),
          ),
          OutlinedButton(
            onPressed: (!hasPrevious || busy) ? null : onPrevious,
            style: style(),
            child: const Text('← Previous'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: (!hasNext || busy) ? null : onNext,
            style: style(),
            child: const Text('Next →'),
          ),
        ],
      ),
    );
  }
}