import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../models/branch_model.dart';
import '../services/branch_service.dart';
import '../widgets/branch_form.dart';
import '../widgets/branch_list.dart';

class BranchesScreen extends StatefulWidget {
  /// True when shown inside the admin dashboard (the sidebar stays visible).
  final bool embedded;

  const BranchesScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  // Palette copied from AdminDashboardScreen.
  static const Color _primary = Color(0xFFE96832);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);
  static const double _mobileBreakpoint = 700;

  final BranchAdminService _service = BranchAdminService();

  List<BranchModel> _branches = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _service.fetchBranches();
      if (!mounted) return;
      setState(() {
        _branches = data;
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } on BranchException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (route) => false,
        );
        return;
      }
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = 'Something went wrong while loading branches.';
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _load(silent: true);
  }

  Future<void> _openForm([BranchModel? branch]) async {
    final saved = await BranchForm.show(context, branch: branch);
    if (saved != true || !mounted) return;

    await _load(silent: true);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          branch == null ? 'Sub-branch created.' : 'Branch updated.',
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // The core body content
    final bodyContent = SafeArea(child: _buildContent());

    // Embedded: return only the body so the dashboard shell stays visible
    if (widget.embedded) {
      return Container(
        color: _pageBg,
        child: bodyContent,
      );
    }

    // Standalone: full screen with its own Scaffold and AppBar
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Branches & Locations',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildContent() {
    final mobile = _isMobile;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          mobile ? 14 : 22,
          mobile ? 16 : 22,
          mobile ? 14 : 22,
          35,
        ),
        children: [
          // Breadcrumb
          Text(
            'Company Admin  /  Branches & Locations',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(mobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(mobile),
                SizedBox(height: mobile ? 14 : 20),
                const Divider(height: 1, color: Color(0xFFEDEFF3)),
                _body(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool mobile) {
    final count = _loading || _error != null ? '' : ' (${_branches.length})';

    final title = Text(
      'Sub-Branches & Office Locations$count',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _textDark,
      ),
    );

    final addButton = FilledButton.icon(
      onPressed: _loading ? null : () => _openForm(),
      icon: const Icon(Icons.add, size: 17),
      label: const Text('Add Sub-Branch / Location'),
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: addButton),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        addButton,
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 30,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(backgroundColor: _primary),
            ),
          ],
        ),
      );
    }

    if (_branches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No branches or locations found.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return BranchList(branches: _branches, onEdit: _openForm);
  }
}