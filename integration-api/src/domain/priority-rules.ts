// Deterministic decision-support heuristics, not calibrated failure prediction.
// Central names keep score weights and Vietnamese explanations traceable.
export const priorityRules = Object.freeze({
  highThreshold: 65,
  mediumThreshold: 30,
  deadlineHours: Object.freeze({ day: 24, threeDays: 72, week: 168 }),
  deadline: Object.freeze({
    overdue: 70,
    within24Hours: 60,
    within72Hours: 45,
    within168Hours: 25,
    later: 10,
  }),
  returnedWeight: 20,
  draftWeight: 10,
  lowProgressThreshold: 50,
  studentLowProgressWeight: 10,
  teacherLowProgressWeight: 20,
  teacherOverdueWeight: 20,
  teacherOverdueCap: 60,
  teacherPendingWeight: 5,
  teacherPendingCap: 20,
  maxScore: 100,
  recommendedMinutes: 45,
});
