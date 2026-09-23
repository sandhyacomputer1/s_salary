import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../data/services/auth_service.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() =>
      _TwoFactorScreenState();
}

class _TwoFactorScreenState
    extends State<TwoFactorScreen> {
  final _otpController =
  TextEditingController();

  final AuthService _authService =
  AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final otp =
    _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a 6-digit OTP',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tempToken =
      await SecureStorage.getTempToken();

      if (tempToken == null ||
          tempToken.isEmpty) {
        throw Exception(
          'Temporary token not found. Please login again.',
        );
      }

      final data =
      await _authService.verify2FA(
        tempToken: tempToken,
        otpCode: otp,
      );

      await _saveSession(data);

      final role =
      data['user']?['role']
          ?.toString()
          .toLowerCase();

      await SecureStorage.clearTempToken();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (role == 'employee') {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.employeeDashboard,
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.adminDashboard,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _saveSession(
      Map<String, dynamic> data,
      ) async {
    final user =
    Map<String, dynamic>.from(
      data['user'] ?? {},
    );

    final tokens =
    Map<String, dynamic>.from(
      data['tokens'] ?? {},
    );

    final accessToken =
    tokens['accessToken']?.toString();

    final refreshToken =
    tokens['refreshToken']?.toString();

    final userId =
    user['_id']?.toString();

    final role =
    user['role']?.toString();

    final companyId =
    user['companyId']?.toString();

    if (accessToken == null ||
        refreshToken == null ||
        userId == null ||
        role == null) {
      throw Exception(
        'Invalid authentication response.',
      );
    }

    await SecureStorage.saveLoginSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      role: role,
      companyId: companyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Two-Factor Authentication',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.security_outlined,
                    size: 70,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Verify your identity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Enter the 6-digit OTP to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                      Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller:
                    _otpController,
                    keyboardType:
                    TextInputType.number,
                    maxLength: 6,
                    textAlign:
                    TextAlign.center,
                    decoration:
                    const InputDecoration(
                      labelText: 'OTP Code',
                      hintText: '123456',
                      prefixIcon:
                      Icon(Icons
                          .password),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 52,
                    child:
                    ElevatedButton(
                      onPressed:
                      _isLoading
                          ? null
                          : _verifyOTP,
                      child: _isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child:
                        CircularProgressIndicator(),
                      )
                          : const Text(
                        'Verify OTP',
                        style:
                        TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}