import 'package:flutter/material.dart';

import '../models/branch_model.dart';

class BranchList extends StatelessWidget {
  const BranchList({
    super.key,
    required this.branches,
    required this.onEdit,
  });

  final List<BranchModel> branches;
  final ValueChanged<BranchModel> onEdit;

  static const double _wideBreakpoint = 760;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        return wide
            ? _WideTable(branches: branches, onEdit: onEdit)
            : _CompactList(branches: branches, onEdit: onEdit);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

final ButtonStyle _editButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: const Color(0xFF374151),
  side: const BorderSide(color: Color(0xFFD9DEE7)),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

String _typeLabel(BranchModel b) =>
    b.isHeadquarters ? 'Headquarters (HQ)' : 'Sub-Branch';

/// The HQ record has no code in the API payload; the web UI shows "HQ".
String _codeLabel(BranchModel b) =>
    (b.code != null && b.code!.trim().isNotEmpty)
        ? b.code!
        : (b.isHeadquarters ? 'HQ' : '-');

String? _gpsLabel(BranchModel b) => b.hasGps
    ? 'GPS: ${b.latitude!.toStringAsFixed(4)}, ${b.longitude!.toStringAsFixed(4)}'
    : null;

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fg = active ? const Color(0xFF18864B) : const Color(0xFFC62828);
    final bg = active ? const Color(0xFFE9F8EF) : const Color(0xFFFDECEC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminText extends StatelessWidget {
  const _AdminText(this.branch);
  final BranchModel branch;

  @override
  Widget build(BuildContext context) {
    final admin = branch.admin;
    if (admin == null) {
      return Text('-', style: TextStyle(color: Colors.grey.shade600));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          admin.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          admin.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }
}

class _AddressText extends StatelessWidget {
  const _AddressText(this.branch);
  final BranchModel branch;

  @override
  Widget build(BuildContext context) {
    final address = (branch.address ?? '').trim();
    final gps = _gpsLabel(branch);
    final muted = TextStyle(color: Colors.grey.shade600, fontSize: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          address.isEmpty ? '-' : address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (gps != null) Text(gps, style: muted),
        if ((branch.timezone ?? '').isNotEmpty)
          Text(branch.timezone!, style: muted),
      ],
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock(this.branch);
  final BranchModel branch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          branch.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          _typeLabel(branch),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wide layout
// ---------------------------------------------------------------------------

class _WideTable extends StatelessWidget {
  const _WideTable({required this.branches, required this.onEdit});

  final List<BranchModel> branches;
  final ValueChanged<BranchModel> onEdit;

  static const _flex = [3, 1, 3, 4, 2];

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: Colors.grey.shade700,
    );

    Widget headerCell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text, style: headerStyle),
    );

    return Column(
      children: [
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              headerCell('BRANCH / LOCATION NAME', _flex[0]),
              headerCell('CODE', _flex[1]),
              headerCell('BRANCH ADMIN (PORTAL LOGIN)', _flex[2]),
              headerCell('ADDRESS & LOCATION', _flex[3]),
              headerCell('STATUS', _flex[4]),
              const SizedBox(width: 80),
            ],
          ),
        ),
        for (var i = 0; i < branches.length; i++) ...[
          if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: _flex[0], child: _NameBlock(branches[i])),
                Expanded(
                  flex: _flex[1],
                  child: Text(
                    _codeLabel(branches[i]),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(flex: _flex[2], child: _AdminText(branches[i])),
                Expanded(flex: _flex[3], child: _AddressText(branches[i])),
                Expanded(
                  flex: _flex[4],
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusChip(active: branches[i].isActive),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: OutlinedButton(
                    onPressed: () => onEdit(branches[i]),
                    style: _editButtonStyle,
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compact layout (phones / narrow windows)
// ---------------------------------------------------------------------------

class _CompactList extends StatelessWidget {
  const _CompactList({required this.branches, required this.onEdit});

  final List<BranchModel> branches;
  final ValueChanged<BranchModel> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < branches.length; i++) ...[
          if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _NameBlock(branches[i])),
                    const SizedBox(width: 8),
                    _StatusChip(active: branches[i].isActive),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Code: ${_codeLabel(branches[i])}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                _AdminText(branches[i]),
                const SizedBox(height: 6),
                _AddressText(branches[i]),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => onEdit(branches[i]),
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}