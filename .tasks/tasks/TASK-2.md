---
id: TASK-2
title: create the data models
created: 2025-01-13 07:53:00
priority: Medium
category: Feature
owner: None
board: Done
---

## Description
Create the following data models:
```
muscle_groug_enum:
  quaadriceps
  hamstrings
  lats
  chest
  biceps

exercise:
  id: unique id
  name: name of the exercise
  main_muscle_group: main muscle group enum
  description (optional): description of the exercise

exercise_set:
  id: unique id
  exercise_id: id of the exercise
  equipment_weight: base equipment weight (such as the barbell weight).
  total_plates_weight: total weight of the plates
  repetitions: number of repetitions

program:
  id: unique id
  name: name of the program
  description (optional): description of the program
  exercises: list of exercises

daily_log:
  date: date of the log
  program_id: id of the program
  performed_exercises: list of exercise_sets ids
```

I think that the basic assumption should be that any update to an exercise or program, should actually create a new version of the program or exercise.
So I won't accidently think that I was doing the exact same exercise or program.

For example if I change the exercises in a program, it means that it is a totally different program.

## Notes


## History
2025-01-13 07:53:00 - Created

2025-01-13 08:25:15 - Moved to In Progress

2025-01-13 08:48:28 - Moved to Done
