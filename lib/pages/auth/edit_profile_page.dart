import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/api/user_info.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/file_api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _userNameController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _sex;
  String? _avatarUrl;
  String? _localAvatarPath;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploadingAvatar = false;

  AuthService get _auth => Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _nickNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_auth.userInfo.value == null) {
      await _auth.fetchUserInfo();
    }
    if (!mounted) return;

    final info = _auth.userInfo.value;
    if (info != null) {
      _applyUserInfo(info);
    }
    setState(() => _isLoading = false);
  }

  void _applyUserInfo(UserInfo info) {
    _userNameController.text = info.userName?.trim() ?? '';
    _nickNameController.text = info.nickName?.trim() ?? '';
    _emailController.text = info.email?.trim() ?? '';
    _phoneController.text = info.phone;
    _sex = _normalizeSex(info.sex);
    _avatarUrl = info.avatarUrl;
    _localAvatarPath = null;
  }

  String? _normalizeSex(String? raw) {
    final value = raw?.trim();
    if (value == '1' || value == '2') return value;
    return null;
  }

  Future<void> _pickAvatar() async {
    if (_isUploadingAvatar || _isSubmitting) return;

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      if (!mounted) return;
      _showMessage('需要相册权限才能更换头像');
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (!mounted || albums.isEmpty) return;

    final assets = await albums.first.getAssetListPaged(page: 0, size: 60);
    if (!mounted || assets.isEmpty) {
      _showMessage('相册中没有可用图片');
      return;
    }

    final picked = await showModalBottomSheet<AssetEntity>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(asset),
                child: FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(
                    const ThumbnailSize.square(200),
                  ),
                  builder: (context, snapshot) {
                    final bytes = snapshot.data;
                    if (bytes == null) {
                      return const ColoredBox(color: Color(0xFFF0F0F0));
                    }
                    return Image.memory(bytes, fit: BoxFit.cover);
                  },
                ),
              );
            },
          ),
        );
      },
    );
    if (picked == null || !mounted) return;

    final file = await picked.file;
    if (file == null || !file.existsSync()) {
      if (mounted) _showMessage('读取图片失败，请重试');
      return;
    }

    final token = _auth.accessToken.value.trim();
    if (token.isEmpty) {
      _showMessage('登录状态已失效，请重新登录');
      return;
    }

    setState(() {
      _localAvatarPath = file.path;
      _isUploadingAvatar = true;
    });

    try {
      final response = await Get.find<FileApiService>().uploadImage(
        accessToken: token,
        filePath: file.path,
      );
      if (!mounted) return;

      if (!response.isSuccess ||
          response.data == null ||
          response.data!.isEmpty) {
        _showMessage(response.msg ?? '头像上传失败');
        return;
      }

      setState(() => _avatarUrl = response.data);
      _showMessage('头像已更新');
    } catch (_) {
      if (mounted) _showMessage('头像上传失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
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

    if (_isUploadingAvatar) {
      _showMessage('头像上传中，请稍候');
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  ImageProvider? _avatarImageProvider() {
    final localPath = _localAvatarPath;
    if (localPath != null && File(localPath).existsSync()) {
      return FileImage(File(localPath));
    }
    final avatarUrl = ApiConfig.resolveAssetUrl(_avatarUrl);
    if (avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final info = _auth.userInfo.value;
    final avatarImage = _avatarImageProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text('修改个人资料'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : info == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _auth.lastErrorMessage.value.isNotEmpty
                        ? _auth.lastErrorMessage.value
                        : '用户信息加载失败',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _loadProfile();
                    },
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFEAF3FF),
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? Text(
                                    info.displayName.isNotEmpty
                                        ? info.displayName.substring(0, 1)
                                        : '我',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1677FF),
                                    ),
                                  )
                                : null,
                          ),
                          if (_isUploadingAvatar)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Color(0x66000000),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isUploadingAvatar ? null : _pickAvatar,
                        child: const Text('更换头像'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  readOnly: true,
                  controller: _phoneController,
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
                  key: ValueKey(_sex ?? 'unset'),
                  initialValue: _sex,
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
                const SizedBox(height: 20),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push(AppPaths.personalMembership),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF4EC), Color(0xFFFFE7D1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD7B0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A3D),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '个人会员',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '开通会员，解锁消除水印等权益',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8A6A4A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.orange.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _isSubmitting || _isUploadingAvatar
                      ? null
                      : _submit,
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
