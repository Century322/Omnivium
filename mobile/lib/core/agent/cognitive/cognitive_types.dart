enum EntityType {
  person,
  project,
  tech,
  concept,
  organization,
  document,
  task,
  goal,
}

enum RelationType {
  owns,
  uses,
  dependsOn,
  partOf,
  knows,
  prefers,
  blocks,
  supports,
  created,
  decided,
}

enum MemoryDomain {
  project,
  personal,
  friend,
  business,
  research,
  entertainment,
}

enum MemoryPersistence {
  permanent,
  longTerm,
  shortTerm,
  ephemeral,
}

enum MemoryType {
  fact,
  decision,
  goal,
  preference,
  rule,
  relationship,
  experience,
  procedure,
}

enum IntentType {
  fact,
  opinion,
  emotion,
  joke,
  sarcasm,
  complaint,
  guess,
  question,
  promise,
  goal,
  task,
  research,
  decision,
  discussion,
  command,
  plan,
}

enum MemoryLifecycle {
  active,
  warm,
  frozen,
}

enum GoalStatus {
  planned,
  inProgress,
  completed,
  abandoned,
  paused,
}

enum EmotionType {
  neutral,
  joy,
  sadness,
  anger,
  fear,
  surprise,
  disgust,
  trust,
  anticipation,
  frustration,
}
