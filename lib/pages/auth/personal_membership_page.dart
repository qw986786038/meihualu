import 'dart:async';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/api/vip_plan.dart';
import 'package:watermark_camera/services/alipay_service.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/order_api_service.dart';

class _MembershipPlanView {
  const _MembershipPlanView({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.originalPriceLabel,
    required this.footerLabel,
    required this.payAmount,
  });

  final String id;
  final String title;
  final String priceLabel;
  final String originalPriceLabel;
  final String footerLabel;
  final double payAmount;

  factory _MembershipPlanView.fromVipPlan(VipPlan plan) {
    return _MembershipPlanView(
      id: plan.id,
      title: plan.planName,
      priceLabel: plan.priceLabel,
      originalPriceLabel: plan.originalPriceLabel,
      footerLabel: plan.footerLabel,
      payAmount: plan.price.toDouble(),
    );
  }
}

class PersonalMembershipPage extends StatefulWidget {
  const PersonalMembershipPage({
    super.key,
    this.planType = '0',
    this.title = '开通个人会员',
  });

  /// 套餐类型：0 个人，1 团队。
  final String planType;
  final String title;

  @override
  State<PersonalMembershipPage> createState() => _PersonalMembershipPageState();
}

class _PersonalMembershipPageState extends State<PersonalMembershipPage> {
  static const _bgPeach = Color(0xFFFFF4EC);

  List<_MembershipPlanView> _plans = const [];
  String? _selectedPlanId;
  bool _loadingPlans = true;
  bool _paying = false;
  String? _loadError;

  AuthService get _auth => Get.find<AuthService>();
  OrderApiService get _orderApi => Get.find<OrderApiService>();
  AlipayService get _alipay => Get.find<AlipayService>();

  _MembershipPlanView? get _selectedPlan {
    if (_plans.isEmpty) return null;
    final id = _selectedPlanId;
    if (id != null) {
      for (final plan in _plans) {
        if (plan.id == id) return plan;
      }
    }
    return _plans.first;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlans());
  }

  Future<void> _loadPlans() async {
    final token = _auth.accessToken.value.trim();
    if (token.isEmpty) {
      setState(() {
        _loadingPlans = false;
        _loadError = '请先登录';
        _plans = const [];
      });
      return;
    }

    setState(() {
      _loadingPlans = true;
      _loadError = null;
    });

    try {
      final response = await _orderApi.listPlans(
        accessToken: token,
        planType: widget.planType,
      );
      if (!mounted) return;
      if (!response.isSuccess || response.data == null) {
        setState(() {
          _loadingPlans = false;
          _loadError = response.msg ?? '套餐加载失败';
          _plans = const [];
        });
        return;
      }

      final plans = response.data!
          .map(_MembershipPlanView.fromVipPlan)
          .where((plan) => plan.id.isNotEmpty)
          .toList();
      setState(() {
        _plans = plans;
        _selectedPlanId = plans.isEmpty ? null : plans.first.id;
        _loadingPlans = false;
        _loadError = plans.isEmpty ? '暂无可用套餐' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPlans = false;
        _loadError = '网络异常，请稍后重试';
        _plans = const [];
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onPay() async {
    if (_paying) return;

    final plan = _selectedPlan;
    if (plan == null) {
      _showMessage('请选择套餐');
      return;
    }

    final token = _auth.accessToken.value.trim();
    if (token.isEmpty) {
      _showMessage('请先登录');
      return;
    }

    setState(() => _paying = true);
    try {
      final response = await _orderApi.createAndPay(
        accessToken: token,
        planId: plan.id,
        channel: 'alipay',
        tradeType: 'APP',
        returnUrl: '',
      );
      if (!mounted) return;
      if (!response.isSuccess || response.data == null) {
        _showMessage(response.msg ?? '创建订单失败');
        return;
      }

      final payResult = await _alipay.pay(response.data!.payPayload);
      if (!mounted) return;
      switch (payResult.status) {
        case AlipayPayStatus.success:
          _showMessage('支付成功');
        case AlipayPayStatus.cancelled:
          _showMessage(payResult.message.isEmpty ? '已取消支付' : payResult.message);
        case AlipayPayStatus.notInstalled:
          _showMessage('未安装支付宝，请安装后重试');
        case AlipayPayStatus.failed:
          _showMessage(
            payResult.message.isEmpty ? '支付失败，请稍后重试' : payResult.message,
          );
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('支付异常，请稍后重试');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _auth.userInfo.value;
    final avatarUrl = ApiConfig.resolveAssetUrl(info?.avatarUrl);
    final displayName = info?.displayName ?? _auth.userName.value;
    final name = displayName.trim().isEmpty ? '我' : displayName.trim();
    final selected = _selectedPlan;

    return Scaffold(
      backgroundColor: _bgPeach,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: _bgPeach,
                  foregroundColor: const Color(0xFF333333),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  title: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),
                  centerTitle: true,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFEAF3FF),
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? Text(
                                  name.substring(0, 1),
                                  style: const TextStyle(
                                    color: Color(0xFF1677FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '开通会员解锁全部权益',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loadingPlans)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (_loadError != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                      child: Column(
                        children: [
                          Text(
                            _loadError!,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loadPlans,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: SizedBox(
                        height: 148,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _plans.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final plan = _plans[index];
                            return _PlanCard(
                              plan: plan,
                              selected: plan.id == selected?.id,
                              onTap: () =>
                                  setState(() => _selectedPlanId = plan.id),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '支付方式',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _PayMethodTile(
                          selected: true,
                          title: '支付宝',
                          icon: _PayBrandIcon(
                            color: Color(0xFF1677FF),
                            label: '支',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _BottomPayBar(
            amount: selected?.payAmount ?? 0,
            paying: _paying,
            enabled: selected != null && !_loadingPlans,
            onPay: _onPay,
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final _MembershipPlanView plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 118,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 118,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFF8F1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF8A3D)
                      : const Color(0xFFE8E8E8),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    plan.priceLabel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFFE8782A)
                          : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.originalPriceLabel.isEmpty
                        ? ' '
                        : plan.originalPriceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      decoration: plan.originalPriceLabel.isEmpty
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF8A3D)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(11),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      plan.footerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMethodTile extends StatelessWidget {
  const _PayMethodTile({
    required this.selected,
    required this.title,
    required this.icon,
  });

  final bool selected;
  final String title;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, color: Color(0xFF222222)),
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? const Color(0xFF1677FF) : Colors.grey.shade400,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _PayBrandIcon extends StatelessWidget {
  const _PayBrandIcon({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BottomPayBar extends StatelessWidget {
  const _BottomPayBar({
    required this.amount,
    required this.onPay,
    this.paying = false,
    this.enabled = true,
  });

  final double amount;
  final VoidCallback onPay;
  final bool paying;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: enabled
                  ? const [Color(0xFFE8A23A), Color(0xFFFF8A3D)]
                  : [Colors.grey.shade400, Colors.grey.shade400],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled && !paying ? onPay : null,
              borderRadius: BorderRadius.circular(24),
              child: Center(
                child: paying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '确认支付 ¥${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
