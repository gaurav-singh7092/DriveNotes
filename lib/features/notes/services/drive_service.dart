import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:note_sync/data/models/note.dart';
import 'package:note_sync/features/auth/services/auth_service.dart';

class DriveService {
  static const String _driveNotesFolder = 'DriveNotes';

  final AuthService _authService;
  String? _driveNotesFolderId;

  drive.DriveApi? _cachedDriveApi;
  DateTime? _apiClientExpiryTime;

  DriveService({required AuthService authService}) : _authService = authService;

  Future<String> _getDriveNotesFolderId(drive.DriveApi driveApi) async {
    if (_driveNotesFolderId != null) {
      return _driveNotesFolderId!;
    }

    try {
      final folderList = await driveApi.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and name='$_driveNotesFolder' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        _driveNotesFolderId = folderList.files!.first.id;
        return _driveNotesFolderId!;
      }

      final folder = drive.File()
        ..name = _driveNotesFolder
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(folder);
      _driveNotesFolderId = createdFolder.id!;

      return _driveNotesFolderId!;
    } catch (e) {
      debugPrint('Error getting/creating DriveNotes folder: $e');
      rethrow;
    }
  }

  Future<drive.DriveApi> _getDriveApi() async {
    try {
      final now = DateTime.now();
      if (_cachedDriveApi != null &&
          _apiClientExpiryTime != null &&
          now.isBefore(_apiClientExpiryTime!)) {
        return _cachedDriveApi!;
      }

      final credentials = await _authService.refreshCredentialsIfNeeded();

      if (credentials == null) {
        throw Exception('No valid credentials available');
      }

      final httpClient = http.Client();
      final client = authenticatedClient(httpClient, credentials);

      _cachedDriveApi = drive.DriveApi(client);
      _apiClientExpiryTime = now.add(const Duration(minutes: 50));

      return _cachedDriveApi!;
    } catch (e) {
      debugPrint('Error initializing DriveApi: $e');
      rethrow;
    }
  }

  Future<List<Note>> getNotes() async {
    try {
      final driveApi = await _getDriveApi();
      final folderId = await _getDriveNotesFolderId(driveApi);

      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and mimeType='text/plain' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name, createdTime, modifiedTime)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return [];
      }

      final notes = <Note>[];

      for (final fileObj in fileList.files!) {
        try {
          final drive.File file = fileObj;

          final media = await driveApi.files.get(
            file.id!,
            downloadOptions: drive.DownloadOptions.fullMedia,
          ) as drive.Media;

          final content = await _readMediaContent(media);

          notes.add(
            Note.fromDriveFile(
              fileId: file.id!,
              title: file.name ?? 'Untitled Note',
              content: content,
              createdTime: file.createdTime,
              modifiedTime: file.modifiedTime,
            ),
          );
        } catch (e) {
          debugPrint('Error fetching note content: $e');
        }
      }

      return notes;
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      rethrow;
    }
  }

  Future<String> _readMediaContent(drive.Media media) async {
    final completer = Completer<String>();
    final contents = <String>[];

    media.stream.listen(
      (data) {
        contents.add(String.fromCharCodes(data));
      },
      onDone: () {
        completer.complete(contents.join());
      },
      onError: (error) {
        completer.completeError(error);
      },
    );

    return completer.future;
  }

  Future<Note> createNote(String title, String content) async {
    try {
      final driveApi = await _getDriveApi();
      final folderId = await _getDriveNotesFolderId(driveApi);

      final fileMetadata = drive.File()
        ..name = '$title.txt'
        ..parents = [folderId]
        ..mimeType = 'text/plain';

      final media = drive.Media(
        Stream.value(content.codeUnits),
        content.length,
        contentType: 'text/plain',
      );

      final createdFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      return Note.fromDriveFile(
        fileId: createdFile.id!,
        title: title,
        content: content,
        createdTime: createdFile.createdTime,
        modifiedTime: createdFile.modifiedTime,
      );
    } catch (e) {
      debugPrint('Error creating note: $e');
      rethrow;
    }
  }

  Future<Note> updateNote(Note note) async {
    try {
      final driveApi = await _getDriveApi();

      final media = drive.Media(
        Stream.value(note.content.codeUnits),
        note.content.length,
        contentType: 'text/plain',
      );

      final fileMetadata = drive.File();
      if (!note.title.endsWith('.txt')) {
        fileMetadata.name = '${note.title}.txt';
      } else {
        fileMetadata.name = note.title;
      }

      final updatedFile = await driveApi.files.update(
        fileMetadata,
        note.fileId,
        uploadMedia: media,
      );

      return Note.fromDriveFile(
        fileId: updatedFile.id!,
        title: note.title,
        content: note.content,
        createdTime: note.createdAt,
        modifiedTime: updatedFile.modifiedTime,
      );
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  Future<bool> deleteNote(String fileId) async {
    try {
      final driveApi = await _getDriveApi();
      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      return false;
    }
  }

  Future<Note?> getNoteById(String fileId) async {
    try {
      final driveApi = await _getDriveApi();

      final fileObj = await driveApi.files.get(
        fileId,
        $fields: 'id, name, createdTime, modifiedTime',
      );

      final drive.File file = fileObj as drive.File;

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final content = await _readMediaContent(media);

      return Note.fromDriveFile(
        fileId: file.id!,
        title: file.name ?? 'Untitled Note',
        content: content,
        createdTime: file.createdTime,
        modifiedTime: file.modifiedTime,
      );
    } catch (e) {
      debugPrint('Error fetching note: $e');
      return null;
    }
  }
}
