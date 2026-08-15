import 'dart:convert';
import 'dart:io';

const int fixtureSeed = 202608;
const String fixtureVersion = 'MOODLE_SUBSET_V1';

const List<String> selectedTables = <String>[
  'user',
  'course_categories',
  'course',
  'enrol',
  'user_enrolments',
  'course_sections',
  'modules',
  'course_modules',
  'resource',
  'assign',
  'assign_submission',
  'assign_grades',
  'grade_items',
  'grade_grades',
  'files',
  'context',
  'role',
  'role_assignments',
  'course_modules_completion',
  'event',
];

void main(List<String> arguments) {
  final outputRoot = _outputRoot(arguments);
  final dataset = _buildDataset();
  final fixtureDirectory = Directory(
    '${outputRoot.path}${Platform.pathSeparator}database'
    '${Platform.pathSeparator}fixtures',
  )..createSync(recursive: true);
  final subsetDirectory = Directory(
    '${outputRoot.path}${Platform.pathSeparator}database'
    '${Platform.pathSeparator}moodle_subset',
  )..createSync(recursive: true);

  final fixtureFile = File(
    '${fixtureDirectory.path}${Platform.pathSeparator}'
    'dlu_lms_fixture.json',
  );
  final seedFile = File(
    '${subsetDirectory.path}${Platform.pathSeparator}seed.sql',
  );

  fixtureFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(dataset)}\n',
  );
  seedFile.writeAsStringSync(_toSql(dataset));

  final tables = dataset['tables']! as Map<String, Object?>;
  stdout.writeln('Generated deterministic fixture (seed $fixtureSeed):');
  for (final tableName in selectedTables) {
    final rows = tables[tableName]! as List<Object?>;
    stdout.writeln('  $tableName: ${rows.length} rows');
  }
  stdout.writeln('JSON: ${fixtureFile.path}');
  stdout.writeln('SQL:  ${seedFile.path}');
}

Directory _outputRoot(List<String> arguments) {
  if (arguments.isEmpty) {
    return Directory.current;
  }
  if (arguments.length == 2 && arguments.first == '--output-root') {
    return Directory(arguments[1]).absolute;
  }
  stderr.writeln(
    'Usage: dart run tool/generate_moodle_sample_data.dart '
    '[--output-root <repository-root>]',
  );
  exitCode = 64;
  throw const FormatException('Invalid command-line arguments.');
}

Map<String, Object?> _buildDataset() {
  final referenceTime =
      DateTime.utc(2026, 8, 15, 12).millisecondsSinceEpoch ~/ 1000;
  const day = 24 * 60 * 60;
  final random = _DeterministicRandom(fixtureSeed);
  final tables = <String, Object?>{
    for (final tableName in selectedTables) tableName: <Map<String, Object?>>[],
  };

  List<Map<String, Object?>> table(String name) =>
      tables[name]! as List<Map<String, Object?>>;

  final users = table('user');
  const teacherDepartments = <String>[
    'Khoa Mẫu Công nghệ',
    'Khoa Mẫu Kinh tế',
    'Khoa Mẫu Ngoại ngữ',
  ];
  for (var index = 1; index <= 3; index++) {
    users.add(<String, Object?>{
      'id': 100 + index,
      'auth': 'manual',
      'confirmed': 1,
      'deleted': 0,
      'suspended': 0,
      'username': 'gvtest${index.toString().padLeft(3, '0')}',
      'idnumber': 'GVTEST${index.toString().padLeft(3, '0')}',
      'firstname': 'Giảng viên Mẫu $index',
      'lastname': 'Kiểm thử',
      'email': 'gvtest${index.toString().padLeft(3, '0')}@example.test',
      'institution': 'Trường Đại học Mẫu',
      'department': teacherDepartments[index - 1],
      'city': 'Thành phố Mẫu',
      'country': 'VN',
      'lang': 'vi',
      'timezone': 'Asia/Ho_Chi_Minh',
      'picture': 0,
      'timecreated': referenceTime - (500 + index) * day,
      'timemodified': referenceTime - index * day,
    });
  }
  for (var index = 1; index <= 20; index++) {
    users.add(<String, Object?>{
      'id': 1000 + index,
      'auth': 'manual',
      'confirmed': 1,
      'deleted': 0,
      'suspended': 0,
      'username': 'svtest${index.toString().padLeft(3, '0')}',
      'idnumber': 'SVTEST${index.toString().padLeft(3, '0')}',
      'firstname': 'Sinh viên Mẫu ${index.toString().padLeft(2, '0')}',
      'lastname': 'Kiểm thử',
      'email': 'svtest${index.toString().padLeft(3, '0')}@example.test',
      'institution': 'Trường Đại học Mẫu',
      'department': 'Lớp Dữ liệu Tổng hợp ${(index - 1) ~/ 5 + 1}',
      'city': 'Thành phố Mẫu',
      'country': 'VN',
      'lang': 'vi',
      'timezone': 'Asia/Ho_Chi_Minh',
      'picture': 0,
      'timecreated': referenceTime - (300 + index) * day,
      'timemodified': referenceTime - (index % 9) * day,
    });
  }

  final categories = <Map<String, Object?>>[
    <String, Object?>{
      'id': 11,
      'name': 'Khối Công nghệ Mẫu',
      'idnumber': 'CATTEST001',
      'description':
          'Danh mục tổng hợp phục vụ kiểm thử, không phải dữ liệu DLU.',
      'sortorder': 10000,
      'coursecount': 2,
      'visible': 1,
      'depth': 1,
      'path': '/11',
    },
    <String, Object?>{
      'id': 12,
      'name': 'Khối Kinh tế Mẫu',
      'idnumber': 'CATTEST002',
      'description':
          'Danh mục tổng hợp phục vụ kiểm thử, không phải dữ liệu DLU.',
      'sortorder': 20000,
      'coursecount': 2,
      'visible': 1,
      'depth': 1,
      'path': '/12',
    },
    <String, Object?>{
      'id': 13,
      'name': 'Khối Ngoại ngữ Mẫu',
      'idnumber': 'CATTEST003',
      'description':
          'Danh mục tổng hợp phục vụ kiểm thử, không phải dữ liệu DLU.',
      'sortorder': 30000,
      'coursecount': 1,
      'visible': 1,
      'depth': 1,
      'path': '/13',
    },
    <String, Object?>{
      'id': 14,
      'name': 'Khối Kỹ năng Mẫu',
      'idnumber': 'CATTEST004',
      'description':
          'Danh mục tổng hợp phục vụ kiểm thử, không phải dữ liệu DLU.',
      'sortorder': 40000,
      'coursecount': 1,
      'visible': 1,
      'depth': 1,
      'path': '/14',
    },
  ];
  table('course_categories').addAll(categories);

  const courseBlueprints = <Map<String, Object>>[
    <String, Object>{
      'category': 11,
      'shortname': 'DEV-MOB101',
      'fullname': 'Phát triển ứng dụng di động — Mẫu',
    },
    <String, Object>{
      'category': 11,
      'shortname': 'DEV-DAT201',
      'fullname': 'Cơ sở dữ liệu ứng dụng — Mẫu',
    },
    <String, Object>{
      'category': 12,
      'shortname': 'DEV-MGT110',
      'fullname': 'Quản trị dự án số — Mẫu',
    },
    <String, Object>{
      'category': 12,
      'shortname': 'DEV-ECO120',
      'fullname': 'Kinh tế học nền tảng — Mẫu',
    },
    <String, Object>{
      'category': 13,
      'shortname': 'DEV-ENG210',
      'fullname': 'Tiếng Anh học thuật — Mẫu',
    },
    <String, Object>{
      'category': 14,
      'shortname': 'DEV-SKL310',
      'fullname': 'Kỹ năng nghiên cứu — Mẫu',
    },
  ];
  for (var index = 0; index < courseBlueprints.length; index++) {
    final blueprint = courseBlueprints[index];
    table('course').add(<String, Object?>{
      'id': 201 + index,
      'category': blueprint['category'],
      'sortorder': (index + 1) * 10,
      'fullname': blueprint['fullname'],
      'shortname': blueprint['shortname'],
      'idnumber': 'COURSETEST${(index + 1).toString().padLeft(3, '0')}',
      'summary':
          'Học phần dùng dữ liệu tổng hợp cho môi trường phát triển; '
          'không phản ánh lớp học hoặc người học thật.',
      'summaryformat': 1,
      'format': 'topics',
      'startdate': referenceTime - (80 - index * 4) * day,
      'enddate': referenceTime + (100 + index * 5) * day,
      'visible': 1,
      'timecreated': referenceTime - (120 + index) * day,
      'timemodified': referenceTime - (index + 1) * day,
      'enablecompletion': 1,
    });
  }

  table('modules').addAll(<Map<String, Object?>>[
    <String, Object?>{
      'id': 1,
      'name': 'resource',
      'cron': 0,
      'lastcron': 0,
      'search': '',
      'visible': 1,
    },
    <String, Object?>{
      'id': 2,
      'name': 'assign',
      'cron': 60,
      'lastcron': referenceTime - 3600,
      'search': '',
      'visible': 1,
    },
  ]);
  table('role').addAll(<Map<String, Object?>>[
    <String, Object?>{
      'id': 1,
      'name': 'Giảng viên Mẫu',
      'shortname': 'editingteacher',
      'description': 'Vai trò giảng viên trong bộ dữ liệu tổng hợp.',
      'sortorder': 1,
      'archetype': 'editingteacher',
    },
    <String, Object?>{
      'id': 2,
      'name': 'Sinh viên Mẫu',
      'shortname': 'student',
      'description': 'Vai trò sinh viên trong bộ dữ liệu tổng hợp.',
      'sortorder': 2,
      'archetype': 'student',
    },
  ]);

  var sectionId = 2001;
  var courseModuleId = 3001;
  var resourceId = 4001;
  var assignmentId = 5001;
  var moduleContextId = 6101;
  var userEnrolmentId = 7001;
  var roleAssignmentId = 8001;
  var submissionId = 9001;
  var assignmentGradeId = 10001;
  var gradeItemId = 11001;
  var gradeGradeId = 12001;
  var completionId = 13001;
  var eventId = 14001;
  var fileId = 15001;
  const sectionCounts = <int>[4, 5, 6, 3, 7, 8];

  for (
    var courseIndex = 0;
    courseIndex < courseBlueprints.length;
    courseIndex++
  ) {
    final courseId = 201 + courseIndex;
    final categoryId = courseBlueprints[courseIndex]['category']! as int;
    final teacherId = 101 + courseIndex % 3;
    final enrolId = 501 + courseIndex;
    final courseContextId = 6001 + courseIndex;

    table('context').add(<String, Object?>{
      'id': courseContextId,
      'contextlevel': 50,
      'instanceid': courseId,
      'path': '/1/$courseContextId',
      'depth': 2,
      'locked': 0,
    });
    table('enrol').add(<String, Object?>{
      'id': enrolId,
      'enrol': 'manual',
      'status': 0,
      'courseid': courseId,
      'sortorder': 0,
      'name': 'Ghi danh thủ công — dữ liệu tổng hợp',
      'timecreated': referenceTime - 90 * day,
      'timemodified': referenceTime - day,
    });

    final candidateStudents = <int>[
      for (var index = 2; index <= 20; index++) 1000 + index,
    ];
    random.shuffle(candidateStudents);
    final enrolledStudents = <int>[1001, ...candidateStudents.take(10)]..sort();
    final enrolledUsers = <int>[teacherId, ...enrolledStudents];
    for (final userId in enrolledUsers) {
      table('user_enrolments').add(<String, Object?>{
        'id': userEnrolmentId++,
        'status': 0,
        'enrolid': enrolId,
        'userid': userId,
        'timestart': referenceTime - 80 * day,
        'timeend': referenceTime + 120 * day,
        'modifierid': teacherId,
        'timecreated': referenceTime - 80 * day,
        'timemodified': referenceTime - day,
      });
      table('role_assignments').add(<String, Object?>{
        'id': roleAssignmentId++,
        'roleid': userId == teacherId ? 1 : 2,
        'contextid': courseContextId,
        'userid': userId,
        'timemodified': referenceTime - day,
        'modifierid': teacherId,
        'component': '',
        'itemid': 0,
        'sortorder': 0,
      });
    }

    final sections = <Map<String, Object?>>[];
    for (
      var sectionNumber = 0;
      sectionNumber < sectionCounts[courseIndex];
      sectionNumber++
    ) {
      final row = <String, Object?>{
        'id': sectionId++,
        'course': courseId,
        'section': sectionNumber,
        'name': sectionNumber == 0
            ? 'Tổng quan học phần — Mẫu'
            : 'Chủ đề mẫu $sectionNumber',
        'summary': sectionNumber == 0
            ? 'Thông tin tổng hợp dành riêng cho kiểm thử giao diện.'
            : 'Nội dung tổng hợp của chủ đề $sectionNumber.',
        'summaryformat': 1,
        'sequence': '',
        'visible': 1,
        'availability': null,
        'timemodified': referenceTime - day,
      };
      sections.add(row);
      table('course_sections').add(row);
    }
    final moduleIdsBySection = <int, List<int>>{
      for (final section in sections) section['id']! as int: <int>[],
    };

    for (var resourceIndex = 0; resourceIndex < 2; resourceIndex++) {
      final currentResourceId = resourceId++;
      final currentCourseModuleId = courseModuleId++;
      final section = sections[(resourceIndex + 1) % sections.length];
      final sectionRowId = section['id']! as int;
      final currentContextId = moduleContextId++;
      moduleIdsBySection[sectionRowId]!.add(currentCourseModuleId);

      table('resource').add(<String, Object?>{
        'id': currentResourceId,
        'course': courseId,
        'name': 'Tài liệu mẫu ${resourceIndex + 1}',
        'intro':
            'Tệp mô phỏng để kiểm thử metadata tài nguyên; không chứa tài liệu thật.',
        'introformat': 1,
        'display': 0,
        'displayoptions': null,
        'revision': 1,
        'timemodified': referenceTime - (resourceIndex + 1) * day,
      });
      table('course_modules').add(<String, Object?>{
        'id': currentCourseModuleId,
        'course': courseId,
        'module': 1,
        'instance': currentResourceId,
        'section': sectionRowId,
        'idnumber':
            'CMRESTEST${currentCourseModuleId.toString().padLeft(5, '0')}',
        'added': referenceTime - 60 * day,
        'visible': 1,
        'visibleoncoursepage': 1,
        'completion': 2,
        'completionview': 1,
        'completionexpected': referenceTime + (resourceIndex + 1) * 4 * day,
        'availability': null,
      });
      table('context').add(<String, Object?>{
        'id': currentContextId,
        'contextlevel': 70,
        'instanceid': currentCourseModuleId,
        'path': '/1/$courseContextId/$currentContextId',
        'depth': 3,
        'locked': 0,
      });
      table('files').add(<String, Object?>{
        'id': fileId,
        'contenthash': _hex40(fileId * 17),
        'pathnamehash': _hex40(fileId * 31 + 7),
        'contextid': currentContextId,
        'component': 'mod_resource',
        'filearea': 'content',
        'itemid': currentResourceId,
        'filepath': '/',
        'filename': 'tai_lieu_mau_${courseIndex + 1}_${resourceIndex + 1}.pdf',
        'userid': teacherId,
        'filesize': 240000 + courseIndex * 10000 + resourceIndex * 2500,
        'mimetype': 'application/pdf',
        'status': 0,
        'timecreated': referenceTime - 30 * day,
        'timemodified': referenceTime - day,
        'sortorder': resourceIndex,
      });
      fileId++;

      for (
        var studentIndex = 0;
        studentIndex < enrolledStudents.length;
        studentIndex++
      ) {
        if ((studentIndex + resourceIndex + courseIndex) % 3 != 0) {
          table('course_modules_completion').add(<String, Object?>{
            'id': completionId++,
            'coursemoduleid': currentCourseModuleId,
            'userid': enrolledStudents[studentIndex],
            'completionstate': 1,
            'viewed': 1,
            'overrideby': null,
            'timemodified': referenceTime - (studentIndex % 4) * day,
          });
        }
      }
    }

    for (var assignmentIndex = 0; assignmentIndex < 3; assignmentIndex++) {
      final currentAssignmentId = assignmentId++;
      final currentCourseModuleId = courseModuleId++;
      final sectionIndex = <int>[
        1,
        sections.length ~/ 2,
        sections.length - 1,
      ][assignmentIndex].clamp(0, sections.length - 1);
      final sectionRowId = sections[sectionIndex]['id']! as int;
      final currentContextId = moduleContextId++;
      final dueOffsets = <int>[7, 2, -4];
      final dueDate = referenceTime + dueOffsets[assignmentIndex] * day;
      final availableDate = assignmentIndex == 0
          ? referenceTime + day
          : referenceTime - 14 * day;
      final currentGradeItemId = gradeItemId++;
      moduleIdsBySection[sectionRowId]!.add(currentCourseModuleId);

      table('assign').add(<String, Object?>{
        'id': currentAssignmentId,
        'course': courseId,
        'name': 'Bài tập mẫu ${assignmentIndex + 1}',
        'intro':
            'Yêu cầu tổng hợp phục vụ kiểm thử trạng thái nộp và chấm điểm.',
        'introformat': 1,
        'alwaysshowdescription': 1,
        'submissiondrafts': 1,
        'duedate': dueDate,
        'allowsubmissionsfromdate': availableDate,
        'grade': 100,
        'timemodified': referenceTime - day,
        'completionsubmit': 1,
        'cutoffdate': dueDate + 7 * day,
        'gradingduedate': dueDate + 5 * day,
      });
      table('course_modules').add(<String, Object?>{
        'id': currentCourseModuleId,
        'course': courseId,
        'module': 2,
        'instance': currentAssignmentId,
        'section': sectionRowId,
        'idnumber':
            'CMASSIGNTEST${currentCourseModuleId.toString().padLeft(5, '0')}',
        'added': referenceTime - 45 * day,
        'visible': 1,
        'visibleoncoursepage': 1,
        'completion': 2,
        'completionview': 0,
        'completionexpected': dueDate,
        'availability': null,
      });
      table('context').add(<String, Object?>{
        'id': currentContextId,
        'contextlevel': 70,
        'instanceid': currentCourseModuleId,
        'path': '/1/$courseContextId/$currentContextId',
        'depth': 3,
        'locked': 0,
      });
      table('grade_items').add(<String, Object?>{
        'id': currentGradeItemId,
        'courseid': courseId,
        'itemname': 'Bài tập mẫu ${assignmentIndex + 1}',
        'itemtype': 'mod',
        'itemmodule': 'assign',
        'iteminstance': currentAssignmentId,
        'itemnumber': 0,
        'idnumber':
            'GRADEITEMTEST${currentGradeItemId.toString().padLeft(5, '0')}',
        'gradetype': 1,
        'grademax': 100.0,
        'grademin': 0.0,
        'gradepass': 50.0,
        'sortorder': assignmentIndex + 1,
        'hidden': 0,
        'locked': 0,
        'timecreated': referenceTime - 45 * day,
        'timemodified': referenceTime - day,
      });
      table('event').add(<String, Object?>{
        'id': eventId++,
        'name': 'Hạn Bài tập mẫu ${assignmentIndex + 1}',
        'description': 'Sự kiện tổng hợp phục vụ kiểm thử lịch học.',
        'format': 1,
        'categoryid': categoryId,
        'courseid': courseId,
        'groupid': 0,
        'userid': 0,
        'component': 'mod_assign',
        'modulename': 'assign',
        'instance': currentAssignmentId,
        'type': 0,
        'eventtype': 'due',
        'timestart': dueDate,
        'timeduration': 0,
        'timesort': dueDate,
        'visible': 1,
        'uuid': 'EVENTTEST-${courseIndex + 1}-${assignmentIndex + 1}',
        'sequence': 1,
        'timemodified': referenceTime - day,
        'priority': null,
        'location': null,
      });

      for (
        var studentIndex = 0;
        studentIndex < enrolledStudents.length;
        studentIndex++
      ) {
        final studentId = enrolledStudents[studentIndex];
        final stateCode = assignmentIndex == 0
            ? 0
            : (studentId + courseIndex * 3 + assignmentIndex) % 5;
        String? submissionStatus;
        double? score;
        if (stateCode == 1) {
          submissionStatus = 'draft';
        } else if (stateCode >= 2) {
          submissionStatus = 'submitted';
        }
        if (stateCode == 3) {
          score = (42 + (studentId + courseIndex) % 7).toDouble();
        } else if (stateCode == 4) {
          score = (studentId + courseIndex + assignmentIndex).isEven
              ? 76.0 + (studentIndex % 5)
              : 91.0 + (studentIndex % 5);
        }

        if (submissionStatus != null) {
          final submittedAt = dueDate - (1 + studentIndex % 3) * day;
          table('assign_submission').add(<String, Object?>{
            'id': submissionId++,
            'assignment': currentAssignmentId,
            'userid': studentId,
            'timecreated': submittedAt - 3600,
            'timemodified': submittedAt,
            'status': submissionStatus,
            'groupid': 0,
            'attemptnumber': 0,
            'latest': 1,
          });
          if (submissionStatus == 'submitted') {
            table('course_modules_completion').add(<String, Object?>{
              'id': completionId++,
              'coursemoduleid': currentCourseModuleId,
              'userid': studentId,
              // The reference page documents 0-3 semantics while exposing
              // BIT(1). V1 stays within the executable 0/1 projection; pass
              // and fail remain available through grade tables.
              'completionstate': 1,
              'viewed': 1,
              'overrideby': null,
              'timemodified': submittedAt,
            });
          }
        }
        if (score != null) {
          final gradedAt = dueDate + day;
          table('assign_grades').add(<String, Object?>{
            'id': assignmentGradeId++,
            'assignment': currentAssignmentId,
            'userid': studentId,
            'timecreated': gradedAt,
            'timemodified': gradedAt,
            'grader': teacherId,
            'grade': score,
            'attemptnumber': 0,
          });
        }
        table('grade_grades').add(<String, Object?>{
          'id': gradeGradeId++,
          'itemid': currentGradeItemId,
          'userid': studentId,
          'rawgrade': score,
          'rawgrademax': 100.0,
          'rawgrademin': 0.0,
          'usermodified': score == null ? null : teacherId,
          'finalgrade': score,
          'hidden': 0,
          'locked': 0,
          'feedback': score == null
              ? null
              : 'Phản hồi tổng hợp dành cho dữ liệu kiểm thử.',
          'feedbackformat': 1,
          'timecreated': score == null ? null : dueDate + day,
          'timemodified': score == null ? null : dueDate + day,
        });
      }
    }

    for (final section in sections) {
      final currentSectionId = section['id']! as int;
      section['sequence'] = moduleIdsBySection[currentSectionId]!.join(',');
    }
  }

  return <String, Object?>{
    'metadata': <String, Object?>{
      'dataset': 'dlu_lms_synthetic_development_fixture',
      'version': fixtureVersion,
      'seed': fixtureSeed,
      'reference_time_epoch': referenceTime,
      'source_classification': 'SYNTHETIC_DATA',
    },
    'tables': tables,
  };
}

String _toSql(Map<String, Object?> dataset) {
  final buffer = StringBuffer()
    ..writeln('-- GENERATED FILE. DO NOT EDIT BY HAND.')
    ..writeln('-- Generator: tool/generate_moodle_sample_data.dart')
    ..writeln('-- Dataset: SYNTHETIC_DATA / $fixtureVersion')
    ..writeln('-- Seed: $fixtureSeed')
    ..writeln('-- Contains no production DLU records or credentials.')
    ..writeln('SET NAMES utf8mb4;')
    ..writeln('SET FOREIGN_KEY_CHECKS = 0;')
    ..writeln();
  final tables = dataset['tables']! as Map<String, Object?>;
  for (final tableName in selectedTables) {
    final rows = tables[tableName]! as List<Map<String, Object?>>;
    if (rows.isEmpty) {
      continue;
    }
    final columns = rows.first.keys.toList(growable: false);
    buffer
      ..writeln(
        'INSERT INTO `${_sqlIdentifier(tableName)}` '
        '(${columns.map((column) => '`${_sqlIdentifier(column)}`').join(', ')})',
      )
      ..writeln('VALUES');
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final values = columns.map((column) => _sqlValue(row[column])).join(', ');
      buffer.writeln('  ($values)${rowIndex == rows.length - 1 ? ';' : ','}');
    }
    buffer.writeln();
  }
  buffer.writeln('SET FOREIGN_KEY_CHECKS = 1;');
  return buffer.toString();
}

String _sqlIdentifier(String value) => value.replaceAll('`', '``');

String _sqlValue(Object? value) {
  if (value == null) {
    return 'NULL';
  }
  if (value is num) {
    return value is double ? value.toStringAsFixed(5) : value.toString();
  }
  final escaped = value
      .toString()
      .replaceAll(r'\', r'\\')
      .replaceAll("'", "''");
  return "'$escaped'";
}

String _hex40(int value) {
  final base = value.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  return (base * 5).substring(0, 40);
}

class _DeterministicRandom {
  _DeterministicRandom(int seed) : _state = seed & 0x7fffffff;

  int _state;

  int nextInt(int maximum) {
    if (maximum <= 0) {
      throw ArgumentError.value(maximum, 'maximum', 'Must be positive.');
    }
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    return _state % maximum;
  }

  void shuffle<T>(List<T> values) {
    for (var index = values.length - 1; index > 0; index--) {
      final other = nextInt(index + 1);
      final value = values[index];
      values[index] = values[other];
      values[other] = value;
    }
  }
}
