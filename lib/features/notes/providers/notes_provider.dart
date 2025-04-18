import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_sync/data/models/note.dart';
import 'package:note_sync/features/auth/providers/auth_provider.dart';
import 'package:note_sync/features/notes/services/drive_service.dart';

// Drive service provider
final driveServiceProvider = Provider<DriveService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return DriveService(authService: authService);
});

// Notes state notifier
class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    // Initial state is an empty list
    return [];
  }

  // Fetch all notes from Drive
  Future<void> fetchNotes() async {
    state = const AsyncValue.loading();

    try {
      final driveService = ref.read(driveServiceProvider);
      final notes = await driveService.getNotes();

      // Sort by modified date (newest first)
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Get a note by ID
  Future<Note?> getNoteById(String noteId) async {
    try {
      // Check if the note is already in the state
      if (state.hasValue) {
        final stateNotes = state.value!;
        final existingNote =
            stateNotes.where((n) => n.id == noteId).firstOrNull;

        if (existingNote != null) {
          return existingNote;
        }
      }

      // Otherwise fetch from Drive
      final driveService = ref.read(driveServiceProvider);
      return await driveService.getNoteById(noteId);
    } catch (e) {
      // If there's an error, let the caller handle it
      return null;
    }
  }

  // Create a new note
  Future<Note?> createNote(String title, String content) async {
    try {
      final driveService = ref.read(driveServiceProvider);
      final newNote = await driveService.createNote(title, content);

      // Update state with the new note
      state.whenData((notes) {
        state = AsyncValue.data([newNote, ...notes]);
      });

      return newNote;
    } catch (e) {
      // Report error but don't change state
      return null;
    }
  }

  // Update an existing note
  Future<Note?> updateNote(Note updatedNote) async {
    try {
      final driveService = ref.read(driveServiceProvider);
      final note = await driveService.updateNote(updatedNote);

      // Update the note in the state
      state.whenData((notes) {
        final updatedNotes = notes.map((n) {
          return n.id == updatedNote.id ? note : n;
        }).toList();

        // Sort by modified date (newest first)
        updatedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        state = AsyncValue.data(updatedNotes);
      });

      return note;
    } catch (e) {
      // Report error but don't change state
      return null;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      final driveService = ref.read(driveServiceProvider);
      final success = await driveService.deleteNote(noteId);

      if (success) {
        // Remove the deleted note from the state
        state.whenData((notes) {
          final updatedNotes = notes.where((n) => n.id != noteId).toList();
          state = AsyncValue.data(updatedNotes);
        });
      }

      return success;
    } catch (e) {
      return false;
    }
  }
}

// Provider for the notes notifier
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(() {
  return NotesNotifier();
});

// Provider for a single note by ID
final noteProvider = FutureProvider.family<Note?, String>((ref, noteId) async {
  final notesNotifier = ref.read(notesProvider.notifier);
  return notesNotifier.getNoteById(noteId);
});
