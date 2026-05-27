import 'package:get_it/get_it.dart';

import '../data/database.dart';
import '../repository/note_repository.dart';
import '../usecases/delete_note_use_case.dart';
import '../usecases/navigate_link_use_case.dart';
import '../usecases/note_list_use_case.dart';
import '../usecases/quick_note_use_case.dart';
import '../usecases/save_note_use_case.dart';

/// Application-wide service locator.
final getIt = GetIt.instance;

/// Register all application dependencies. Called once before [runApp].
void configureDependencies() {
  // ── Data layer ──────────────────────────────────────────────────────
  getIt.registerLazySingleton<GraphiteDB>(() => GraphiteDB());

  // ── Repository ──────────────────────────────────────────────────────
  getIt.registerLazySingleton<NoteRepository>(
    () => NoteRepository(getIt<GraphiteDB>()),
  );

  // ── Use cases (stateless — new instance per request) ────────────────
  getIt.registerFactory<NoteListUseCase>(
    () => NoteListUseCase(getIt<NoteRepository>()),
  );
  getIt.registerFactory<QuickNoteUseCase>(
    () => QuickNoteUseCase(getIt<NoteRepository>()),
  );
  getIt.registerFactory<DeleteNoteUseCase>(
    () => DeleteNoteUseCase(getIt<NoteRepository>()),
  );
  getIt.registerFactory<SaveNoteUseCase>(
    () => SaveNoteUseCase(getIt<NoteRepository>()),
  );
  getIt.registerFactory<NavigateLinkUseCase>(
    () => NavigateLinkUseCase(getIt<NoteRepository>()),
  );
}
