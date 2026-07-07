import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _userNameController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _sex;
  String? _avatarUrl;
  bool _isSubmitting = false;

  AuthService get _auth => Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    final info = _auth.userInfo.value;
    if (info != null) {
      _userNameController.text = info.userName ?? '';
      _nickNameController.text = info.nickName ?? '';
      _emailController.text = info.email ?? '';
      _sex = info.sex;
      _avatarUrl = info.avatarUrl;
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _nickNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final info = _auth.userInfo.value;
    if (info == null) {
      _showMessage('用户信息未加载，请返回重试');
      return;
    }

    final userName = _userNameController.text.trim();
    if (userName.isEmpty) {
      _showMessage('请输入用户名');
      return;
    }

    final nickName = _nickNameController.text.trim();
    if (nickName.isEmpty) {
      _showMessage('请输入昵称');
      return;
    }

    if (_sex == null || _sex!.isEmpty) {
      _showMessage('请选择性别');
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await _auth.updateUserInfo(
      userName: userName,
      nickName: nickName,
      sex: _sex!,
      email: _emailController.text.trim(),
      avatarUrl: _avatarUrl ?? '',
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (!success) {
      _showMessage(
        _auth.lastErrorMessage.value.isNotEmpty
            ? _auth.lastErrorMessage.value
            : '修改资料失败，请稍后重试',
      );
      return;
    }

    _showMessage('资料已保存');
    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _auth.userInfo.value;
    final avatarUrl = ApiConfig.resolveAssetUrl(_avatarUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('修改个人资料'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFEAF3FF),
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          (info?.displayName.isNotEmpty ?? false)
                              ? info!.displayName.substring(0, 1)
                              : '我',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1677FF),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showMessage('头像上传接口待对接'),
                  child: const Text('更换头像'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: info?.phone ?? ''),
            decoration: const InputDecoration(
              labelText: '手机号',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userNameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              hintText: '请输入用户名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nickNameController,
            decoration: const InputDecoration(
              labelText: '昵称',
              hintText: '请输入昵称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _sex == null || _sex!.isEmpty ? null : _sex,
            decoration: const InputDecoration(
              labelText: '性别',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '1', child: Text('男')),
              DropdownMenuItem(value: '2', child: Text('女')),
            ],
            onChanged: (value) => setState(() => _sex = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '邮箱',
              hintText: '请输入邮箱',
              border: OutlineInputBorder(),
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
                : const Text('保存'),
          ),
        ],
      ),
    );
  }
}
