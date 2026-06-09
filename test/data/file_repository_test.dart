import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/core/data/file_repository.dart';

/// Tests for FileRepository — async init pattern and directory traversal.
void main() {
  late Directory tempVault;
  late FileRepository repo;

  setUp(() async {
    // Create a clean temp vault for each test
    tempVault = Directory.systemTemp.createTempSync('graphite_test_vault_');
  });

  tearDown(() async {
    // Clean up temp vault
    if (await tempVault.exists()) {
      await tempVault.delete(recursive: true);
    }
  });

  group('async init pattern', () {
    test('throws when vault is accessed before init()', () async {
      // Create without init — should be in uninitialized state
      repo = FileRepository();

      // Accessing vault-dependent methods before init should throw
      expect(
        () => repo.getNotePath('test'),
        throwsA(isA<Error>()),
      );
    });

    test('init() creates vault directory and makes operations work', () async {
      repo = FileRepository();

      await repo.init(vaultDir: tempVault);

      // Vault directory should exist after init
      expect(await tempVault.exists(), isTrue);

      // Operations should work after init
      expect(repo.getNotePath('hello'), equals('${tempVault.path}/hello.md'));
    });

    test('writeNote and readNote round-trip after init', () async {
      repo = FileRepository();
      await repo.init(vaultDir: tempVault);

      const content = '# Hello\n\nWorld';
      await repo.writeNote('test_note', content);

      final result = await repo.readNote('test_note');
      expect(result, equals(content));
    });
  });

  group('directory traversal', () {
    test('listAllNotes finds files in nested directories', () async {
      repo = FileRepository();
      await repo.init(vaultDir: tempVault);

      // Create nested structure:
      //   vault/
      //     root.md
      //     projects/
      //       dart.md
      //       flutter.md
      await repo.writeNote('root', '# Root');
      await repo.writeNote('projects/dart', '# Dart');
      await repo.writeNote('projects/flutter', '# Flutter');

      final notes = await repo.listAllNotes();

      expect(notes, contains('root.md'));
      expect(notes, contains('projects/dart.md'));
      expect(notes, contains('projects/flutter.md'));
      expect(notes.length, equals(3));
    });

    test('listAllNotes returns empty list for empty vault', () async {
      repo = FileRepository();
      await repo.init(vaultDir: tempVault);

      final notes = await repo.listAllNotes();
      expect(notes, isEmpty);
    });

    test('listAllNotes skips non-md files', () async {
      repo = FileRepository();
      await repo.init(vaultDir: tempVault);

      await repo.writeNote('note', '# Note');
      // Create a non-md file
      await File('${tempVault.path}/readme.txt').writeAsString('hello');

      final notes = await repo.listAllNotes();

      expect(notes, contains('note.md'));
      expect(notes, isNot(contains('readme.txt')));
      expect(notes.length, equals(1));
    });
  });
}
