#!/bin/bash
# Adds a "More" icon button (opens the shared More-actions sheet) to
# each Goal, Task, and Step row. Wires Edit/Delete in that sheet to
# the existing _editX()/_deleteX() methods already in each screen.
# Run add_more_actions_sheet.sh FIRST, then this script.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

if [ ! -f "lib/version_a/widgets/more_actions_sheet.dart" ]; then
  echo "Error: more_actions_sheet.dart not found. Run add_more_actions_sheet.sh first."
  exit 1
fi

python3 << 'PYEOF'
def add_import(path, import_line):
    with open(path) as f:
        content = f.read()
    if import_line in content:
        return content
    anchor = "import '../widgets/accessible_dialogs.dart';\n"
    if anchor not in content:
        raise SystemExit(f"Error: could not find import anchor in {path}")
    return content.replace(anchor, anchor + import_line, 1)


def insert_before(path, old_tail, new_snippet, expect=1):
    content = path if isinstance(path, str) and "\n" in path else None

def patch_file(path, import_line, old_tail, new_tail):
    with open(path) as f:
        content = f.read()

    content = add_import(path, import_line) if import_line not in content else content

    count = content.count(old_tail)
    if count != 1:
        raise SystemExit(
            f"Error: expected exactly 1 match for the Row-closing anchor in {path}, found {count}. "
            f"File content may not match what was expected — paste a fresh `cat` of this file."
        )
    content = content.replace(old_tail, new_tail)

    with open(path, "w") as f:
        f.write(content)

    print(f"Added 'More' button to {path}")


# --- Goals screen ---
goals_import = "import '../widgets/more_actions_sheet.dart';\n"
goals_old_tail = """                    ],
                  ),
                );
              },
            ),
    );
  }
}
"""
goals_new_tail = """                      Semantics(
                        button: true,
                        label: 'More actions for ${goal.title}',
                        excludeSemantics: true,
                        onTap: () => showMoreActionsSheet(
                          context,
                          itemTitle: goal.title,
                          onEdit: () => _editGoal(goal),
                          onDelete: () => _deleteGoal(goal),
                        ),
                        child: IconButton(
                          onPressed: () => showMoreActionsSheet(
                            context,
                            itemTitle: goal.title,
                            onEdit: () => _editGoal(goal),
                            onDelete: () => _deleteGoal(goal),
                          ),
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
"""
patch_file("lib/version_a/screens/goals_list_screen.dart", goals_import, goals_old_tail, goals_new_tail)

# --- Tasks screen ---
tasks_import = "import '../widgets/more_actions_sheet.dart';\n"
tasks_old_tail = """                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
"""
tasks_new_tail = """                      Semantics(
                        button: true,
                        label: 'More actions for ${task.title}',
                        excludeSemantics: true,
                        onTap: () => showMoreActionsSheet(
                          context,
                          itemTitle: task.title,
                          onEdit: () => _editTask(task),
                          onDelete: () => _deleteTask(task),
                        ),
                        child: IconButton(
                          onPressed: () => showMoreActionsSheet(
                            context,
                            itemTitle: task.title,
                            onEdit: () => _editTask(task),
                            onDelete: () => _deleteTask(task),
                          ),
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
"""
patch_file("lib/version_a/screens/tasks_list_screen.dart", tasks_import, tasks_old_tail, tasks_new_tail)

# --- Steps screen ---
steps_import = "import '../widgets/more_actions_sheet.dart';\n"
steps_old_tail = """                    ],
                  ),
                );
              },
            ),
    );
  }
}
"""
steps_new_tail = """                      Semantics(
                        button: true,
                        label: 'More actions for ${step.title}',
                        excludeSemantics: true,
                        onTap: () => showMoreActionsSheet(
                          context,
                          itemTitle: step.title,
                          onEdit: () => _editStep(step),
                          onDelete: () => _deleteStep(step),
                        ),
                        child: IconButton(
                          onPressed: () => showMoreActionsSheet(
                            context,
                            itemTitle: step.title,
                            onEdit: () => _editStep(step),
                            onDelete: () => _deleteStep(step),
                          ),
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
"""
patch_file("lib/version_a/screens/steps_list_screen.dart", steps_import, steps_old_tail, steps_new_tail)
PYEOF

echo ""
echo "Done. Run: flutter run"
