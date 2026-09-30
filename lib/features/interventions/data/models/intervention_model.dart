import 'dart:convert';

import '../../../../core/constants/sync_status.dart';

class InterventionModel {
  final String id;
  final String title;
  final String clientName;
  final String address;
  final String description;
  final String equipment;
  final String status;
  final String priority;
  final double latitude;
  final double longitude;
  final String scheduledAt;
  final String notes;
  final List<String> photoPaths;
  final String? signaturePath;
  final String updatedAt;
  final String syncStatus;

  const InterventionModel({
    required this.id,
    required this.title,
    required this.clientName,
    required this.address,
    required this.description,
    required this.equipment,
    required this.status,
    required this.priority,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
    required this.updatedAt,
    this.notes = '',
    this.photoPaths = const [],
    this.signaturePath,
    this.syncStatus = SyncStatus.synced,
  });

  InterventionModel copyWith({
    String? status,
    String? notes,
    List<String>? photoPaths,
    String? signaturePath,
    String? updatedAt,
    String? syncStatus,
  }) {
    return InterventionModel(
      id: id,
      title: title,
      clientName: clientName,
      address: address,
      description: description,
      equipment: equipment,
      status: status ?? this.status,
      priority: priority,
      latitude: latitude,
      longitude: longitude,
      scheduledAt: scheduledAt,
      notes: notes ?? this.notes,
      photoPaths: photoPaths ?? this.photoPaths,
      signaturePath: signaturePath ?? this.signaturePath,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Ligne SQLite -> modèle
  factory InterventionModel.fromMap(Map<String, Object?> map) {
    return InterventionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      clientName: map['client_name'] as String,
      address: map['address'] as String,
      description: map['description'] as String,
      equipment: map['equipment'] as String,
      status: map['status'] as String,
      priority: map['priority'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      scheduledAt: map['scheduled_at'] as String,
      notes: map['notes'] as String,
      photoPaths:
          List<String>.from(jsonDecode(map['photo_paths'] as String) as List),
      signaturePath: map['signature_path'] as String?,
      updatedAt: map['updated_at'] as String,
      syncStatus: map['sync_status'] as String,
    );
  }

  /// Modèle -> ligne SQLite
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'client_name': clientName,
      'address': address,
      'description': description,
      'equipment': equipment,
      'status': status,
      'priority': priority,
      'latitude': latitude,
      'longitude': longitude,
      'scheduled_at': scheduledAt,
      'notes': notes,
      'photo_paths': jsonEncode(photoPaths),
      'signature_path': signaturePath,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
    };
  }
}