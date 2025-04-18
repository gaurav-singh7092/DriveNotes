import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sync/data/models/note.dart';
import 'package:note_sync/features/notes/providers/notes_provider.dart';
import 'package:intl/intl.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final bool isNewNote;

  const NoteDetailScreen({
    super.key,
    this.noteId,
    this.isNewNote = false,
  });

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isNewNote;

    if (widget.isNewNote) {
      _titleController.text = 'Untitled Note';
      _contentController.text = '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(Note? note) async {
    if (note == null && !widget.isNewNote) {
      setState(() {
        _errorMessage = 'Cannot save changes: Note not found';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final notesNotifier = ref.read(notesProvider.notifier);

      if (widget.isNewNote) {
        final newNote = await notesNotifier.createNote(
          _titleController.text,
          _contentController.text,
        );

        if (newNote != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Note created successfully'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              width: 300,
            ),
          );
          context.go('/notes');
        } else {
          setState(() {
            _errorMessage = 'Failed to create note';
            _isSaving = false;
          });
        }
      } else {
        final updatedNote = note!.copyWith(
          title: _titleController.text,
          content: _contentController.text,
        );

        final result = await notesNotifier.updateNote(updatedNote);

        if (result != null && mounted) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Note updated successfully'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              width: 300,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to update note';
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: colorScheme.error, size: 32),
        title: Text(
          'Delete Note',
          style: TextStyle(
            color: colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
            child: const Text('DELETE'),
          ),
        ],
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
        _errorMessage = '';
      });

      try {
        final notesNotifier = ref.read(notesProvider.notifier);
        final success = await notesNotifier.deleteNote(noteId);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Note deleted'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: colorScheme.primary,
              width: 300,
              action: SnackBarAction(
                label: 'DISMISS',
                textColor: Colors.white.withOpacity(0.8),
                onPressed: () {},
              ),
            ),
          );
          context.go('/notes');
        } else {
          setState(() {
            _errorMessage = 'Failed to delete note';
            _isSaving = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = widget.isNewNote
        ? const AsyncValue.data(null)
        : ref.watch(noteProvider(widget.noteId!));

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
            _isEditing ? colorScheme.primaryContainer.withOpacity(0.7) : null,
        title: Text(
          widget.isNewNote
              ? 'New Note'
              : (_isEditing
                  ? 'Edit Note'
                  : (noteAsync.valueOrNull?.title ?? 'Note')),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _isEditing ? colorScheme.primary : null,
          ),
        ),
        actions: [
          if (!widget.isNewNote && !_isEditing)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
              tooltip: 'Edit note',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!widget.isNewNote && !_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: 'Delete note',
              onPressed: () => _deleteNote(widget.noteId!),
            ),
          if (_isEditing && !widget.isNewNote)
            IconButton(
              icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              tooltip: 'Cancel editing',
              onPressed: () {
                setState(() {
                  _isEditing = false;

                  if (noteAsync.hasValue && noteAsync.value != null) {
                    _titleController.text = noteAsync.value!.title;
                    _contentController.text = noteAsync.value!.content;
                  }
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(
                Icons.check_circle_outline,
                color: _isSaving
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
              tooltip: 'Save changes',
              onPressed: _isSaving
                  ? null
                  : () => _saveChanges(
                        widget.isNewNote ? null : noteAsync.valueOrNull,
                      ),
            ),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (note) {
          if (!widget.isNewNote && note != null && !_isEditing) {
            _titleController.text = note.title;
            _contentController.text = note.content;
          }

          final contentLength = _contentController.text.length;
          final wordCount = _contentController.text.isEmpty
              ? 0
              : _contentController.text.trim().split(RegExp(r'\s+')).length;

          String? lastModified;
          if (note != null) {
            lastModified =
                DateFormat('MMM d, yyyy · h:mm a').format(note.updatedAt);
          }

          return Column(
            children: [
              if (_errorMessage.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: colorScheme.onErrorContainer, size: 20),
                        onPressed: () => setState(() => _errorMessage = ''),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              if (_isEditing)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Editing mode',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _titleController,
                  enabled: _isEditing,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isEditing
                            ? colorScheme.primary.withOpacity(0.5)
                            : colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    filled: !_isEditing,
                    fillColor: !_isEditing
                        ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _isEditing
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _contentController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      alignLabelWithHint: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isEditing
                              ? colorScheme.primary.withOpacity(0.5)
                              : colorScheme.outline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      filled: !_isEditing,
                      fillColor: !_isEditing
                          ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                          : null,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: _isEditing
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: '$contentLength characters',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const TextSpan(text: ' · '),
                          TextSpan(text: '$wordCount words'),
                        ],
                      ),
                    ),
                    if (lastModified != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.update,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lastModified,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (_isSaving)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: colorScheme.surface.withOpacity(0.8),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Saving...',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
