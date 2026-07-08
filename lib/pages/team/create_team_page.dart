import 'dart:io';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team_brand.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/file_api_service.dart';

class CreateTeamPage extends StatefulWidget {
  const CreateTeamPage({super.key});

  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final _nameController = TextEditingController();
  String _industryType = '房屋建筑业';
  TeamBrandSelection? _brandSelection;
  String? _uploadedLogoUrl;
  bool _isUploadingBrand = false;
  bool _isSubmitting = false;

  AuthService get _auth => Get.find<AuthService>();

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      !_isSubmitting &&
      !_isUploadingBrand;

  Future<void> _pickIndustry() async {
    final selected = await context.push<String>(
      AppPaths.teamIndustryPicker,
      extra: _industryType,
    );

    if (selected != null) {
      setState(() => _industryType = selected);
    }
  }

  Future<void> _pickBrandImage() async {
    final selected = await context.push<TeamBrandSelection>(
      AppPaths.teamBrandPicker,
    );
    if (selected == null || !mounted) return;

    setState(() {
      _brandSelection = selected;
      _uploadedLogoUrl = null;
    });

    final imagePath = selected.imagePath?.trim();
    if (imagePath == null || imagePath.isEmpty) return;

    final file = File(imagePath);
    if (!file.existsSync()) {
      _showMessage('品牌图读取失败，请重新选择');
      return;
    }

    final token = _auth.accessToken.value.trim();
    if (token.isEmpty) {
      _showMessage('请先登录');
      return;
    }

    setState(() => _isUploadingBrand = true);
    try {
      final response = await Get.find<FileApiService>().uploadImage(
        accessToken: token,
        filePath: imagePath,
      );
      if (!mounted) return;

      if (!response.isSuccess ||
          response.data == null ||
          response.data!.isEmpty) {
        _showMessage(response.msg ?? '品牌图上传失败');
        return;
      }

      setState(() => _uploadedLogoUrl = response.data);
      _showMessage('品牌图已上传');
    } catch (_) {
      if (mounted) _showMessage('品牌图上传失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isUploadingBrand = false);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);
    final success = await _auth.createTeam(
      name: _nameController.text.trim(),
      industryType: _industryType,
      logo: _uploadedLogoUrl,
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (!success) {
      _showMessage(
        _auth.lastErrorMessage.value.isNotEmpty
            ? _auth.lastErrorMessage.value
            : '创建失败，请重试',
      );
      return;
    }

    _showMessage('团队创建成功');
    context.pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _brandStatusText() {
    if (_isUploadingBrand) return '品牌图上传中...';
    if (_brandSelection == null) return '立即添加，享升级服务';
    if (_uploadedLogoUrl != null && _uploadedLogoUrl!.isNotEmpty) {
      return '${_brandSelection!.displayName}（已上传）';
    }
    return _brandSelection!.displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '完善团队信息',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _FormRow(
                  label: '团队名称',
                  child: TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '请输入真实团队名称',
                      hintStyle: TextStyle(
                        color: Color(0xFFBFBFBF),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const Divider(height: 1, indent: 16),
                _FormRow(
                  label: '行业类型',
                  onTap: _pickIndustry,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _industryType,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16),
                _FormRow(
                  label: '公司品牌图',
                  onTap: _isUploadingBrand ? null : _pickBrandImage,
                  child: Row(
                    children: [
                      if (_isUploadingBrand) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          _brandStatusText(),
                          style: TextStyle(
                            fontSize: 15,
                            color: _brandSelection == null
                                ? const Color(0xFFBFBFBF)
                                : const Color(0xFF333333),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8EC5FF),
                      disabledBackgroundColor: const Color(0xFF8EC5FF),
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '创建团队',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push(AppPaths.joinTeam),
                  child: const Text(
                    '已有团队，去加入',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1677FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    required this.child,
    this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}
