import 'main_staging.dart' as staging;

/// Legacy development target retained for existing local launch commands.
///
/// It intentionally routes to the explicit staging composition so no app
/// entrypoint renders a password-shaped fixture login or silently uses local
/// academic fixture data.
void main() => staging.main();
