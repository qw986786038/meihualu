class CreateAndPayResult {
  const CreateAndPayResult({
    required this.orderId,
    required this.orderNo,
    required this.planName,
    required this.planId,
    required this.amount,
    required this.orderStatus,
    required this.channel,
    required this.tradeType,
    required this.payPayload,
  });

  final String orderId;
  final String orderNo;
  final String planName;
  final String planId;
  final String amount;
  final String orderStatus;
  final String channel;
  final String tradeType;
  final String payPayload;

  factory CreateAndPayResult.fromJson(Map<String, dynamic> json) {
    return CreateAndPayResult(
      orderId: json['orderId']?.toString() ?? '',
      orderNo: json['orderNo']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      tradeType: json['tradeType']?.toString() ?? '',
      payPayload: json['payPayload']?.toString() ?? '',
    );
  }
}
