---
id: TASK-8
title: add service for ExerciseTemplate
created: 2025-02-10 22:18:32
priority: Medium
category: Feature
owner: None
board: Done
---

## Description
Should implement the following methods:
- [ ] Exercise Template Service - A service for managing exercise templates. Contains:
  - [x] Create Exercise Template - Creates a new exercise template.
  - [x] Get Exercise Template - Gets an exercise template by id.
  - [x] Get Exercise Templates - Gets all exercise templates.
  - [ ] Update Exercise Template - Updates an exercise template. Only allow update if no exercise sets are associated with the template.
  - [ ] Delete Exercise Template - Deletes an exercise template. Only allow delete if no exercise sets are associated with the template.

2025-02-11 - I will start working only on the create ang get methods. 
Later when I will create the ExerciseSetRepository, I will add the rest of the methods, as they depend on the ExerciseSetRepository.

2025-03-05 - I went with a different direction of using a ViewModel. I was wrong with the terminology, and basically 
what I thought that a service was, is actually called a use case, or at least it similar in some aspects to what I 
thought that the service should do.

## Notes


## History
2025-02-10 22:18:32 - Created

2025-02-11 07:06:39 - Moved to In Progress

2025-02-11 09:06:06 - Moved to Backlog

2025-03-05 18:14:53 - Moved to Done
