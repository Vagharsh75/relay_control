class SimCardInfo {
  final int subscriptionId;
  final String carrierName;
  final int slotIndex;

  SimCardInfo({
    required this.subscriptionId,
    required this.carrierName,
    required this.slotIndex,
  });

  factory SimCardInfo.fromMap(Map<String, dynamic> map) {
    return SimCardInfo(
      subscriptionId: map['subscriptionId'] as int,
      carrierName: map['carrierName'] as String? ?? 'Unknown',
      slotIndex: map['slotIndex'] as int? ?? 0,
    );
  }

  String get displayName => 'SIM ${slotIndex + 1}: $carrierName';
}
