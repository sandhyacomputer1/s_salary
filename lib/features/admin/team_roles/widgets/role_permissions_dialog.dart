import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../models/role_permission_model.dart';
import '../models/team_member_model.dart';
import '../services/team_roles_service.dart';

// Palette copied from AdminDashboardScreen.
const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kFieldBorder = Color(0xFFD9DEE7);
const Color _kPageBg = Color(0xFFF7F8FA);
const Color _kDanger = Color(0xFFDC2626);

class RolePermissionsDialog extends StatefulWidget {
  const RolePermissionsDialog({super.key});

  /// Resolves to true when permissions were saved.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: const RolePermissionsDialog(),
        ),
      ),
    );
  }

  @override
  State<RolePermissionsDialog> createState() => _RolePermissionsDialogState();
}

class _RolePermissionsDialogState extends State<RolePermissionsDialog> {
  final TeamRolesService _service = TeamRolesService();

  RolePermissions? _saved; // what the server has
  RolePermissions? _draft; // what the user is editing

  String _role = RolePermissions.editableRoles.first;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ==========================================================
  // LOAD (always from the server, every time the dialog opens)
  // ==========================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _saveError = null;
    });

    try {
      final permissions = await _service.fetchRolePermissions();
      if (!mounted) return;

      setState(() {
        _saved = permissions;
        _draft = permissions.copy();
        _loading = false;
      });
    } on TeamRolesException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        _goToLogin();
        return;
      }
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load permissions. Please try again.';
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
          (route) => false,
    );
  }

  // ==========================================================
  // EDIT ACTIONS
  // ==========================================================

  void _toggle(String key, bool granted) {
    setState(() => _draft!.setModule(_role, key, granted));
  }

  void _selectAll() {
    setState(() => _draft!.selectAll(_role));
  }

  void _clearAll() {
    setState(() => _draft!.clearAll(_role));
  }

  /// There is no "default permissions" endpoint in the API reference, so this
  /// reverts all unsaved edits back to what the server currently has.
  void _resetChanges() {
    setState(() {
      _draft = _saved!.copy();
      _saveError = null;
    });
  }

  // ==========================================================
  // SAVE  (PUT /companies/:id/settings)
  // ==========================================================

  Future<void> _save() async {
    if (_saving) return;

    final draft = _draft;
    final saved = _saved;
    if (draft == null || saved == null) return;

    if (draft.sameAs(saved)) {
      Navigator.of(context).pop(false); // nothing changed, nothing to send
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await _service.saveRolePermissions(draft);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TeamRolesException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        _goToLogin();
        return;
      }
      setState(() {
        _saving = false;
        _saveError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Could not save permissions. Please try again.';
      });
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: _content(),
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Custom Role Access & Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final canSave = !_loading && _loadError == null && !_saving;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: _kFieldBorder),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Save Role Permissions'),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 34, color: _kDanger),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            ),
          ],
        ),
      );
    }

    return _editor();
  }

  // ==========================================================
  // EDITOR
  // ==========================================================

  Widget _editor() {
    final draft = _draft!;
    final granted = draft.grantedCount(_role);
    final total = PermissionCatalog.modules.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_saveError != null) _errorBanner(_saveError!),
        const SizedBox(height: 8),
        _rolePanel(),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                'Module Permissions for '
                    '${TeamRole.shortLabel(_role).toUpperCase()} '
                    '($granted / $total Granted)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _smallButton('Select All', _selectAll),
                  _smallButton('Clear All', _clearAll),
                  _smallButton('Reset Changes', _resetChanges),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final columns = constraints.maxWidth >= 520 ? 2 : 1;
            final tileWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final module in PermissionCatalog.modules)
                  _tile(module, tileWidth),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _rolePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Team Role to Configure Access:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tabs = [
                for (final role in RolePermissions.editableRoles)
                  _roleTab(role),
              ];

              if (constraints.maxWidth >= 520) {
                return Row(
                  children: [
                    for (var i = 0; i < tabs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: tabs[i]),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < tabs.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: tabs[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roleTab(String role) {
    final selected = role == _role;

    return InkWell(
      onTap: _saving ? null : () => setState(() => _role = role),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _kPrimary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              TeamRole.shortLabel(role),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _kTextDark,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                TeamRole.tagline(role),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(PermissionModule module, double width) {
    final on = _draft!.has(_role, module.key);

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: _saving ? null : () => _toggle(module.key, !on),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFFFF4EE) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? _kPrimary : _kFieldBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: on,
                  activeColor: _kPrimary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged:
                  _saving ? null : (v) => _toggle(module.key, v ?? false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: on ? _kPrimary : _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Group: ${module.group}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: _saving ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kTextDark,
        side: const BorderSide(color: _kFieldBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: _kDanger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9B1C1C)),
            ),
          ),
        ],
      ),
    );
  }
}