import 'dart:io';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/models/api/media_verify_result.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/utils/watermark_metadata.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

class MediaVerifyResultPage extends StatefulWidget {
  const MediaVerifyResultPage({super.key, required this.asset});

  final AssetEntity asset;

  @override
  State<MediaVerifyResultPage> createState() => _MediaVerifyResultPageState();
}

class _MediaVerifyResultPageState extends State<MediaVerifyResultPage> {
  bool _loading = true;
  String? _error;
  MediaVerifyResult? _result;
  File? _previewFile;

  @override
  void initState() {
    super.initState();
    _runVerify();
  }

  Future<void> _runVerify() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final file = await widget.asset.file;
      if (file == null || !await file.exists()) {
        setState(() {
          _loading = false;
          _error = '无法读取所选文件';
        });
        return;
      }
      _previewFile = file;

      final meta = await WatermarkMetadata.readFromImagePath(file.path);
      final proof = meta?.proof;
      if (proof == null) {
        setState(() {
          _loading = false;
          _error = '未找到防伪凭证，请选择本应用拍摄的照片';
        });
        return;
      }

      String? accessToken;
      if (Get.isRegistered<AuthService>()) {
        final token = Get.find<AuthService>().accessToken.value.trim();
        if (token.isNotEmpty) accessToken = token;
      }

      final response = await Get.find<SpaceApiService>().verifyMedia(
        filePath: file.path,
        proofJson: proof.toJsonString(),
        accessToken: accessToken,
      );

      if (!mounted) return;
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _loading = false;
          _error = response.msg ?? '校验失败，请稍后重试';
        });
        return;
      }

      setState(() {
        _loading = false;
        _result = response.data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '网络异常，请稍后重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('验真结果'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在校验照片真实性...'),
                ],
              ),
            )
          : _error != null
              ? _buildError()
              : _buildSuccess(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.orange.shade700),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _runVerify,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final result = _result!;
    final trusted = result.isTrusted;
    final color = trusted ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_previewFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.file(_previewFile!, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Icon(
                  trusted ? Icons.verified_user : Icons.gpp_bad_outlined,
                  size: 48,
                  color: color,
                ),
                const SizedBox(height: 10),
                Text(
                  result.verdict.isEmpty
                      ? (trusted ? '可信' : '不可信')
                      : result.verdict,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  trusted ? '该照片通过真实性校验' : '该照片未通过真实性校验',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          if (result.stepResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              '校验项',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...result.stepResults.entries.map((entry) {
              final ok = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  ok ? Icons.check_circle : Icons.cancel,
                  color: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                ),
                title: Text(entry.key),
                trailing: Text(
                  ok ? '通过' : '未通过',
                  style: TextStyle(
                    color: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimaryBlue,
              side: const BorderSide(color: _kPrimaryBlue),
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }
}
