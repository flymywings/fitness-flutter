/// Enums mirroring the Postgres enums in Supabase (`difficulty`, `category`, `muscles`).
/// `db` is the exact string stored in the database.
library;

enum Difficulty {
  easy('EASY', 'Easy'),
  medium('MEDIUM', 'Medium'),
  hard('HARD', 'Hard');

  const Difficulty(this.db, this.label);
  final String db;
  final String label;

  static Difficulty fromDb(String? v) =>
      values.firstWhere((e) => e.db == v, orElse: () => easy);
}

enum Category {
  strength('Strength'),
  hypertrophy('Hypertrophy'),
  fatLoss('Fat Loss'),
  endurance('Endurance'),
  generalFitness('General Fitness');

  const Category(this.db);
  final String db;
  String get label => db;

  static Category fromDb(String? v) =>
      values.firstWhere((e) => e.db == v, orElse: () => strength);
}

enum Muscle {
  chest('Chest'),
  back('Back'),
  shoulders('Shoulders'),
  biceps('Biceps'),
  triceps('Triceps'),
  quads('Quads'),
  hamstrings('Hamstrings'),
  glutes('Glutes'),
  calves('Calves'),
  abs('Abs'),
  fullBody('Full Body');

  const Muscle(this.db);
  final String db;
  String get label => db;

  static Muscle fromDb(String? v) =>
      values.firstWhere((e) => e.db == v, orElse: () => fullBody);
}

/// day_of_week in the database: 1 = Sunday ... 7 = Saturday.
const dayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

String dayName(int dayOfWeek) => dayNames[(dayOfWeek - 1).clamp(0, 6)];
