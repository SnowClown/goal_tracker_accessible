/// Shared data model used by both Version A and Version B.
/// Kept deliberately simple for now — extend as the app grows.
class Goal {
  final String id;
  final String title;
  final int taskCount;
  final int completedTaskCount;

  const Goal({
    required this.id,
    required this.title,
    this.taskCount = 0,
    this.completedTaskCount = 0,
  });
}

/// Temporary in-memory sample data so the UI has something to show
/// before real persistence/storage is wired up.
final List<Goal> sampleGoals = [
  const Goal(id: '1', title: 'Learn Mandarin', taskCount: 5, completedTaskCount: 2),
  const Goal(id: '2', title: 'Finish bamboo conduit project', taskCount: 3, completedTaskCount: 1),
  const Goal(id: '3', title: 'Release Goal Tracker on Play Store', taskCount: 8, completedTaskCount: 6),
];
