class MosqueModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;

  MosqueModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: json['id']?.toString() ?? "Unknown",
      name: json['name'] ?? "Unknown",
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      address: json['address'],
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
