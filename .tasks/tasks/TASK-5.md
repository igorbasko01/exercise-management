---
id: TASK-5
title: create a view to manage exercises
created: 2025-01-13 07:54:34
priority: Medium
category: Feature
owner: None
board: In Progress
---

## Description
- [ ] Create a page to list exercises.
- [ ] Create a page to manage a specific exercise, create, update and delete.

2025-02-12 - I have added a view model with ChangeNotifier for the exercise templates, after that I should continue to creating:
- [ ] Provider for `ExerciseTemplateService`.
- [ ] `ChangeNotifierProvider` for `ExerciseTemplatesViewModel`.
- [ ] Update the `ExerciseTemplatesPage` to consume the `ExerciseTemplatesViewModel` using `Consumer`.
- [ ] The `ExerciseTemplatesPage` should for now just return a widget of the list of exercise templates.
- [ ] Add a floating button that will allow adding a new exercise template, use the `Stack` widget to place the button in the bottom right corner.

## Notes


## History
2025-01-13 07:54:34 - Created

2025-02-12 19:53:49 - Moved to In Progress
