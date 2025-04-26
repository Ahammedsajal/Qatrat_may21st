class MosqueModel {
  final String id;
  final String name;
  final String? nameAr;
  final double latitude;
  final double longitude;
  final String? address;
  final String? addressAr;

  MosqueModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.nameAr,
    this.address,
    this.addressAr,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: json['id']?.toString() ?? "Unknown",
      name: json['name'] ?? "Unknown",
      nameAr: json['name_ar'],
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      address: json['address'],
      addressAr: json['address_ar'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MosqueModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
