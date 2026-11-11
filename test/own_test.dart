// Part 7: own tests (besides the example). They test real code, no real Firebase.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab05_study_notes/data/auth_repository.dart';
import 'package:lab05_study_notes/data/notes_repository.dart';
import 'package:lab05_study_notes/models/note.dart';

void main() {
  // Create one fake first: it makes FieldValue.serverTimestamp() work in tests.
  setUpAll(FakeFirebaseFirestore.new);

  test('example: messageFor maps weak-password', () {
    expect(AuthRepository.messageFor('weak-password'), contains('6 characters'));
  });

  CollectionReference<Map<String, dynamic>> notesOf(FakeFirebaseFirestore db, String uid) =>
      db.collection('users').doc(uid).collection('notes');

  test('addNote trims the title and stores it without surrounding spaces', () async {
    final db = FakeFirebaseFirestore();
    await NotesRepository(db).addNote('u1', '  Exam  ', 'Room B238');
    final docs = (await notesOf(db, 'u1').get()).docs;
    expect(docs, hasLength(1));
    expect(docs.single.data()['title'], 'Exam');
  });

  test('addNote: 101 characters throws and writes nothing; exactly 100 is accepted', () async {
    final db = FakeFirebaseFirestore();
    final repo = NotesRepository(db);
    await expectLater(repo.addNote('u1', 'a' * 101, ''), throwsArgumentError);
    expect((await notesOf(db, 'u1').get()).docs, isEmpty);

    await repo.addNote('u1', 'a' * 100, '');
    expect((await notesOf(db, 'u1').get()).docs, hasLength(1));
  });

  test('Note.fromFirestore: a non-String body is a FormatException; a missing createdAt is null', () {
    expect(() => Note.fromFirestore('n1', {'title': 'T', 'body': 42}), throwsFormatException);
    final note = Note.fromFirestore('n2', {'title': 'T', 'body': 'B'});
    expect(note.createdAt, isNull);
  });
}
