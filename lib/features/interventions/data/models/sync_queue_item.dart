class SyncAction {
  static const String create = 'create';
  static const String update = 'update';
}

class SyncQueueItem {
  final int? id; // null avant l'insertion (AUTOINCREMENT)
  final String interventionId;
  final String actionType;
  final String payload; // JSON de l'intervention à envoyer
  final String createdAt;
  final int retryCount;

  const SyncQueueItem({
    this.id,
    required this.interventionId,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory SyncQueueItem.fromMap(Map<String, Object?> map) {
    return SyncQueueItem(
      id: map['id'] as int,
      interventionId: map['intervention_id'] as String,
      actionType: map['action_type'] as String,
      payload: map['payload'] as String,
      createdAt: map['created_at'] as String,
      retryCount: map['retry_count'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'intervention_id': interventionId,
      'action_type': actionType,
      'payload': payload,
      'created_at': createdAt,
      'retry_count': retryCount,
    };
  }
}