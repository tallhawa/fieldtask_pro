import 'package:equatable/equatable.dart';

enum InterventionStatus { pending, inProgress, done }

enum InterventionPriority { low, medium, high }

class Intervention extends Equatable {
  final String id;
  final String title;
  final String clientName;
  final String address;
  final String description;
  final String equipment;
  final InterventionStatus status;
  final InterventionPriority priority;
  final double latitude;
  final double longitude;
  final DateTime scheduledAt;
  final String notes;
  final List<String> photoPaths;
  final String? signaturePath;
  final DateTime updatedAt;

  const Intervention({
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
  });

  Intervention copyWith({
    InterventionStatus? status,
    String? notes,
    List<String>? photoPaths,
    String? signaturePath,
    DateTime? updatedAt,
  }) {
    return Intervention(
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
    );
  }

  @override
  List<Object?> get props => [id, status, notes, photoPaths, signaturePath, updatedAt];
}