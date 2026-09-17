export interface Student {
  studentCode: string;
  fullName: string;
  email: string;
  department: string;
  role: "student";
}
export interface Course {
  courseId: string;
  courseCode: string;
  courseName: string;
  categoryName: string;
  summary: string;
  startsAt: string;
  endsAt: string | null;
  teacherNames: string | null;
}
export interface DeepLink {
  deepLink: null;
  deepLinkStatus: "TO_VERIFY_DLU";
}
export interface Content extends DeepLink {
  courseCode: string;
  sectionNumber: number;
  sectionName: string;
  courseModuleId: string;
  position: number;
  activityType: string;
  activityName: string;
  description: string;
  assignmentCode: string | null;
  dueAt: string | null;
  filenames: string | null;
  totalSizeBytes: number | null;
}
export interface Resource extends DeepLink {
  courseId: string;
  courseCode: string;
  courseName: string;
  sectionName: string;
  resourceId: string;
  resourceName: string;
  description: string;
  filename: string | null;
  fileSizeBytes: number | null;
  mimeType: string | null;
}
export interface Assignment extends DeepLink {
  courseId: string;
  courseCode: string;
  courseName: string;
  assignmentId: string;
  assignmentCode: string;
  assignmentName: string;
  description: string;
  opensAt: string;
  dueAt: string;
  maxGrade: number;
}
export type SubmissionStatus =
  | "graded"
  | "returned_for_resubmission"
  | "draft"
  | "late"
  | "submitted"
  | "missing"
  | "not_submitted";
export interface AssignmentStatus extends DeepLink {
  courseCode: string;
  courseName: string;
  assignmentCode: string;
  assignmentName: string;
  submissionStatus: SubmissionStatus;
  submittedAt: string | null;
  isLate: boolean;
  attemptNumber: number | null;
}
export interface Grade {
  courseCode: string;
  courseName: string;
  assignmentCode: string;
  gradeItem: string;
  score: number;
  maxGrade: number;
  percentage: number | null;
  gradeResult: string;
  feedback: string | null;
  gradedAt: string;
  teacherName: string;
}
export interface Progress {
  courseId: string;
  courseCode: string;
  courseName: string;
  totalActivities: number;
  completedActivities: number;
  progressPercent: number;
}
export interface Deadline extends DeepLink {
  courseCode: string;
  courseName: string;
  assignmentCode: string;
  assignmentName: string;
  dueAt: string;
  submissionStatus: SubmissionStatus;
  daysRemaining: number;
}
export interface StudentLearningDataSource {
  health(): Promise<void>;
  student(code: string): Promise<Student | null>;
  courses(code: string): Promise<Course[]>;
  content(code: string, courseId: string): Promise<Content[] | null>;
  resources(code: string): Promise<Resource[]>;
  assignments(code: string): Promise<Assignment[]>;
  assignmentStatus(code: string): Promise<AssignmentStatus[]>;
  grades(code: string): Promise<Grade[]>;
  progress(code: string): Promise<Progress[]>;
  deadlines(code: string): Promise<Deadline[]>;
}
