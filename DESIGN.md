# Design
A design document for the exercise management app.
## Data Models
- [ ] Exercise Template - A template for an exercise. Contains:
  - [ ] Id - A unique identifier for the exercise template.
  - [ ] Name - The name of the exercise.
  - [ ] Description - A description of the exercise.
  - [ ] Muscle Group - The main muscle group targeted by the exercise.
  - [ ] Repetition Range - The range of repetitions for the exercise.
- [ ] Exercise Set - A set that was done for an exercise. Contains:
  - [ ] Id - A unique identifier for the exercise set.
  - [ ] Date - The date that the set was done.
  - [ ] Exercise Template Id - The id of the exercise template that the set was done for.
  - [ ] Equipment Weight - The weight of the equipment used for the set.
  - [ ] Plates Weight - The weight of the plates used for the set.
  - [ ] Repetitions - The number of repetitions done for the set.
## Repositories
- [ ] Exercise Template Repository - A repository for managing exercise templates. Contains:
  - [ ] Create Exercise Template - Creates a new exercise template.
  - [ ] Get Exercise Template - Gets an exercise template by id.
  - [ ] Get Exercise Templates - Gets all exercise templates.
  - [ ] Update Exercise Template - Updates an exercise template.
  - [ ] Delete Exercise Template - Deletes an exercise template.
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
I'm not sure there is currently a need for services. 
The repositories could be used directly by the UI layer.
## Presentation Layer
- [ ] Main Screen - The main screen of the app. Contains:
  - [ ] Navigation Drawer - A drawer that allows the user to navigate to different screens:
    - [ ] Exercise Templates Screen - A screen that displays a list of exercise templates.
    - [ ] Exercise Sets Screen - A screen that displays a list of exercise sets.
  - [ ] Welcome Message - A message that welcomes the user to the app.
- [ ] Exercise Template List Screen - A screen that displays a list of exercise templates.
- [ ] Exercise Template Detail Screen - A screen that displays the details of an exercise template.
- [ ] Exercise Set List Screen - A screen that displays a list of exercise sets, sorted by date descending.
- [ ] Exercise Set Detail Screen - A screen that displays the details of an exercise set.