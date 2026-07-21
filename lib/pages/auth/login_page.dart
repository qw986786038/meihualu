import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';

enum _LoginMode { password, smsCode }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _smsCodeController = TextEditingController();

  _LoginMode _loginMode = _LoginMode.password;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  int _smsCountdown = 0;
  Timer? _smsTimer;

  AuthService get _auth => Get.find<AuthService>();

  bool get _canSendSmsCode =>
      _smsCountdown == 0 && !_isSubmitting && _isValidPhone(_phoneController.text);

  @override
  void dispose() {
    _smsTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final trimmed = phone.trim();
    return RegExp(r'^1\d{10}$').hasMatch(trimmed);
  }

  void _switchLoginMode(_LoginMode mode) {
    if (_loginMode == mode) return;
    setState(() => _loginMode = mode);
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

    setState(() => _isSubmitting = true);
    late final bool success;

    if (_loginMode == _LoginMode.password) {
      final password = _passwordController.text;
      if (password.isEmpty) {
        setState(() => _isSubmitting = false);
        _showMessage('请输入密码');
        return;
      }
      success = await _auth.loginWithPassword(
        phoneNumber: phone,
        password: password,
      );
    } else {
      final code = _smsCodeController.text.trim();
      if (code.isEmpty) {
        setState(() => _isSubmitting = false);
        _showMessage('请输入验证码');
        return;
      }
      success = await _auth.loginWithSmsCode(
        phoneNumber: phone,
        code: code,
      );
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (!success) {
      final fallback = _loginMode == _LoginMode.password
          ? '登录失败，请检查账号密码'
          : '登录失败，请检查验证码';
      _showMessage(
        _auth.lastErrorMessage.value.isNotEmpty
            ? _auth.lastErrorMessage.value
            : fallback,
      );
      return;
    }

    if (mounted) context.pop(true);
  }

  Future<void> _loginWithWechat() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final result = await _auth.loginWithWechat();
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (result.needBindPhone) {
      final bound = await context.push<bool>(
        AppPaths.wechatBindPhone,
        extra: result.bindToken,
      );
      if (!mounted) return;
      if (bound == true) context.pop(true);
      return;
    }

    if (!result.loggedIn) {
      _showMessage(
        _auth.lastErrorMessage.value.isNotEmpty
            ? _auth.lastErrorMessage.value
            : '微信登录失败，请稍后重试',
      );
      return;
    }

    if (mounted) context.pop(true);
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
        title: const Text('登录'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '登录后可创建个人空间、创建或加入团队，统一管理拍照同步。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SegmentedButton<_LoginMode>(
            segments: const [
              ButtonSegment(
                value: _LoginMode.password,
                label: Text('密码登录'),
              ),
              ButtonSegment(
                value: _LoginMode.smsCode,
                label: Text('验证码登录'),
              ),
            ],
            selected: {_loginMode},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              _switchLoginMode(selection.first);
            },
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
          if (_loginMode == _LoginMode.password) ...[
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '请输入密码',
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.push(AppPaths.forgotPassword),
                child: const Text('忘记密码'),
              ),
            ),
          ] else ...[
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
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '登录成功后将自动创建个人空间，可在相机页切换个人/团队模式并管理同步设置。',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
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
                : const Text('立即登录'),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '其他登录方式',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _loginWithWechat,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: const Color(0xFF07C160),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            icon: const Icon(Icons.wechat, color: Color(0xFF07C160)),
            label: const Text('微信授权登录'),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '登录即表示同意',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              TextButton(
                onPressed: () => context.push(AppPaths.serviceAgreement),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('《服务协议》', style: TextStyle(fontSize: 12)),
              ),
              Text(
                '和',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              TextButton(
                onPressed: () => context.push(AppPaths.privacyPolicy),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('《隐私政策》', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],

      ),
    );
  }
}
