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

class Task {
  final String id;
  final String goalId;
  final String title;
  final bool completed;

  const Task({
    required this.id,
    required this.goalId,
    required this.title,
    this.completed = false,
  });
}

class Step {
  final String id;
  final String taskId;
  final String title;
  final bool completed;

  const Step({
    required this.id,
    required this.taskId,
    required this.title,
    this.completed = false,
  });
}

/// Temporary in-memory sample data so the UI has something to show
/// before real persistence/storage is wired up.
final List<Goal> sampleGoals = [
  const Goal(id: '1', title: 'Learn Mandarin', taskCount: 5, completedTaskCount: 2),
  const Goal(id: '2', title: 'Finish bamboo conduit project', taskCount: 3, completedTaskCount: 1),
  const Goal(id: '3', title: 'Release Goal Tracker on Play Store', taskCount: 8, completedTaskCount: 6),
];

final List<Task> sampleTasks = [
  const Task(id: 't1', goalId: '1', title: 'Learn the four tones', completed: true),
  const Task(id: 't2', goalId: '1', title: 'Memorize 100 basic characters', completed: true),
  const Task(id: 't3', goalId: '1', title: 'Complete HSK1 vocabulary list', completed: false),
  const Task(id: 't4', goalId: '1', title: 'Practice speaking with a tutor', completed: false),
  const Task(id: 't5', goalId: '1', title: 'Watch a beginner Mandarin show', completed: false),

  const Task(id: 't6', goalId: '2', title: 'Source large-diameter bamboo', completed: true),
  const Task(id: 't7', goalId: '2', title: 'Cure and treat the bamboo', completed: false),
  const Task(id: 't8', goalId: '2', title: 'Run cable through conduit', completed: false),

  const Task(id: 't9', goalId: '3', title: 'Fix release build crashes', completed: true),
  const Task(id: 't10', goalId: '3', title: 'Set up Play Console billing', completed: true),
  const Task(id: 't11', goalId: '3', title: 'Finish translation coverage', completed: true),
  const Task(id: 't12', goalId: '3', title: 'Add monetization tiers', completed: true),
  const Task(id: 't13', goalId: '3', title: 'Polish onboarding flow', completed: true),
  const Task(id: 't14', goalId: '3', title: 'Submit for review', completed: true),
  const Task(id: 't15', goalId: '3', title: 'Respond to review feedback', completed: false),
  const Task(id: 't16', goalId: '3', title: 'Public launch', completed: false),
];

final List<Step> sampleSteps = [
  const Step(id: 's1', taskId: 't3', title: 'Review HSK1 word list part 1', completed: true),
  const Step(id: 's2', taskId: 't3', title: 'Review HSK1 word list part 2', completed: false),
  const Step(id: 's3', taskId: 't3', title: 'Self-test all 150 words', completed: false),

  const Step(id: 's4', taskId: 't4', title: 'Book a session with tutor', completed: false),
  const Step(id: 's5', taskId: 't4', title: 'Prepare topics to discuss', completed: false),

  const Step(id: 's6', taskId: 't7', title: 'Sand and clean sections', completed: true),
  const Step(id: 's7', taskId: 't7', title: 'Apply borax treatment', completed: false),
  const Step(id: 's8', taskId: 't7', title: 'Let cure for required time', completed: false),

  const Step(id: 's9', taskId: 't15', title: 'Read reviewer feedback notes', completed: false),
  const Step(id: 's10', taskId: 't15', title: 'Make requested changes', completed: false),
  const Step(id: 's11', taskId: 't15', title: 'Resubmit for review', completed: false),
];

List<Task> tasksForGoal(String goalId) =>
    sampleTasks.where((t) => t.goalId == goalId).toList();

List<Step> stepsForTask(String taskId) =>
    sampleSteps.where((s) => s.taskId == taskId).toList();

/// A Task is only considered completed if ALL of its Steps are completed.
/// If a Task has no Steps yet, its own stored 'completed' flag is used
/// as a fallback (nothing to derive from).
bool isTaskCompleted(Task task) {
  final steps = stepsForTask(task.id);
  if (steps.isEmpty) return task.completed;
  return steps.every((s) => s.completed);
}

/// A Goal is only considered completed if ALL of its Tasks are
/// derived-completed (per isTaskCompleted above).
bool isGoalCompleted(Goal goal) {
  final tasks = tasksForGoal(goal.id);
  if (tasks.isEmpty) return false;
  return tasks.every((t) => isTaskCompleted(t));
}

// --- CRUD operations -------------------------------------------------
// Simple in-memory mutation helpers. Cascading deletes remove children
// (and grandchildren) so the data never contains orphaned Tasks/Steps.

int _nextGoalIdSeed = 100;
int _nextTaskIdSeed = 100;
int _nextStepIdSeed = 100;

String _newGoalId() => 'g${_nextGoalIdSeed++}';
String _newTaskId() => 't${_nextTaskIdSeed++}';
String _newStepId() => 's${_nextStepIdSeed++}';

Goal addGoal(String title) {
  final goal = Goal(id: _newGoalId(), title: title);
  sampleGoals.add(goal);
  return goal;
}

void updateGoalTitle(Goal goal, String newTitle) {
  final index = sampleGoals.indexWhere((g) => g.id == goal.id);
  if (index == -1) return;
  sampleGoals[index] = Goal(
    id: goal.id,
    title: newTitle,
    taskCount: goal.taskCount,
    completedTaskCount: goal.completedTaskCount,
  );
}

/// Deletes a Goal and cascades to all its Tasks and their Steps.
/// Returns the number of tasks and steps that were removed, so the
/// caller can show an accurate warning before confirming.
({int taskCount, int stepCount}) goalDeletionImpact(Goal goal) {
  final tasks = tasksForGoal(goal.id);
  final stepCount = tasks.fold<int>(0, (sum, t) => sum + stepsForTask(t.id).length);
  return (taskCount: tasks.length, stepCount: stepCount);
}

void deleteGoal(Goal goal) {
  final tasks = tasksForGoal(goal.id);
  for (final task in tasks) {
    sampleSteps.removeWhere((s) => s.taskId == task.id);
  }
  sampleTasks.removeWhere((t) => t.goalId == goal.id);
  sampleGoals.removeWhere((g) => g.id == goal.id);
}

Task addTask(String goalId, String title) {
  final task = Task(id: _newTaskId(), goalId: goalId, title: title);
  sampleTasks.add(task);
  return task;
}

void updateTaskTitle(Task task, String newTitle) {
  final index = sampleTasks.indexWhere((t) => t.id == task.id);
  if (index == -1) return;
  sampleTasks[index] = Task(
    id: task.id,
    goalId: task.goalId,
    title: newTitle,
    completed: task.completed,
  );
}

/// Deletes a Task and cascades to all its Steps.
/// Returns the number of steps that were removed.
int taskDeletionImpact(Task task) => stepsForTask(task.id).length;

void deleteTask(Task task) {
  sampleSteps.removeWhere((s) => s.taskId == task.id);
  sampleTasks.removeWhere((t) => t.id == task.id);
}

Step addStep(String taskId, String title) {
  final step = Step(id: _newStepId(), taskId: taskId, title: title);
  sampleSteps.add(step);
  return step;
}

void updateStepTitle(Step step, String newTitle) {
  final index = sampleSteps.indexWhere((s) => s.id == step.id);
  if (index == -1) return;
  sampleSteps[index] = Step(
    id: step.id,
    taskId: step.taskId,
    title: newTitle,
    completed: step.completed,
  );
}

void deleteStep(Step step) {
  sampleSteps.removeWhere((s) => s.id == step.id);
}

/// Fraction (0.0 - 1.0) of a Task's Steps that are completed.
/// Falls back to the Task's own completed flag if it has no Steps.
double taskStepProgress(Task task) {
  final steps = stepsForTask(task.id);
  if (steps.isEmpty) return isTaskCompleted(task) ? 1.0 : 0.0;
  final completedCount = steps.where((s) => s.completed).length;
  return completedCount / steps.length;
}

/// Fraction (0.0 - 1.0) of a Goal's Steps (across ALL its Tasks) that
/// are completed. Falls back to the Goal's own completed flag if none
/// of its Tasks have any Steps yet.
double goalStepProgress(Goal goal) {
  final tasks = tasksForGoal(goal.id);
  final allSteps = tasks.expand((t) => stepsForTask(t.id)).toList();
  if (allSteps.isEmpty) return isGoalCompleted(goal) ? 1.0 : 0.0;
  final completedCount = allSteps.where((s) => s.completed).length;
  return completedCount / allSteps.length;
}
