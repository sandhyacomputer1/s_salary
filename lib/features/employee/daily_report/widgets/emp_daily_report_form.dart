import 'package:flutter/material.dart';

import '../models/emp_daily_report_model.dart';

class EmpDailyReportForm extends StatefulWidget {
  /// Today's saved report, used only to pre-fill the fields on first build.
  final EmpDailyReportModel? initialReport;

  /// True when today's report already exists on the server (reports are
  /// upserted, so submitting again updates it).
  final bool hasSubmittedToday;

  final bool isSubmitting;

  /// Returns true when the backend accepted the report.
  final Future<bool> Function(EmpDailyReportInput input) onSubmit;

  const EmpDailyReportForm({
    super.key,
    required this.initialReport,
    required this.hasSubmittedToday,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<EmpDailyReportForm> createState() => _EmpDailyReportFormState();
}

class _EmpDailyReportFormState extends State<EmpDailyReportForm> {
  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color fill = Color(0xFFF7F8FA);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF2563EB);

  late final TextEditingController _completedController;
  late final TextEditingController _ongoingController;
  late final TextEditingController _planController;

  bool _busy = false;
  String? _completedError;
  String? _planError;

  @override
  void initState() {
    super.initState();

    final report = widget.initialReport;

    _completedController =
        TextEditingController(text: report?.completedWork ?? '');
    _ongoingController =
        TextEditingController(text: report?.ongoingWork ?? '');
    _planController =
        TextEditingController(text: report?.planForTomorrow ?? '');
  }

  @override
  void dispose() {
    _completedController.dispose();
    _ongoingController.dispose();
    _planController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_busy || widget.isSubmitting) return;

    FocusScope.of(context).unfocus();

    final completed = _completedController.text.trim();
    final ongoing = _ongoingController.text.trim();
    final plan = _planController.text.trim();

    final completedError =
    completed.isEmpty ? 'Please describe the work you completed today.' : null;
    final planError =
    plan.isEmpty ? 'Please enter tomorrow\'s work plan.' : null;

    if (completedError != null || planError != null) {
      setState(() {
        _completedError = completedError;
        _planError = planError;
      });
      return;
    }

    setState(() {
      _completedError = null;
      _planError = null;
      _busy = true;
    });

    try {
      await widget.onSubmit(
        EmpDailyReportInput(
          completedWork: completed,
          ongoingWork: ongoing,
          planForTomorrow: plan,
          date: DateTime.now(),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _textArea({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool disabled,
    String? errorText,
    VoidCallback? onEdited,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !disabled,
          minLines: 4,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14.5, color: textDark, height: 1.4),
          onChanged: (_) {
            if (onEdited != null) onEdited();
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13.5, color: textLight),
            filled: true,
            fillColor: fill,
            errorText: errorText,
            contentPadding: const EdgeInsets.all(14),
            border: _inputBorder(border),
            enabledBorder: _inputBorder(border),
            disabledBorder: _inputBorder(border),
            focusedBorder: _inputBorder(primary, 1.4),
            errorBorder: _inputBorder(danger),
            focusedErrorBorder: _inputBorder(danger, 1.4),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _busy || widget.isSubmitting;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 560;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit Daily End-of-Day (EOD) Work Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Report for ${EmpDailyReportFormat.longDate(DateTime.now())}',
                style: const TextStyle(fontSize: 14, color: textMedium),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: border),
              const SizedBox(height: 18),
              if (widget.hasSubmittedToday) ...[
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F0FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: info.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: info),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Today\'s report has already been submitted. '
                              'You can edit it below and submit again to update it.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: info,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              _textArea(
                label: 'Completed Work Today (Key Accomplishments) *',
                controller: _completedController,
                hint:
                'Bullet list of key tasks, features, or tickets completed today...',
                disabled: disabled,
                errorText: _completedError,
                onEdited: () {
                  if (_completedError != null) {
                    setState(() => _completedError = null);
                  }
                },
              ),
              const SizedBox(height: 18),
              _textArea(
                label: 'Ongoing Work / Tasks in Progress',
                controller: _ongoingController,
                hint:
                'Ongoing code reviews, pending testing, or in-progress design work...',
                disabled: disabled,
              ),
              const SizedBox(height: 18),
              _textArea(
                label: 'Tomorrow\'s Work Plan *',
                controller: _planController,
                hint: 'Planned tasks, priorities, or meetings for tomorrow...',
                disabled: disabled,
                errorText: _planError,
                onEdited: () {
                  if (_planError != null) {
                    setState(() => _planError = null);
                  }
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: wide ? null : double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: disabled ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: disabled
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    widget.hasSubmittedToday
                        ? 'Update Today\'s EOD Report'
                        : 'Submit Daily EOD Report',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}