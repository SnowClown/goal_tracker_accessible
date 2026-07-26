#!/bin/bash
# Fixes a naming collision: Flutter's material.dart exports its own
# 'Step' class (used by the Stepper widget), which clashed with our
# own Step model in shared/models.dart. Fix: hide Flutter's Step from
# the material import in steps_list_screen.dart, since we don't use
# Flutter's Stepper widget there.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

TARGET="lib/version_a/screens/steps_list_screen.dart"

if [ ! -f "$TARGET" ]; then
  echo "Error: $TARGET not found."
  exit 1
fi

# Replace just the import line, leaving everything else in the file untouched.
sed -i "s|^import 'package:flutter/material.dart';|import 'package:flutter/material.dart' hide Step;|" "$TARGET"

# Confirm the fix landed
if grep -q "hide Step" "$TARGET"; then
  echo "Fixed import in $TARGET"
else
  echo "Warning: could not find the expected import line to patch. Check $TARGET manually."
  exit 1
fi

echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
