import 'package:flutter/material.dart';

class IndustryCategory {
  const IndustryCategory({
    required this.name,
    required this.icon,
    this.children = const [],
  });

  final String name;
  final IconData icon;
  final List<String> children;

  bool get hasChildren => children.isNotEmpty;
}

const List<IndustryCategory> kTeamIndustryCategories = [
  IndustryCategory(
    name: '建筑/装修',
    icon: Icons.apartment_outlined,
    children: [
      '房屋建筑业',
      '建筑装饰/装修',
      '铁路/道路/隧道/桥梁工程建筑业',
      '其他土木工程建筑业',
    ],
  ),
  IndustryCategory(
    name: '物业管理',
    icon: Icons.home_repair_service_outlined,
  ),
  IndustryCategory(
    name: '电力/热力/燃气/水生产和供应业',
    icon: Icons.bolt_outlined,
  ),
  IndustryCategory(
    name: '快消/批发',
    icon: Icons.shopping_bag_outlined,
  ),
  IndustryCategory(
    name: '零售/促销',
    icon: Icons.shopping_cart_outlined,
  ),
  IndustryCategory(
    name: '餐饮/住宿',
    icon: Icons.room_service_outlined,
  ),
  IndustryCategory(
    name: '服务业',
    icon: Icons.favorite_border,
  ),
  IndustryCategory(
    name: '交通运输/仓储/邮政快递业',
    icon: Icons.local_shipping_outlined,
  ),
  IndustryCategory(
    name: '公共和环境',
    icon: Icons.eco_outlined,
  ),
  IndustryCategory(
    name: '农/林/牧/渔业',
    icon: Icons.park_outlined,
  ),
];

String? findIndustryCategoryName(String selection) {
  for (final category in kTeamIndustryCategories) {
    if (category.name == selection) return category.name;
    if (category.children.contains(selection)) return category.name;
  }
  return null;
}
