import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/audit_log_model.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kFieldBorder = Color(0xFFD9DEE7);

/// Search box + "All Event Actions" + "All Statuses" + orange Search button.
///
/// Pressing Search, pressing Enter, or changing a dropdown calls [onSearch]
/// with the current values. The parent resets to page 1 and fetches.
/// Nothing is sent per keystroke.
class AuditFilterBar extends StatefulWidget {
  const AuditFilterBar({
    super.key,
    required this.search,
    required this.action,
    required this.status,
    required this.busy,
    required this.onSearch,
  });

  /// The filters currently applied by the parent (kept in sync when the
  /// parent clears them).
  final String search;
  final String action;
  final String status;

  /// True while a request is running; blocks duplicate submissions.
  final bool busy;

  final void Function(String search, String action, String status) onSearch;

  @override
  State<AuditFilterBar> createState() => _AuditFilterBarState();
}

class _AuditFilterBarState extends State<AuditFilterBar> {
  static const int _maxSearchLength = 100;
  static const double _wideBreakpoint = 760;

  late final TextEditingController _controller;
  late String _action;
  late String _status;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.search);
    _action = widget.action;
    _status = widget.status;
  }

  @override
  void didUpdateWidget(covariant AuditFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.search != widget.search &&
        widget.search != _controller.text.trim()) {
      _controller.text = widget.search;
    }
    if (oldWidget.action != widget.action) _action = widget.action;
    if (oldWidget.status != widget.status) _status = widget.status;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  void _submit() {
    if (widget.busy) return;

    // Only known values are ever sent.
    if (_action.isNotEmpty && !AuditOptions.actions.contains(_action)) {
      _action = '';
    }
    if (_status.isNotEmpty && !AuditOptions.statuses.contains(_status)) {
      _status = '';
    }

    FocusScope.of(context).unfocus();
    widget.onSearch(_controller.text.trim(), _action, _status);
  }

  void _clearSearch() {
    final hadAppliedSearch = widget.search.trim().isNotEmpty;

    _controller.clear();

    // Re-run only when a search was actually applied.
    if (hadAppliedSearch) _submit();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final search = _searchField();

    final actionDropdown = _dropdown(
      value: _action,
      allLabel: 'All Event Actions',
      options: AuditOptions.actions,
      onChanged: (v) {
        setState(() => _action = v);
        _submit();
      },
    );

    final statusDropdown = _dropdown(
      value: _status,
      allLabel: 'All Statuses',
      options: AuditOptions.statuses,
      onChanged: (v) {
        setState(() => _status = v);
        _submit();
      },
    );

    final button = _searchButton();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 12),
              SizedBox(width: 210, child: actionDropdown),
              const SizedBox(width: 12),
              SizedBox(width: 170, child: statusDropdown),
              const SizedBox(width: 12),
              button,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: actionDropdown),
                const SizedBox(width: 10),
                Expanded(child: statusDropdown),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: button),
          ],
        );
      },
    );
  }

  Widget _searchField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          inputFormatters: [
            LengthLimitingTextInputFormatter(_maxSearchLength),
          ],
          onSubmitted: (_) => _submit(),
          style: const TextStyle(fontSize: 14, color: _kTextDark),
          decoration: _decoration(
            hint: 'Search email, IP address, action...',
            prefix: const Icon(Icons.search_rounded, size: 20),
            suffix: value.text.isEmpty
                ? null
                : IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: _clearSearch,
            ),
          ),
        );
      },
    );
  }

  Widget _dropdown({
    required String value,
    required String allLabel,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return InputDecorator(
      decoration: _decoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(fontSize: 14, color: _kTextDark),
          onChanged: widget.busy ? null : (v) => onChanged(v ?? ''),
          items: [
            DropdownMenuItem<String>(value: '', child: Text(allLabel)),
            for (final option in options)
              DropdownMenuItem<String>(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }

  Widget _searchButton() {
    return FilledButton(
      onPressed: widget.busy ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(110, 48),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: widget.busy
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Text('Search'),
    );
  }

  InputDecoration _decoration({
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: outline(_kFieldBorder),
      enabledBorder: outline(_kFieldBorder),
      disabledBorder: outline(const Color(0xFFEDEFF3)),
      focusedBorder: outline(_kPrimary),
    );
  }
}