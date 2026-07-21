import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/agreement_data.dart';
import 'package:watermark_camera/services/agreement_api_service.dart';

/// 从后端拉取并展示服务协议 / 隐私政策。
class AgreementPage extends StatefulWidget {
  const AgreementPage({super.key, required this.type});

  /// [AgreementType.service] 或 [AgreementType.privacy]
  final String type;

  @override
  State<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  bool _loading = true;
  String? _error;
  AgreementData? _data;

  String get _fallbackTitle {
    switch (widget.type) {
      case AgreementType.privacy:
        return '隐私政策';
      case AgreementType.service:
      default:
        return '服务协议';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await Get.find<AgreementApiService>().getAgreement(widget.type);
      if (!mounted) return;
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _loading = false;
          _error = response.msg?.trim().isNotEmpty == true
              ? response.msg
              : '加载失败，请稍后重试';
          _data = null;
        });
        return;
      }
      setState(() {
        _loading = false;
        _data = response.data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '网络异常，请稍后重试';
        _data = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _data?.title.trim().isNotEmpty == true
        ? _data!.title
        : _fallbackTitle;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('重新加载')),
            ],
          ),
        ),
      );
    }

    final content = _data?.content ?? '';
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.65,
            color: Colors.grey.shade900,
          ),
        ),
      ),
    );
  }
}
