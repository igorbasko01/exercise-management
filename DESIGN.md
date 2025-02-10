# Design
A design document for the exercise management app.
## Data Models
- [x] Exercise Template - A template for an exercise. Contains:
  - [x] Id - A unique identifier for the exercise template.
  - [x] Name - The name of the exercise.
  - [x] Description - A description of the exercise.
  - [x] Muscle Group - The main muscle group targeted by the exercise.
  - [x] Repetition Range - The range of repetitions for the exercise.
- [x] Exercise Set - A set that was done for an exercise. Contains:
  - [x] Id - A unique identifier for the exercise set.
  - [x] Date - The date that the set was done.
  - [x] Exercise Template Id - The id of the exercise template that the set was done for.
  - [x] Equipment Weight - The weight of the equipment used for the set.
  - [x] Plates Weight - The weight of the plates used for the set.
  - [x] Repetitions - The number of repetitions done for the set.
## Repositories
- [x] Exercise Template Repository - A repository for managing exercise templates. Contains:
  - [x] Create Exercise Template - Creates a new exercise template.
  - [x] Get Exercise Template - Gets an exercise template by id.
  - [x] Get Exercise Templates - Gets all exercise templates.
  - [x] Update Exercise Template - Updates an exercise template.
  - [x] Delete Exercise Template - Deletes an exercise template.
- [ ] Exercise Set Repository - A repository for managing exercise sets. Contains:
  - [ ] Create Exercise Set - Creates a new exercise set.
  - [ ] Get Exercise Set - Gets an exercise set by id.
  - [ ] Get Exercise Sets - Gets all exercise sets.
  - [ ] Update Exercise Set - Updates an exercise set.
  - [ ] Delete Exercise Set - Deletes an exercise set.
  - [ ] Get Exercise Sets By Exercise Template Id - Gets all exercise sets for an exercise template.
  - [ ] Get Exercise Sets By Date - Gets all exercise sets for a date.
  - [ ] Get Latest Exercise Set by Exercise Template Id - Gets the latest exercise set for an exercise template.
## Services
- [ ] Exercise Template Service - A service for managing exercise templates. Contains:
  - [ ] Create Exercise Template - Creates a new exercise template.
  - [ ] Get Exercise Template - Gets an exercise template by id.
  - [ ] Get Exercise Templates - Gets all exercise templates.
  - [ ] Update Exercise Template - Updates an exercise template. Only allow update if no exercise sets are associated with the template.
  - [ ] Delete Exercise Template - Deletes an exercise template. Only allow delete if no exercise sets are associated with the template.
## Presentation Layer
- [ ] Main Screen - The main screen of the app. Contains:
  - [ ] Navigation Drawer - A drawer that allows the user to navigate to different screens:
    - [ ] Exercise Templates Screen - A screen that displays a list of exercise templates.
    - [ ] Exercise Sets Screen - A screen that displays a list of exercise sets.
  - [ ] Welcome Message - A message that welcomes the user to the app.
- [ ] Exercise Template List Screen - A screen that displays a list of exercise templates. Should allow the user to:
  - [ ] Create Exercise Template - Navigates to the create exercise template screen.
  - [ ] View Exercise Template - Navigates to the exercise template detail screen.
- [ ] Exercise Template Detail Screen - A screen that displays the details of an exercise template. Should allow the user to:
  - [ ] Edit Exercise Template - Navigates to the edit exercise template screen. Only allow edit if no exercise sets are associated with the template.
  - [ ] Delete Exercise Template - Deletes the exercise template. Only allow delete if no exercise sets are associated with the template.
- [ ] Exercise Set List Screen - A screen that displays a list of exercise sets, sorted by date descending. Should allow the user to:
  - [ ] Create Exercise Set - Navigates to the create exercise set screen.
  - [ ] View Exercise Set - Navigates to the exercise set detail screen.
- [ ] Exercise Set Detail Screen - A screen that displays the details of an exercise set. Should allow the user to:
  - [ ] Edit Exercise Set - Navigates to the edit exercise set screen.
  - [ ] Delete Exercise Set - Deletes the exercise set.