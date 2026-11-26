import 'package:fitness_app/data/fake/fake_repositories.dart';
import 'package:fitness_app/data/fake/fake_store.dart';
import 'package:fitness_app/domain/models/enums.dart';
import 'package:fitness_app/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeStore store;
  late FakeAuthRepository auth;
  late FakePlanRepository plans;
  late FakeWorkoutRepository workouts;

  setUp(() {
    store = FakeStore.seeded();
    auth = FakeAuthRepository(store);
    plans = FakePlanRepository(store);
    workouts = FakeWorkoutRepository(store);
  });

  test('all 5 seed users can log in with the seed password', () async {
    for (final a in List.of(store.accounts)) {
      await auth.signIn(email: a.email, password: FakeStore.seedPassword);
      expect((await auth.getProfile())?.username, a.user.username);
    }
    expect(store.accounts.length, 5);
  });

  test('wrong password gives a friendly error', () async {
    expect(
      () => auth.signIn(email: 'john@seed.test', password: 'nope'),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'Wrong email or password.',
        ),
      ),
    );
  });

  test('private plans are visible only to their creator', () async {
    await auth.signIn(
      email: 'jane@seed.test',
      password: FakeStore.seedPassword,
    );
    final janeSees = await plans.getPlans();
    expect(janeSees.any((p) => p.id == 9002), isFalse); // john's private plan
    expect(janeSees.any((p) => p.id == 9001), isTrue);

    await auth.signOut();
    await auth.signIn(
      email: 'john@seed.test',
      password: FakeStore.seedPassword,
    );
    expect((await plans.getPlans()).any((p) => p.id == 9002), isTrue);
  });

  test('category filter works', () async {
    await auth.signIn(
      email: 'john@seed.test',
      password: FakeStore.seedPassword,
    );
    final fat = await plans.getPlans(category: Category.fatLoss);
    expect(fat, isNotEmpty);
    expect(fat.every((p) => p.category == Category.fatLoss), isTrue);
  });

  test('plan exercises are ordered by day then sort_order', () async {
    final list = await plans.getPlanExercises(9001);
    for (var i = 1; i < list.length; i++) {
      final a = list[i - 1], b = list[i];
      expect(
        a.dayOfWeek < b.dayOfWeek ||
            (a.dayOfWeek == b.dayOfWeek && a.sortOrder <= b.sortOrder),
        isTrue,
      );
    }
  });

  test('create plan then save plan then log workout', () async {
    await auth.signIn(email: 'ana@seed.test', password: FakeStore.seedPassword);
    final id = await plans.createPlan(
      const NewPlan(
        title: 'Test Plan',
        durationWeeks: 4,
        difficulty: Difficulty.easy,
        category: Category.strength,
        isPublic: false,
        exercises: [
          NewPlanExercise(
            exerciseId: 1,
            dayOfWeek: 2,
            sets: 3,
            reps: 10,
            restSeconds: 75,
          ),
        ],
      ),
    );
    expect((await plans.getPlans()).any((p) => p.id == id), isTrue);
    expect((await plans.getPlanExercises(id)).single.reps, 10);
    expect((await plans.getPlanExercises(id)).single.restSeconds, 75);

    await plans.savePlan(9001);
    expect((await plans.getSavedPlans()).any((p) => p.id == 9001), isTrue);
    await plans.unsavePlan(9001);
    expect((await plans.getSavedPlans()).any((p) => p.id == 9001), isFalse);

    await workouts.logWorkout([
      NewWorkoutLog(exerciseId: 1, planId: id, setsDone: 3, repsDone: 30),
    ]);
    final logs = await workouts.getRecentLogs();
    expect(logs.first.exerciseName, 'Barbell Bench Press');
    expect(logs.first.totalRepsDone, 30);
  });

  test('model parsing matches the Supabase row shape', () {
    final user = AppUser.fromJson({
      'id': 'u',
      'username': 'bob',
      'created_at': '2026-11-01T00:00:00Z',
    });
    expect(user.username, 'bob');
    expect(user.createdAt, DateTime.utc(2026, 11, 1));

    final plan = Plan.fromJson({
      'id': 1,
      'title': 'T',
      'duration_weeks': 12,
      'difficulty': 'HARD',
      'is_public': true,
      'created_at': '2026-11-01',
      'category': 'Fat Loss',
      'creator_id': 'u',
      'users': {'username': 'bob'},
    });
    expect(plan.difficulty, Difficulty.hard);
    expect(plan.category, Category.fatLoss);
    expect(plan.creatorName, 'bob');

    final pe = PlanExercise.fromJson({
      'sets': 4,
      'reps': 8,
      'day_of_week': 2,
      'sort_order': 1,
      'rest': 75,
      'exercises': {
        'id': 7,
        'name': 'Barbell Row',
        'primary_muscle_group': 'Back',
      },
    });
    expect(pe.muscle, Muscle.back);
    expect(pe.reps, 8);
    expect(pe.restSeconds, 75);
  });
}
