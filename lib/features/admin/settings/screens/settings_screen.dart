import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../models/company_profile_model.dart';
import '../models/company_settings_model.dart';
import '../models/settings_request.dart';
import '../services/settings_service.dart';
import '../widgets/settings_late_pt_tabs.dart';
import '../widgets/settings_leave_security_tabs.dart';
import '../widgets/settings_profile_tab.dart';
import '../widgets/settings_shift_tab.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  // Palette copied from AdminDashboardScreen.
  static const Color _primary = Color(0xFFE96832);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);
  static const double _mobileBreakpoint = 700;

  static const List<String> _tabLabels = [
    'Profile & Location',
    'Shift & Work Timings',
    'Late Attendance Rules',
    'Professional Tax (PT) Slabs',
    'Leave Types & Quotas',
    'Security & 2FA',
  ];

  final SettingsService _service = SettingsService();
  late final TabController _tab;

  /// What the server has.
  CompanyBundle? _loaded;

  /// Working copies the tabs edit in place.
  CompanyProfile? _profile;
  CompanySettings? _settings;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  /// Changes after every (re)load so the tabs rebuild with fresh text.
  int _reload = 0;

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  bool get _profileDirty =>
      _profile != null &&
      _loaded != null &&
      _profile!.fingerprint != _loaded!.profile.fingerprint;

  bool get _settingsDirty =>
      _settings != null &&
      _loaded != null &&
      _settings!.fingerprint != _loaded!.settings.fingerprint;

  bool get _dirty => _profileDirty || _settingsDirty;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabLabels.length, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ==========================================================
  // DATA
  // ==========================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final bundle = await _service.fetch();
      if (!mounted) return;

      setState(() {
        _loaded = bundle;
        _profile = bundle.profile.copy();
        _settings = bundle.settings.copy();
        _loading = false;
        _saveError = null;
        _reload++;
      });
    } on SettingsException catch (e) {
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
        _loadError = 'Something went wrong while loading settings.';
      });
    }
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _changed() {
    setState(() => _saveError = null);
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  Future<void> _save() async {
    if (_saving) return; // no duplicate submissions

    final profile = _profile;
    final settings = _settings;
    final loaded = _loaded;
    if (profile == null || settings == null || loaded == null) return;

    final profileDirty = _profileDirty;
    final settingsDirty = _settingsDirty;
    final radiusChanged = profile.radiusMeters != loaded.profile.radiusMeters;

    // Validate only what changed, so an old, incomplete value elsewhere
    // never blocks an unrelated save.
    SettingsIssue? issue;
    if (profileDirty) issue = SettingsValidator.profile(profile);
    if (issue == null && (settingsDirty || radiusChanged)) {
      issue = SettingsValidator.settings(settings);
    }

    if (issue != null) {
      _tab.animateTo(issue.tab);
      setState(() => _saveError = issue!.message);
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      if (profileDirty) {
        await _service.saveProfile(profile);
      }

      if (settingsDirty || radiusChanged) {
        await _service.saveSettings(
          companyId: profile.id,
          settings: settings,
          radiusMeters: profile.radiusMeters,
        );
      }

      if (!mounted) return;

      // Re-read from the server so the screen shows exactly what was saved.
      await _load();
      if (!mounted) return;

      setState(() => _saving = false);
      _toast('Company settings saved.');
    } on SettingsException catch (e) {
      if (!mounted) return;

      if (e.isAuthError) {
        _goToLogin();
        return;
      }

      // Edits are kept so nothing is lost; the user can fix and retry.
      setState(() {
        _saving = false;
        _saveError = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _saveError = 'Could not save settings. Please try again.';
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ==========================================================
  // LEAVING WITH UNSAVED CHANGES
  // ==========================================================

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _primary),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'Settings',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Reload from server',
              onPressed: (_loading || _saving || _dirty) ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 14 : 22,
              mobile ? 16 : 22,
              mobile ? 14 : 22,
              35,
            ),
            children: [
              Text(
                'Company Admin  /  Company Settings',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              _body(mobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(bool mobile) {
    if (_loading && _profile == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null || _settings == null) {
      return _errorState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _primary,
            unselectedLabelColor: _textDark,
            indicatorColor: _primary,
            dividerColor: const Color(0xFFEDEFF3),
            labelStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            tabs: [for (final label in _tabLabels) Tab(text: label)],
          ),
          Padding(
            padding: EdgeInsets.all(mobile ? 14 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_saveError != null) ...[
                  _saveBanner(),
                  const SizedBox(height: 16),
                ],
                _tabContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabContent() {
    final profile = _profile!;
    final settings = _settings!;

    switch (_tab.index) {
      case 0:
        return SettingsProfileTab(
          key: ValueKey('profile-$_reload'),
          profile: profile,
          onChanged: _changed,
          dirty: _dirty,
          saving: _saving,
          onSave: _save,
        );
      case 1:
        return SettingsShiftTab(
          key: ValueKey('shift-$_reload'),
          settings: settings,
          onChanged: _changed,
          dirty: _dirty,
          saving: _saving,
          onSave: _save,
        );
      case 2:
        return SettingsLateTab(
          key: ValueKey('late-$_reload'),
          settings: settings,
          onChanged: _changed,
          dirty: _dirty,
          saving: _saving,
          onSave: _save,
        );
      case 3:
        return SettingsPtTab(
          key: ValueKey('pt-$_reload'),
          settings: settings,
          onChanged: _changed,
          dirty: _dirty,
          saving: _saving,
          onSave: _save,
        );
      case 4:
        return SettingsLeaveTab(
          key: ValueKey('leave-$_reload'),
          settings: settings,
          onChanged: _changed,
          dirty: _dirty,
          saving: _saving,
          onSave: _save,
        );
      default:
        return SettingsSecurityTab(
          key: ValueKey('security-$_reload'),
          settings: settings,
          onChanged: _changed,
          dirty: _dirty,
          saving: _saving,
          onSave: _save,
        );
    }
  }

  Widget _saveBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _saveError!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9B1C1C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
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
            _loadError ?? 'Could not load settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: _primary),
          ),
        ],
      ),
    );
  }
}
