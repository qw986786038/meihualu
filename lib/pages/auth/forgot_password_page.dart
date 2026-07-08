import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _smsCountdown = 0;
  Timer? _smsTimer;

  AuthService get _auth => Get.find<AuthService>();

  bool get _canSendSmsCode =>
      _smsCountdown == 0 && !_isSubmitting && _isValidPhone(_phoneController.text);

  @override
  void dispose() {
    _smsTimer?.cancel();
    _phoneController.dispose();
    _smsCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final trimmed = phone.trim();
    return RegExp(r'^1\d{10}$').hasMatch(trimmed);
  }

  void _startSmsCountdown() {
    _smsTimer?.cancel();
    setState(() => _smsCountdown = 60);
    _smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_smsCountdown <= 1) {
        timer.cancel();
        setState(() => _smsCountdown = 0);
        return;
      }
      setState(() => _smsCountdown -= 1);
    });
  }

  Future<void> _sendSmsCode() async {
    if (!_canSendSmsCode) return;

    final phone = _phoneController.text.trim();
    if (!_isValidPhone(phone)) {
      _showMessage('请输入正确的手机号');
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await _auth.sendSmsCode(phoneNumber: phone);
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (!success) {
      _showMessage(
        _auth.lastErrorMessage.value.isNotEmpty
            ? _auth.lastErrorMessage.value
            : '验证码发送失败，请稍后重试',
      );
      return;
    }

    _startSmsCountdown();
    _showMessage('验证码已发送');
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final phone = _phoneController.text.trim();
    if (!_isValidPhone(phone)) {
      _showMessage('请输入正确的手机号');
      return;
    }

    final smsCode = _smsCodeController.text.trim();
    if (smsCode.isEmpty) {
      _showMessage('请输入验证码');
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      _showMessage('请输入新密码');
      return;
    }

    final confirmPassword = _confirmPasswordController.text;
    if (confirmPassword.isEmpty) {
      _showMessage('请确认新密码');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('两次输入的密码不一致');
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await _auth.resetPassword(
      phoneNumber: phone,
      smsCode: smsCode,
      password: password,
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (!success) {
      _showMessage(
        _auth.lastErrorMessage.value.isNotEmpty
            ? _auth.lastErrorMessage.value
            : '重置密码失败，请稍后重试',
      );
      return;
    }

    _showMessage('密码重置成功，请使用新密码登录');
    context.pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('忘记密码'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '验证手机号后即可设置新密码。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 11,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: '手机号',
              hintText: '请输入手机号',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _smsCodeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            decoration: InputDecoration(
              labelText: '验证码',
              hintText: '请输入验证码',
              border: const OutlineInputBorder(),
              counterText: '',
              suffixIcon: TextButton(
                onPressed: _canSendSmsCode ? _sendSmsCode : null,
                child: Text(
                  _smsCountdown > 0 ? '${_smsCountdown}s' : '获取验证码',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '新密码',
              hintText: '请输入新密码',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: '确认密码',
              hintText: '请再次输入新密码',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('确认重置'),
          ),
        ],
      ),
    );
  }
}
