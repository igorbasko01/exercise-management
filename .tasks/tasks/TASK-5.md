---
id: TASK-5
title: create a view to manage exercises
created: 2025-01-13 07:54:34
priority: Medium
category: Feature
owner: None
board: Done
---

## Description
- [x] Create a page to list exercise templates.
- [x] Add a button to add a new exercise template.
- [x] Create a page that will allow creating/editing an exercise template.
- [x] The create/edit page should show error messages if the form is invalid. - Does validation per field.
- [x] The create/edit page should have two buttons, one for saving the exercise template and one for canceling the creation/editing. - Back button and save button.

2025-02-12 - I have added a view model with ChangeNotifier for the exercise templates, after that I should continue to creating:
- [x] Provider for `ExerciseTemplateService`.
- [x] `ChangeNotifierProvider` for `ExerciseTemplatesViewModel`.
- [x] Update the `ExerciseTemplatesPage` to consume the `ExerciseTemplatesViewModel` using `Consumer`.
- [x] The `ExerciseTemplatesPage` should for now just return a widget of the list of exercise templates.
- [x] Add a floating button that will allow adding a new exercise template, use the `Stack` widget to place the button in the bottom right corner.

## Notes


## History
2025-01-13 07:54:34 - Created

2025-02-12 19:53:49 - Moved to In Progress

2025-03-05 18:11:46 - Moved to Done
