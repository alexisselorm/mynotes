import 'package:mynotes/services/cloud/cloud_storage_constants.dart';

class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String text;
  final DateTime createdAt;

  CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
    required this.createdAt,
  });

  CloudNote.fromSnapshot({
    required Map<String, dynamic> snapshot,
    required this.documentId,
  }) : ownerUserId = snapshot[ownerUserIdFieldName] as String,
       text = snapshot[textFieldName] as String,
       createdAt = DateTime.parse(snapshot[createdAtFieldName] as String);
}
