import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/utils/gallery_saver.dart';

class TeamQrInvitePage extends StatefulWidget {
  const TeamQrInvitePage({super.key, required this.team});

  final Team team;

  @override
  State<TeamQrInvitePage> createState() => _TeamQrInvitePageState();
}

class _TeamQrInvitePageState extends State<TeamQrInvitePage> {
  static const _wechatGreen = Color(0xFF07C160);

  final _screenshotController = ScreenshotController();
  bool _isSaving = false;

  Team get _team => widget.team;

  String get _qrPayload => _team.teamCode;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveQrCode() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final bytes = await _screenshotController.capture(pixelRatio: 3);
      if (!mounted) return;
      if (bytes == null) {
        _showMessage('保存失败，请重试');
        return;
      }

      final saved = await GallerySaver.saveImageBytes(
        bytes,
        fileName: 'team_qr_${_team.teamCode}',
      );
      if (!mounted) return;
      _showMessage(saved ? '二维码已保存到相册' : '保存失败，请检查相册权限');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '二维码邀请',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _team.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '团队号：${_team.teamCode}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      QrImageView(
                        data: _qrPayload,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          children: const [
                            TextSpan(text: '使用'),
                            TextSpan(
                              text: '微信',
                              style: TextStyle(color: _wechatGreen),
                            ),
                            TextSpan(text: '扫一扫，加入团队'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveQrCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE8EAED),
                        foregroundColor: const Color(0xFF333333),
                        disabledBackgroundColor: const Color(0xFFE8EAED),
                        disabledForegroundColor: Colors.grey,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isSaving ? '保存中...' : '保存二维码到相册',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
