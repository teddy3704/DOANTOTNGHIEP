# LMS Mobile Flutter - Agent Instructions

## Project goal
Đây là ứng dụng di động HỖ TRỢ HỌC TẬP trên nền tảng LMS.

Learning Analytics is secondary.
Do not design the app as an analytics-only dashboard.

## Architecture
Flutter -> REST API -> Spring Boot -> PostgreSQL

Flutter must NEVER connect directly to PostgreSQL.

## Main student priorities
- My Courses
- Course content
- Tasks / deadlines
- Assignment and quiz status
- Grades
- Attendance
- Continue Learning
- Reminders
- Moodle deep links

## Main teacher priorities
- Courses
- Student list
- Assignment monitoring
- Submitted / not submitted students
- Quiz monitoring
- Progress monitoring
- Students needing attention
- Moodle deep links

## LMS boundary
Flutter must NOT implement:
- assignment submission
- quiz engine
- grading
- editing Moodle attendance

Instead provide buttons such as:
- "Mở LMS để nộp bài"
- "Mở LMS để làm bài"
- "Mở trên LMS"

Moodle base URL:
https://lms.dlu.edu.vn

## Development IDs
Student development ID: 205
Teacher development ID: 102

These are temporary development values and must not be scattered throughout UI code.

## UI
- Flutter Material 3
- Vietnamese
- clear wording
- responsive
- avoid raw technical exceptions in UI

## Testing
After changes run:

flutter pub get
flutter analyze

Do not claim success unless flutter analyze passes.