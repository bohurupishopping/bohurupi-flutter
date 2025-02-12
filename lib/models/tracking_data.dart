class TrackingData {
  final List<ShipmentData> shipmentData;

  TrackingData({required this.shipmentData});

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      shipmentData: (json['ShipmentData'] as List?)
          ?.map((x) => ShipmentData.fromJson(x))
          .toList() ?? [],
    );
  }
}

class ShipmentData {
  final Shipment shipment;

  ShipmentData({required this.shipment});

  factory ShipmentData.fromJson(Map<String, dynamic> json) {
    return ShipmentData(
      shipment: Shipment.fromJson(json['Shipment'] ?? {}),
    );
  }
}

class Shipment {
  final TrackingStatus status;
  final List<TrackingScan> scans;
  final String? estimatedDeliveryDate;
  final String? promisedDeliveryDate;
  final String? actualDeliveryDate;

  Shipment({
    required this.status,
    required this.scans,
    this.estimatedDeliveryDate,
    this.promisedDeliveryDate,
    this.actualDeliveryDate,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      status: TrackingStatus.fromJson(json['Status'] ?? {}),
      scans: (json['Scans'] as List?)
          ?.map((x) => TrackingScan.fromJson(x))
          .toList() ?? [],
      estimatedDeliveryDate: json['EstimatedDeliveryDate'],
      promisedDeliveryDate: json['PromisedDeliveryDate'],
      actualDeliveryDate: json['ActualDeliveryDate'],
    );
  }
}

class TrackingStatus {
  final String status;
  final String statusDateTime;
  final String statusLocation;
  final String instructions;

  TrackingStatus({
    required this.status,
    required this.statusDateTime,
    required this.statusLocation,
    required this.instructions,
  });

  factory TrackingStatus.fromJson(Map<String, dynamic> json) {
    return TrackingStatus(
      status: json['Status'] ?? '',
      statusDateTime: json['StatusDateTime'] ?? '',
      statusLocation: json['StatusLocation'] ?? '',
      instructions: json['Instructions'] ?? '',
    );
  }
}

class TrackingScan {
  final ScanDetail scanDetail;

  TrackingScan({required this.scanDetail});

  factory TrackingScan.fromJson(Map<String, dynamic> json) {
    return TrackingScan(
      scanDetail: ScanDetail.fromJson(json['ScanDetail'] ?? {}),
    );
  }
}

class ScanDetail {
  final String scan;
  final String scanDateTime;
  final String scanLocation;
  final String instructions;

  ScanDetail({
    required this.scan,
    required this.scanDateTime,
    required this.scanLocation,
    required this.instructions,
  });

  factory ScanDetail.fromJson(Map<String, dynamic> json) {
    return ScanDetail(
      scan: json['Scan'] ?? '',
      scanDateTime: json['ScanDateTime'] ?? '',
      scanLocation: json['ScanLocation'] ?? '',
      instructions: json['Instructions'] ?? '',
    );
  }
} 