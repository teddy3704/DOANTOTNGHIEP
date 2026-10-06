export interface TeacherProfile {
  teacherCode: string;
  fullName: string;
  email: string;
  department: string;
  role: "teacher";
}
export interface TeachingWork {
  title: string;
  description: string;
  dueAt: string;
  submitted: number;
  studentCount: number;
}
export interface TeachingSection {
  title: string;
  resources: string[];
}
export interface TeachingCourse {
  id: string;
  name: string;
  code: string;
  summary: string;
  studentCount: number;
  work: TeachingWork[];
  sections: TeachingSection[];
}
export interface StudentMonitoring {
  courseId: string;
  studentId: string;
  studentName: string;
  progressPercent: number;
  pendingTasks: number;
  overdueTasks: number;
  riskLevel: string;
}
export interface TeacherSupportDataSource {
  attention?(
    code: string,
  ): Promise<(StudentMonitoring & { courseName: string })[]>;
  teacher(code: string): Promise<TeacherProfile | null>;
  courses(code: string): Promise<TeachingCourse[]>;
  students(code: string, courseId: string): Promise<StudentMonitoring[] | null>;
}
