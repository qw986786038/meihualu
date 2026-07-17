import 'package:flutter/material.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/pages/auth/personal_membership_page.dart';

class TeamMembershipArgs {
  const TeamMembershipArgs({required this.team});

  final Team team;
}

/// 团队 VIP 开通页（仅主管理员可进入）。
class TeamMembershipPage extends StatelessWidget {
  const TeamMembershipPage({super.key, required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return PersonalMembershipPage(
      planType: '1',
      title: '开通团队会员',
    );
  }
}
