import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sync/data/models/note.dart';
import 'package:note_sync/features/notes/providers/notes_provider.dart';
import 'package:note_sync/presentation/screens/notes_list_screen.dart';

// Mock notes provider for testing
final mockNotesProvider =
    AsyncNotifierProvider<MockNotesNotifier, List<Note>>(() {
  return MockNotesNotifier();
});

class MockNotesNotifier extends NotesNotifier {
  @override
  Future<List<Note>> build() async {
    // Return test data
    return [
      Note(
        id: '1',
        title: 'Test Note 1',
        content: 'This is test content for note 1',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        fileId: 'file1',
      ),
      Note(
        id: '2',
        title: 'Test Note 2',
        content: 'This is test content for note 2',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        fileId: 'file2',
      ),
    ];
  }

  @override
  Future<void> fetchNotes() async {
    // Mock fetch operation - we're already returning data in build()
    return;
  }

  @override
  Future<bool> deleteNote(String noteId) async {
    // Mock successful deletion for testing
    state.whenData((notes) {
      final updatedNotes = notes.where((n) => n.id != noteId).toList();
      state = AsyncValue.data(updatedNotes);
    });
    return true;
  }
}

void main() {
  testWidgets('NotesListScreen displays notes correctly',
      (WidgetTester tester) async {
    // Override the notes provider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesProvider.overrideWith(() => MockNotesNotifier()),
        ],
        child: const MaterialApp(
          home: NotesListScreen(),
        ),
      ),
    );

    // Initial build will show loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump the widget until fully loaded
    await tester.pumpAndSettle();

    // Check if notes are displayed
    expect(find.text('Test Note 1'), findsOneWidget);
    expect(find.text('Test Note 2'), findsOneWidget);
    expect(find.text('This is test content for note 1'), findsOneWidget);
    expect(find.text('This is test content for note 2'), findsOneWidget);

    // Check for the add note button
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
