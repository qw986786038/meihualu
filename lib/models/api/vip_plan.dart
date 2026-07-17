class VipPlanFeature {
  const VipPlanFeature({
    required this.id,
    required this.planId,
    required this.featureKey,
    required this.featureName,
    required this.featureValue,
    this.icon,
    this.sortOrder = 0,
    this.remark,
    this.dataType,
    this.unit,
    this.defaultValue,
  });

  final String id;
  final String planId;
  final String featureKey;
  final String featureName;
  final String featureValue;
  final String? icon;
  final int sortOrder;
  final String? remark;
  final String? dataType;
  final String? unit;
  final String? defaultValue;

  factory VipPlanFeature.fromJson(Map<String, dynamic> json) {
    return VipPlanFeature(
      id: json['id']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      featureKey: json['featureKey']?.toString() ?? '',
      featureName: json['featureName']?.toString() ?? '',
      featureValue: json['featureValue']?.toString() ?? '',
      icon: json['icon']?.toString(),
      sortOrder: _asInt(json['sortOrder']) ?? 0,
      remark: json['remark']?.toString(),
      dataType: json['dataType']?.toString(),
      unit: json['unit']?.toString(),
      defaultValue: json['defaultValue']?.toString(),
    );
  }

  String get displayDetail {
    final remarkText = remark?.trim() ?? '';
    if (remarkText.isNotEmpty) return remarkText;
    final unitText = unit?.trim() ?? '';
    if (unitText.isEmpty) return featureValue;
    return '$featureValue$unitText';
  }
}

class VipPlan {
  const VipPlan({
    required this.id,
    required this.planCode,
    required this.planType,
    required this.planName,
    this.planDesc,
    required this.price,
    this.originalPrice,
    this.billingCycle,
    this.isSubscription = false,
    this.subscriptionInterval,
    this.sortOrder = 0,
    this.remark,
    this.featureList = const [],
  });

  final String id;
  final String planCode;
  final String planType;
  final String planName;
  final String? planDesc;
  final int price;
  final int? originalPrice;
  final String? billingCycle;
  final bool isSubscription;
  final int? subscriptionInterval;
  final int sortOrder;
  final String? remark;
  final List<VipPlanFeature> featureList;

  factory VipPlan.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['featureList'];
    final features = <VipPlanFeature>[];
    if (featuresRaw is List) {
      for (final item in featuresRaw) {
        if (item is Map<String, dynamic>) {
          features.add(VipPlanFeature.fromJson(item));
        } else if (item is Map) {
          features.add(
            VipPlanFeature.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    features.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return VipPlan(
      id: json['id']?.toString() ?? '',
      planCode: json['planCode']?.toString() ?? '',
      planType: json['planType']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      planDesc: json['planDesc']?.toString(),
      price: _asInt(json['price']) ?? 0,
      originalPrice: _asInt(json['originalPrice']),
      billingCycle: json['billingCycle']?.toString(),
      isSubscription: _asBool(json['isSubscription']),
      subscriptionInterval: _asInt(json['subscriptionInterval']),
      sortOrder: _asInt(json['sortOrder']) ?? 0,
      remark: json['remark']?.toString(),
      featureList: features,
    );
  }

  String get priceLabel => '¥$price';

  String get originalPriceLabel {
    final value = originalPrice;
    if (value == null || value <= 0) return '';
    return '¥$value';
  }

  String get billingCycleLabel {
    switch (billingCycle?.trim()) {
      case '1':
        return '年付';
      case '2':
        return '单次';
      case '0':
      default:
        return '月付';
    }
  }

  String get footerLabel => billingCycleLabel;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == '1';
}
