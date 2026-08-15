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
  const teacherProfiles = <Map<String, String>>[
    <String, String>{
      'firstname': 'Minh Quang',
      'lastname': 'Nguyễn',
      'email': 'nguyen.minh.quang@example.test',
      'department': 'Khoa Công nghệ Thông tin',
    },
    <String, String>{
      'firstname': 'Thu Hà',
      'lastname': 'Lê',
      'email': 'le.thu.ha@example.test',
      'department': 'Khoa Kinh tế và Quản trị Kinh doanh',
    },
    <String, String>{
      'firstname': 'Quốc Bảo',
      'lastname': 'Trần',
      'email': 'tran.quoc.bao@example.test',
      'department': 'Khoa Ngoại ngữ',
    },
  ];
  for (var index = 1; index <= 3; index++) {
    final profile = teacherProfiles[index - 1];
    users.add(<String, Object?>{
      'id': 100 + index,
      'auth': 'manual',
      'confirmed': 1,
      'deleted': 0,
      'suspended': 0,
      'username': 'gvtest${index.toString().padLeft(3, '0')}',
      'idnumber': 'GVTEST${index.toString().padLeft(3, '0')}',
      'firstname': profile['firstname'],
      'lastname': profile['lastname'],
      'email': profile['email'],
      'institution': 'Trường Đại học Đà Lạt',
      'department': profile['department'],
      'city': 'Đà Lạt',
      'country': 'VN',
      'lang': 'vi',
      'timezone': 'Asia/Ho_Chi_Minh',
      'picture': 0,
      'timecreated': referenceTime - (500 + index) * day,
      'timemodified': referenceTime - index * day,
    });
  }
  const studentProfiles = <Map<String, String>>[
    <String, String>{
      'firstname': 'Minh Anh',
      'lastname': 'Nguyễn',
      'email': 'nguyen.minh.anh@example.test',
    },
    <String, String>{
      'firstname': 'Gia Hân',
      'lastname': 'Trần',
      'email': 'tran.gia.han@example.test',
    },
    <String, String>{
      'firstname': 'Hoàng Nam',
      'lastname': 'Lê',
      'email': 'le.hoang.nam@example.test',
    },
    <String, String>{
      'firstname': 'Khánh Linh',
      'lastname': 'Phạm',
      'email': 'pham.khanh.linh@example.test',
    },
    <String, String>{
      'firstname': 'Đức Anh',
      'lastname': 'Võ',
      'email': 'vo.duc.anh@example.test',
    },
    <String, String>{
      'firstname': 'Thanh Trúc',
      'lastname': 'Bùi',
      'email': 'bui.thanh.truc@example.test',
    },
    <String, String>{
      'firstname': 'Nhật Minh',
      'lastname': 'Đặng',
      'email': 'dang.nhat.minh@example.test',
    },
    <String, String>{
      'firstname': 'Ngọc Mai',
      'lastname': 'Hồ',
      'email': 'ho.ngoc.mai@example.test',
    },
    <String, String>{
      'firstname': 'Quang Huy',
      'lastname': 'Đỗ',
      'email': 'do.quang.huy@example.test',
    },
    <String, String>{
      'firstname': 'Thảo Vy',
      'lastname': 'Phan',
      'email': 'phan.thao.vy@example.test',
    },
    <String, String>{
      'firstname': 'Tuấn Kiệt',
      'lastname': 'Vũ',
      'email': 'vu.tuan.kiet@example.test',
    },
    <String, String>{
      'firstname': 'Hải Yến',
      'lastname': 'Nguyễn',
      'email': 'nguyen.hai.yen@example.test',
    },
    <String, String>{
      'firstname': 'Minh Khoa',
      'lastname': 'Trương',
      'email': 'truong.minh.khoa@example.test',
    },
    <String, String>{
      'firstname': 'Bảo Ngọc',
      'lastname': 'Lý',
      'email': 'ly.bao.ngoc@example.test',
    },
    <String, String>{
      'firstname': 'Quốc Khánh',
      'lastname': 'Mai',
      'email': 'mai.quoc.khanh@example.test',
    },
    <String, String>{
      'firstname': 'Thùy Dương',
      'lastname': 'Cao',
      'email': 'cao.thuy.duong@example.test',
    },
    <String, String>{
      'firstname': 'Thành Đạt',
      'lastname': 'Dương',
      'email': 'duong.thanh.dat@example.test',
    },
    <String, String>{
      'firstname': 'Ngọc Ánh',
      'lastname': 'Tạ',
      'email': 'ta.ngoc.anh@example.test',
    },
    <String, String>{
      'firstname': 'Anh Tú',
      'lastname': 'Lâm',
      'email': 'lam.anh.tu@example.test',
    },
    <String, String>{
      'firstname': 'Gia Bảo',
      'lastname': 'Huỳnh',
      'email': 'huynh.gia.bao@example.test',
    },
  ];
  const studentDepartments = <String>[
    'Khoa Công nghệ Thông tin',
    'Khoa Kinh tế và Quản trị Kinh doanh',
    'Khoa Ngoại ngữ',
    'Khoa Khoa học Xã hội',
  ];
  for (var index = 1; index <= studentProfiles.length; index++) {
    final profile = studentProfiles[index - 1];
    users.add(<String, Object?>{
      'id': 1000 + index,
      'auth': 'manual',
      'confirmed': 1,
      'deleted': 0,
      'suspended': 0,
      'username': 'svtest${index.toString().padLeft(3, '0')}',
      'idnumber': 'SVTEST${index.toString().padLeft(3, '0')}',
      'firstname': profile['firstname'],
      'lastname': profile['lastname'],
      'email': profile['email'],
      'institution': 'Trường Đại học Đà Lạt',
      'department': studentDepartments[(index - 1) ~/ 5],
      'city': 'Đà Lạt',
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
      'name': 'Công nghệ thông tin',
      'idnumber': 'CATTEST001',
      'description':
          'Các học phần nền tảng và chuyên ngành về công nghệ thông tin.',
      'sortorder': 10000,
      'coursecount': 2,
      'visible': 1,
      'depth': 1,
      'path': '/11',
    },
    <String, Object?>{
      'id': 12,
      'name': 'Kinh tế và Quản trị',
      'idnumber': 'CATTEST002',
      'description': 'Các học phần về kinh tế, quản trị và kỹ năng tổ chức.',
      'sortorder': 20000,
      'coursecount': 2,
      'visible': 1,
      'depth': 1,
      'path': '/12',
    },
    <String, Object?>{
      'id': 13,
      'name': 'Ngoại ngữ',
      'idnumber': 'CATTEST003',
      'description':
          'Các học phần phát triển năng lực ngoại ngữ trong môi trường học thuật.',
      'sortorder': 30000,
      'coursecount': 1,
      'visible': 1,
      'depth': 1,
      'path': '/13',
    },
    <String, Object?>{
      'id': 14,
      'name': 'Kỹ năng học thuật',
      'idnumber': 'CATTEST004',
      'description':
          'Các học phần hỗ trợ nghiên cứu, giao tiếp và học tập bậc đại học.',
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
      'shortname': 'CNTT2401',
      'fullname': 'Phát triển ứng dụng di động',
      'summary':
          'Xây dựng ứng dụng đa nền tảng với giao diện thích ứng, điều hướng rõ ràng và kiến trúc dễ bảo trì.',
      'sections': <String>[
        'Thông tin học phần',
        'Nền tảng giao diện Flutter',
        'Điều hướng và quản lý trạng thái',
        'Hoàn thiện ứng dụng',
      ],
      'resources': <String>[
        'Đề cương học phần',
        'Hướng dẫn thiết lập môi trường Flutter',
      ],
      'assignments': <Map<String, String>>[
        <String, String>{
          'name': 'Thiết kế giao diện thích ứng',
          'description':
              'Thiết kế một màn hình học tập hoạt động tốt trên nhiều kích thước thiết bị.',
        },
        <String, String>{
          'name': 'Xây dựng luồng điều hướng',
          'description':
              'Tổ chức các tuyến màn hình và xử lý trạng thái điều hướng cho ứng dụng.',
        },
        <String, String>{
          'name': 'Hoàn thiện ứng dụng học kỳ',
          'description':
              'Hoàn thiện sản phẩm, kiểm tra chất lượng và trình bày các quyết định kỹ thuật chính.',
        },
      ],
    },
    <String, Object>{
      'category': 11,
      'shortname': 'CNTT2402',
      'fullname': 'Cơ sở dữ liệu nâng cao',
      'summary':
          'Vận dụng mô hình dữ liệu, chuẩn hóa, truy vấn và chỉ mục để xây dựng hệ thống dữ liệu tin cậy.',
      'sections': <String>[
        'Thông tin học phần',
        'Mô hình dữ liệu quan hệ',
        'Chuẩn hóa dữ liệu',
        'Truy vấn và chỉ mục',
        'Giao dịch và bảo mật',
      ],
      'resources': <String>['Đề cương học phần', 'Tài liệu chuẩn hóa dữ liệu'],
      'assignments': <Map<String, String>>[
        <String, String>{
          'name': 'Thiết kế lược đồ quan hệ',
          'description':
              'Phân tích yêu cầu và xây dựng lược đồ quan hệ cho một hệ thống quản lý.',
        },
        <String, String>{
          'name': 'Tối ưu truy vấn dữ liệu',
          'description':
              'Đánh giá kế hoạch thực thi và đề xuất chỉ mục phù hợp cho các truy vấn đã cho.',
        },
        <String, String>{
          'name': 'Xây dựng báo cáo dữ liệu',
          'description':
              'Tổng hợp dữ liệu bằng truy vấn có cấu trúc và trình bày kết quả ngắn gọn.',
        },
      ],
    },
    <String, Object>{
      'category': 12,
      'shortname': 'QTKD2401',
      'fullname': 'Quản lý dự án',
      'summary':
          'Lập kế hoạch, phân bổ nguồn lực, theo dõi tiến độ và kiểm soát rủi ro trong dự án.',
      'sections': <String>[
        'Thông tin học phần',
        'Khởi tạo dự án',
        'Phạm vi và tiến độ',
        'Nguồn lực dự án',
        'Quản trị rủi ro',
        'Tổng kết dự án',
      ],
      'resources': <String>['Đề cương học phần', 'Khung kế hoạch dự án'],
      'assignments': <Map<String, String>>[
        <String, String>{
          'name': 'Lập kế hoạch dự án',
          'description':
              'Xác định phạm vi, mốc công việc và nguồn lực cho một dự án theo nhóm.',
        },
        <String, String>{
          'name': 'Phân tích rủi ro',
          'description':
              'Lập danh mục rủi ro và đề xuất biện pháp ứng phó có thứ tự ưu tiên.',
        },
        <String, String>{
          'name': 'Báo cáo tổng kết dự án',
          'description':
              'Đánh giá kết quả, bài học kinh nghiệm và khả năng cải tiến quy trình dự án.',
        },
      ],
    },
    <String, Object>{
      'category': 12,
      'shortname': 'KTE2401',
      'fullname': 'Kinh tế vi mô',
      'summary':
          'Phân tích lựa chọn của người tiêu dùng, doanh nghiệp và sự vận hành của các dạng thị trường.',
      'sections': <String>[
        'Thông tin học phần',
        'Cung cầu và thị trường',
        'Hành vi người tiêu dùng',
      ],
      'resources': <String>['Đề cương học phần', 'Bộ câu hỏi ôn tập'],
      'assignments': <Map<String, String>>[
        <String, String>{
          'name': 'Phân tích cung và cầu',
          'description':
              'Phân tích sự thay đổi cân bằng thị trường trong một tình huống kinh tế cụ thể.',
        },
        <String, String>{
          'name': 'Bài toán hành vi người tiêu dùng',
          'description':
              'Vận dụng đường ngân sách và sở thích để giải thích lựa chọn tiêu dùng.',
        },
        <String, String>{
          'name': 'Tiểu luận cấu trúc thị trường',
          'description':
              'So sánh đặc điểm và hành vi doanh nghiệp trong các cấu trúc thị trường khác nhau.',
        },
      ],
    },
    <String, Object>{
      'category': 13,
      'shortname': 'NNA2401',
      'fullname': 'Tiếng Anh học thuật',
      'summary':
          'Phát triển kỹ năng đọc, viết và trình bày bằng tiếng Anh trong bối cảnh học thuật.',
      'sections': <String>[
        'Thông tin học phần',
        'Kỹ năng đọc học thuật',
        'Từ vựng theo ngữ cảnh',
        'Cấu trúc đoạn văn',
        'Viết bài lập luận',
        'Thuyết trình học thuật',
        'Ôn tập cuối kỳ',
      ],
      'resources': <String>['Đề cương học phần', 'Hướng dẫn viết học thuật'],
      'assignments': <Map<String, String>>[
        <String, String>{
          'name': 'Tóm tắt bài đọc học thuật',
          'description':
              'Đọc một bài viết ngắn và trình bày lại luận điểm chính bằng ngôn ngữ của người học.',
        },
        <String, String>{
          'name': 'Thuyết trình theo nhóm',
          'description':
              'Chuẩn bị bài thuyết trình có cấu trúc rõ ràng và phân chia thời lượng hợp lý.',
        },
        <String, String>{
          'name': 'Bài viết lập luận',
          'description':
              'Viết bài lập luận ngắn, sử dụng dẫn chứng phù hợp và trích dẫn nhất quán.',
        },
      ],
    },
    <String, Object>{
      'category': 14,
      'shortname': 'KHNC2401',
      'fullname': 'Phương pháp nghiên cứu khoa học',
      'summary':
          'Hình thành câu hỏi nghiên cứu, lựa chọn phương pháp và trình bày kết quả theo chuẩn học thuật.',
      'sections': <String>[
        'Thông tin học phần',
        'Xác định vấn đề nghiên cứu',
        'Tổng quan tài liệu',
        'Câu hỏi và giả thuyết',
        'Thiết kế phương pháp',
        'Thu thập dữ liệu',
        'Phân tích kết quả',
        'Viết báo cáo nghiên cứu',
      ],
      'resources': <String>[
        'Đề cương học phần',
        'Hướng dẫn xây dựng đề cương nghiên cứu',
      ],
      'assignments': <Map<String, String>>[
        <String, String>{
          'name': 'Xác định vấn đề nghiên cứu',
          'description':
              'Trình bày bối cảnh, khoảng trống và mục tiêu của một vấn đề nghiên cứu phù hợp.',
        },
        <String, String>{
          'name': 'Xây dựng đề cương nghiên cứu',
          'description':
              'Hoàn thiện câu hỏi, phương pháp và kế hoạch thu thập dữ liệu cho đề tài đã chọn.',
        },
        <String, String>{
          'name': 'Hoàn thiện báo cáo nghiên cứu',
          'description':
              'Trình bày kết quả, thảo luận giới hạn và đề xuất hướng phát triển tiếp theo.',
        },
      ],
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
      'summary': blueprint['summary'],
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
      'name': 'Giảng viên',
      'shortname': 'editingteacher',
      'description':
          'Phụ trách nội dung, hoạt động và đánh giá trong học phần.',
      'sortorder': 1,
      'archetype': 'editingteacher',
    },
    <String, Object?>{
      'id': 2,
      'name': 'Sinh viên',
      'shortname': 'student',
      'description': 'Tham gia học tập và theo dõi kết quả trong học phần.',
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
    final blueprint = courseBlueprints[courseIndex];
    final courseId = 201 + courseIndex;
    final categoryId = blueprint['category']! as int;
    final sectionNames = blueprint['sections']! as List<String>;
    final resourceNames = blueprint['resources']! as List<String>;
    final assignmentBlueprints =
        blueprint['assignments']! as List<Map<String, String>>;
    final shortName = blueprint['shortname']! as String;
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
      'name': 'Ghi danh theo danh sách lớp',
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
        'name': sectionNames[sectionNumber],
        'summary': sectionNumber == 0
            ? 'Mục tiêu, kế hoạch học tập và các yêu cầu chính của học phần.'
            : 'Kiến thức trọng tâm và hoạt động học tập về ${sectionNames[sectionNumber].toLowerCase()}.',
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
        'name': resourceNames[resourceIndex],
        'intro': resourceIndex == 0
            ? 'Thông tin về mục tiêu, nội dung, cách đánh giá và kế hoạch học tập của học phần.'
            : 'Tài liệu hướng dẫn hỗ trợ người học chuẩn bị cho các hoạt động trong học phần.',
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
        'filename': resourceIndex == 0
            ? 'de_cuong_${shortName.toLowerCase()}.pdf'
            : 'huong_dan_${shortName.toLowerCase()}.pdf',
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
      final assignmentBlueprint = assignmentBlueprints[assignmentIndex];
      final assignmentName = assignmentBlueprint['name']!;
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
        'name': assignmentName,
        'intro': assignmentBlueprint['description'],
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
        'itemname': assignmentName,
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
        'name': 'Hạn nộp: $assignmentName',
        'description': 'Thời hạn hoàn thành và nộp bài trên hệ thống.',
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
          'feedback': score == null ? null : _feedbackForScore(score),
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

String _feedbackForScore(double score) {
  if (score < 50) {
    return 'Bài làm đã nêu được ý chính. Cần bổ sung dẫn chứng và trình bày rõ phương pháp.';
  }
  if (score < 85) {
    return 'Bài làm đáp ứng yêu cầu. Nên làm rõ phần phân tích và chuẩn hóa cách trình bày.';
  }
  return 'Bài làm có cấu trúc tốt, lập luận rõ ràng và vận dụng kiến thức phù hợp.';
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
