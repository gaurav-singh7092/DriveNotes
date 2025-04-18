import 'package:json_annotation/json_annotation.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fileId; // Google Drive file ID

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.fileId,
  });

  // Create a new note with default values
  factory Note.create({
    required String title,
    String content = '',
  }) {
    final now = DateTime.now();
    return Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      fileId: '', // Empty until uploaded to Drive
    );
  }

  // Create a note from a Google Drive file
  factory Note.fromDriveFile({
    required String fileId,
    required String title,
    required String content,
    DateTime? createdTime,
    DateTime? modifiedTime,
  }) {
    final now = DateTime.now();
    return Note(
      id: fileId, // Using fileId as the note id for simplicity
      fileId: fileId,
      title: title,
      content: content,
      createdAt: createdTime ?? now,
      updatedAt: modifiedTime ?? now,
    );
  }

  // Copy constructor with optional parameter overrides
  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    String? fileId,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      fileId: fileId ?? this.fileId,
    );
  }

  // JSON serialization
  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
  Map<String, dynamic> toJson() => _$NoteToJson(this);
}
