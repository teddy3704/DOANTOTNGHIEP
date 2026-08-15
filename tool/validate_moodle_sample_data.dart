import 'dart:convert';
import 'dart:io';

const int expectedSeed = 202608;
const String expectedVersion = 'MOODLE_SUBSET_V1';

const List<String> expectedTables = <String>[
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

const Map<String, List<String>> expectedColumns = <String, List<String>>{
  'user': <String>[
    'id',
    'auth',
    'confirmed',
    'deleted',
    'suspended',
    'username',
    'idnumber',
    'firstname',
    'lastname',
    'email',
    'institution',
    'department',
    'city',
    'country',
    'lang',
    'timezone',
    'picture',
    'timecreated',
    'timemodified',
  ],
  'course_categories': <String>[
    'id',
    'name',
    'idnumber',
    'description',
    'sortorder',
    'coursecount',
    'visible',
    'depth',
    'path',
  ],
  'course': <String>[
    'id',
    'category',
    'sortorder',
    'fullname',
    'shortname',
    'idnumber',
    'summary',
    'summaryformat',
    'format',
    'startdate',
    'enddate',
    'visible',
    'timecreated',
    'timemodified',
    'enablecompletion',
  ],
  'enrol': <String>[
    'id',
    'enrol',
    'status',
    'courseid',
    'sortorder',
    'name',
    'timecreated',
    'timemodified',
  ],
  'user_enrolments': <String>[
    'id',
    'status',
    'enrolid',
    'userid',
    'timestart',
    'timeend',
    'modifierid',
    'timecreated',
    'timemodified',
  ],
  'course_sections': <String>[
    'id',
    'course',
    'section',
    'name',
    'summary',
    'summaryformat',
    'sequence',
    'visible',
    'availability',
    'timemodified',
  ],
  'modules': <String>['id', 'name', 'cron', 'lastcron', 'search', 'visible'],
  'course_modules': <String>[
    'id',
    'course',
    'module',
    'instance',
    'section',
    'idnumber',
    'added',
    'visible',
    'visibleoncoursepage',
    'completion',
    'completionview',
    'completionexpected',
    'availability',
  ],
  'resource': <String>[
    'id',
    'course',
    'name',
    'intro',
    'introformat',
    'display',
    'displayoptions',
    'revision',
    'timemodified',
  ],
  'assign': <String>[
    'id',
    'course',
    'name',
    'intro',
    'introformat',
    'alwaysshowdescription',
    'submissiondrafts',
    'duedate',
    'allowsubmissionsfromdate',
    'grade',
    'timemodified',
    'completionsubmit',
    'cutoffdate',
    'gradingduedate',
  ],
  'assign_submission': <String>[
    'id',
    'assignment',
    'userid',
    'timecreated',
    'timemodified',
    'status',
    'groupid',
    'attemptnumber',
    'latest',
  ],
  'assign_grades': <String>[
    'id',
    'assignment',
    'userid',
    'timecreated',
    'timemodified',
    'grader',
    'grade',
    'attemptnumber',
  ],
  'grade_items': <String>[
    'id',
    'courseid',
    'itemname',
    'itemtype',
    'itemmodule',
    'iteminstance',
    'itemnumber',
    'idnumber',
    'gradetype',
    'grademax',
    'grademin',
    'gradepass',
    'sortorder',
    'hidden',
    'locked',
    'timecreated',
    'timemodified',
  ],
  'grade_grades': <String>[
    'id',
    'itemid',
    'userid',
    'rawgrade',
    'rawgrademax',
    'rawgrademin',
    'usermodified',
    'finalgrade',
    'hidden',
    'locked',
    'feedback',
    'feedbackformat',
    'timecreated',
    'timemodified',
  ],
  'files': <String>[
    'id',
    'contenthash',
    'pathnamehash',
    'contextid',
    'component',
    'filearea',
    'itemid',
    'filepath',
    'filename',
    'userid',
    'filesize',
    'mimetype',
    'status',
    'timecreated',
    'timemodified',
    'sortorder',
  ],
  'context': <String>[
    'id',
    'contextlevel',
    'instanceid',
    'path',
    'depth',
    'locked',
  ],
  'role': <String>[
    'id',
    'name',
    'shortname',
    'description',
    'sortorder',
    'archetype',
  ],
  'role_assignments': <String>[
    'id',
    'roleid',
    'contextid',
    'userid',
    'timemodified',
    'modifierid',
    'component',
    'itemid',
    'sortorder',
  ],
  'course_modules_completion': <String>[
    'id',
    'coursemoduleid',
    'userid',
    'completionstate',
    'viewed',
    'overrideby',
    'timemodified',
  ],
  'event': <String>[
    'id',
    'name',
    'description',
    'format',
    'categoryid',
    'courseid',
    'groupid',
    'userid',
    'component',
    'modulename',
    'instance',
    'type',
    'eventtype',
    'timestart',
    'timeduration',
    'timesort',
    'visible',
    'uuid',
    'sequence',
    'timemodified',
    'priority',
    'location',
  ],
};

void main(List<String> arguments) {
  if (arguments.length > 1) {
    stderr.writeln(
      'Usage: dart run tool/validate_moodle_sample_data.dart [fixture.json]',
    );
    exitCode = 64;
    return;
  }
  final fixturePath = arguments.isEmpty
      ? 'database${Platform.pathSeparator}fixtures'
            '${Platform.pathSeparator}dlu_lms_fixture.json'
      : arguments.single;
  final fixtureFile = File(fixturePath);
  if (!fixtureFile.existsSync()) {
    stderr.writeln('Fixture not found: ${fixtureFile.absolute.path}');
    exitCode = 66;
    return;
  }

  final validator = _FixtureValidator();
  try {
    final decoded = jsonDecode(fixtureFile.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      validator.error(r'$ must be a JSON object.');
    } else {
      validator.validate(decoded);
    }
  } on FormatException catch (error) {
    validator.error('Invalid JSON: $error');
  }

  if (validator.errors.isNotEmpty) {
    stderr.writeln('SYNTHETIC FIXTURE VALIDATION: FAIL');
    for (final error in validator.errors) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('SYNTHETIC FIXTURE VALIDATION: PASS');
  stdout.writeln('  file: ${fixtureFile.absolute.path}');
  stdout.writeln('  version: $expectedVersion');
  stdout.writeln('  seed: $expectedSeed');
  for (final entry in validator.rowCounts.entries) {
    stdout.writeln('  ${entry.key}: ${entry.value} rows');
  }
  stdout.writeln('  state coverage: ${validator.stateCoverage.join(', ')}');
}

class _FixtureValidator {
  final List<String> errors = <String>[];
  final Map<String, int> rowCounts = <String, int>{};
  final Set<String> stateCoverage = <String>{};
  late final Map<String, List<Map<String, Object?>>> tables;
  late final Map<String, Map<int, Map<String, Object?>>> rowsById;

  void error(String message) => errors.add(message);

  void validate(Map<String, Object?> root) {
    _validatePrivacy(root);
    final metadataValue = root['metadata'];
    final tablesValue = root['tables'];
    if (metadataValue is! Map<String, Object?>) {
      error(r'$.metadata must be an object.');
      return;
    }
    _validateMetadata(metadataValue);
    if (tablesValue is! Map<String, Object?>) {
      error(r'$.tables must be an object.');
      return;
    }
    if (!_sameSet(tablesValue.keys.toSet(), expectedTables.toSet())) {
      error(
        'tables must contain exactly the 20 MOODLE_SUBSET_V1 tables; '
        'found ${tablesValue.keys.join(', ')}.',
      );
    }

    tables = <String, List<Map<String, Object?>>>{};
    for (final tableName in expectedTables) {
      final value = tablesValue[tableName];
      if (value is! List<Object?>) {
        error('tables.$tableName must be an array.');
        tables[tableName] = <Map<String, Object?>>[];
        continue;
      }
      final rows = <Map<String, Object?>>[];
      for (var index = 0; index < value.length; index++) {
        final row = value[index];
        if (row is! Map<String, Object?>) {
          error('tables.$tableName[$index] must be an object.');
          continue;
        }
        rows.add(row);
        _validateRowShape(tableName, index, row);
      }
      tables[tableName] = rows;
      rowCounts[tableName] = rows.length;
    }

    rowsById = <String, Map<int, Map<String, Object?>>>{};
    for (final tableName in expectedTables) {
      final index = <int, Map<String, Object?>>{};
      for (final row in tables[tableName]!) {
        final id = row['id'];
        if (id is! int || id <= 0) {
          error('$tableName.id must be a positive integer; found $id.');
        } else if (index.containsKey(id)) {
          error('$tableName has duplicate primary key id=$id.');
        } else {
          index[id] = row;
        }
      }
      rowsById[tableName] = index;
    }

    _validateDeclaredReferences();
    _validateUniqueKeys();
    _validateDatasetCardinality();
    _validateLocalConventions();
    _validateLearningStateCoverage(metadataValue);
  }

  void _validateMetadata(Map<String, Object?> metadata) {
    if (metadata['dataset'] != 'dlu_lms_synthetic_development_fixture') {
      error('metadata.dataset must identify the canonical synthetic fixture.');
    }
    if (metadata['version'] != expectedVersion) {
      error('metadata.version must be $expectedVersion.');
    }
    if (metadata['seed'] != expectedSeed) {
      error('metadata.seed must be $expectedSeed.');
    }
    if (metadata['reference_time_epoch'] is! int) {
      error('metadata.reference_time_epoch must be an integer Unix timestamp.');
    }
    if (metadata['source_classification'] != 'SYNTHETIC_DATA') {
      error('metadata.source_classification must be SYNTHETIC_DATA.');
    }
  }

  void _validateRowShape(
    String tableName,
    int rowIndex,
    Map<String, Object?> row,
  ) {
    final expected = expectedColumns[tableName]!.toSet();
    final actual = row.keys.toSet();
    if (!_sameSet(actual, expected)) {
      error(
        '$tableName[$rowIndex] columns differ from the selected projection; '
        'expected ${expected.join(', ')}, found ${actual.join(', ')}.',
      );
    }
  }

  void _validateDeclaredReferences() {
    _reference('course', 'category', 'course_categories');
    _reference('enrol', 'courseid', 'course');
    _reference('user_enrolments', 'enrolid', 'enrol');
    _reference('user_enrolments', 'userid', 'user');
    _reference('user_enrolments', 'modifierid', 'user');
    _reference('course_sections', 'course', 'course');
    _reference('course_modules', 'course', 'course');
    _reference('course_modules', 'module', 'modules');
    _reference('assign_submission', 'assignment', 'assign');
    _reference('assign_grades', 'assignment', 'assign');
    _reference('grade_items', 'courseid', 'course');
    _reference('grade_grades', 'itemid', 'grade_items');
    _reference('grade_grades', 'userid', 'user');
    _reference('grade_grades', 'usermodified', 'user', nullable: true);
    _reference('files', 'contextid', 'context');
    _reference('files', 'userid', 'user', nullable: true);
    _reference('role_assignments', 'roleid', 'role');
    _reference('role_assignments', 'contextid', 'context');
    _reference('role_assignments', 'userid', 'user');
    _reference('course_modules_completion', 'coursemoduleid', 'course_modules');
    _reference('course_modules_completion', 'userid', 'user');
    _reference('event', 'categoryid', 'course_categories');
  }

  void _reference(
    String childTable,
    String childColumn,
    String parentTable, {
    bool nullable = false,
  }) {
    final parentIds = rowsById[parentTable]!.keys.toSet();
    for (final row in tables[childTable]!) {
      final value = row[childColumn];
      if (nullable && value == null) {
        continue;
      }
      if (value is! int || !parentIds.contains(value)) {
        error(
          '$childTable.${row['id']}.$childColumn=$value does not resolve '
          'to $parentTable.id.',
        );
      }
    }
  }

  void _validateUniqueKeys() {
    _unique('user_enrolments', <String>['enrolid', 'userid']);
    _unique('course_sections', <String>['course', 'section']);
    _unique('assign_submission', <String>[
      'assignment',
      'userid',
      'groupid',
      'attemptnumber',
    ]);
    _unique('assign_grades', <String>['assignment', 'userid', 'attemptnumber']);
    _unique('grade_grades', <String>['userid', 'itemid']);
    _unique('files', <String>['pathnamehash']);
    _unique('context', <String>['contextlevel', 'instanceid']);
    _unique('role', <String>['shortname']);
    _unique('role', <String>['sortorder']);
    _unique('course_modules_completion', <String>['userid', 'coursemoduleid']);
  }

  void _unique(String tableName, List<String> columns) {
    final seen = <String>{};
    for (final row in tables[tableName]!) {
      final key = jsonEncode(<Object?>[
        for (final column in columns) row[column],
      ]);
      if (!seen.add(key)) {
        error('$tableName violates unique(${columns.join(', ')}): $key.');
      }
    }
  }

  void _validateDatasetCardinality() {
    final users = tables['user']!;
    final teachers = users.where(
      (row) => (row['idnumber'] as String).startsWith('GVTEST'),
    );
    final students = users.where(
      (row) => (row['idnumber'] as String).startsWith('SVTEST'),
    );
    if (teachers.length != 3) {
      error('Expected exactly 3 synthetic teachers; found ${teachers.length}.');
    }
    if (students.length != 20) {
      error(
        'Expected exactly 20 synthetic students; found ${students.length}.',
      );
    }
    if (tables['course_categories']!.length != 4) {
      error('Expected exactly 4 synthetic categories.');
    }
    if (tables['course']!.length != 6) {
      error('Expected exactly 6 synthetic courses.');
    }
    for (final user in users) {
      final idNumber = user['idnumber'] as String;
      final isMarkerValid = RegExp(
        r'^(SVTEST|GVTEST)\d{3}$',
      ).hasMatch(idNumber);
      if (!isMarkerValid) {
        error('user.${user['id']} has a non-synthetic idnumber: $idNumber.');
      }
      final email = user['email'] as String;
      if (!email.endsWith('@example.test')) {
        error('user.${user['id']} email must use example.test: $email.');
      }
    }

    for (final course in tables['course']!) {
      final courseId = course['id'] as int;
      final sections = tables['course_sections']!
          .where((row) => row['course'] == courseId)
          .length;
      if (sections < 3 || sections > 8) {
        error('course.$courseId must have 3-8 sections; found $sections.');
      }
      final resources = tables['resource']!
          .where((row) => row['course'] == courseId)
          .length;
      final assignments = tables['assign']!
          .where((row) => row['course'] == courseId)
          .length;
      if (resources < 1 || assignments < 1) {
        error(
          'course.$courseId needs both resource and assignment activities.',
        );
      }
    }
  }

  void _validateLocalConventions() {
    final moduleNames = <int, String>{
      for (final row in tables['modules']!)
        row['id']! as int: row['name']! as String,
    };
    final sections = rowsById['course_sections']!;
    final resources = rowsById['resource']!;
    final assignments = rowsById['assign']!;
    final courseModules = rowsById['course_modules']!;
    final contexts = rowsById['context']!;
    final courses = rowsById['course']!;
    final users = rowsById['user']!;

    for (final module in courseModules.values) {
      final moduleId = module['id'] as int;
      final courseId = module['course'] as int;
      final section = sections[module['section']];
      if (section == null || section['course'] != courseId) {
        error(
          'LOCAL_SYNTHETIC_CONVENTION: course_modules.$moduleId.section '
          'must resolve to a section in course $courseId.',
        );
      }
      final moduleName = moduleNames[module['module']];
      final instance = module['instance'];
      final target = switch (moduleName) {
        'resource' => resources[instance],
        'assign' => assignments[instance],
        _ => null,
      };
      if (target == null || target['course'] != courseId) {
        error(
          'LOCAL_SYNTHETIC_CONVENTION: course_modules.$moduleId '
          '($moduleName/$instance) does not resolve within course $courseId.',
        );
      }
    }

    final sequencedModuleIds = <int>{};
    for (final section in sections.values) {
      final sequence = section['sequence'] as String;
      if (sequence.isEmpty) {
        continue;
      }
      for (final token in sequence.split(',')) {
        final moduleId = int.tryParse(token);
        final module = moduleId == null ? null : courseModules[moduleId];
        if (module == null || module['section'] != section['id']) {
          error(
            'LOCAL_SYNTHETIC_CONVENTION: course_sections.${section['id']}'
            '.sequence contains invalid course module $token.',
          );
        } else if (!sequencedModuleIds.add(moduleId!)) {
          error('course module $moduleId occurs in more than one sequence.');
        }
      }
    }
    if (!_sameSet(sequencedModuleIds, courseModules.keys.toSet())) {
      error('Every course module must occur exactly once in section.sequence.');
    }

    final contextByLevelAndInstance = <String, Map<String, Object?>>{
      for (final context in contexts.values)
        '${context['contextlevel']}:${context['instanceid']}': context,
    };
    for (final courseId in courses.keys) {
      if (!contextByLevelAndInstance.containsKey('50:$courseId')) {
        error('course.$courseId has no LOCAL course context (level 50).');
      }
    }
    for (final moduleId in courseModules.keys) {
      if (!contextByLevelAndInstance.containsKey('70:$moduleId')) {
        error(
          'course_modules.$moduleId has no LOCAL module context (level 70).',
        );
      }
    }

    final enrolCourse = <int, int>{
      for (final enrol in tables['enrol']!)
        enrol['id']! as int: enrol['courseid']! as int,
    };
    final enrolledByCourse = <int, Set<int>>{};
    for (final enrolment in tables['user_enrolments']!) {
      final courseId = enrolCourse[enrolment['enrolid']]!;
      enrolledByCourse
          .putIfAbsent(courseId, () => <int>{})
          .add(enrolment['userid']! as int);
    }

    for (final roleAssignment in tables['role_assignments']!) {
      final context = contexts[roleAssignment['contextid']];
      if (context == null || context['contextlevel'] != 50) {
        error(
          'role_assignments.${roleAssignment['id']} must use a course context.',
        );
        continue;
      }
      final courseId = context['instanceid'] as int;
      if (!(enrolledByCourse[courseId] ?? <int>{}).contains(
        roleAssignment['userid'],
      )) {
        error(
          'role_assignments.${roleAssignment['id']} user is not enrolled '
          'in course $courseId.',
        );
      }
    }

    bool isStudent(int userId) =>
        (users[userId]?['idnumber'] as String?)?.startsWith('SVTEST') ?? false;
    bool isEnrolled(int userId, int courseId) =>
        (enrolledByCourse[courseId] ?? <int>{}).contains(userId);

    for (final resource in resources.values) {
      if (!courses.containsKey(resource['course'])) {
        error('resource.${resource['id']}.course does not resolve.');
      }
    }
    for (final assignment in assignments.values) {
      if (!courses.containsKey(assignment['course'])) {
        error('assign.${assignment['id']}.course does not resolve.');
      }
    }

    final submissionsByAssignmentAndUser = <String, Map<String, Object?>>{};
    for (final submission in tables['assign_submission']!) {
      final assignment = assignments[submission['assignment']]!;
      final userId = submission['userid'] as int;
      final courseId = assignment['course'] as int;
      if (!isStudent(userId) || !isEnrolled(userId, courseId)) {
        error(
          'assign_submission.${submission['id']} user must be a student '
          'enrolled in course $courseId.',
        );
      }
      if (submission['status'] != 'draft' &&
          submission['status'] != 'submitted') {
        error('assign_submission.${submission['id']} has invalid status.');
      }
      submissionsByAssignmentAndUser['${submission['assignment']}:${submission['userid']}'] =
          submission;
    }

    final gradesByAssignmentAndUser = <String, Map<String, Object?>>{};
    for (final grade in tables['assign_grades']!) {
      final assignment = assignments[grade['assignment']]!;
      final userId = grade['userid'] as int;
      final courseId = assignment['course'] as int;
      final key = '${grade['assignment']}:$userId';
      final submission = submissionsByAssignmentAndUser[key];
      if (!isStudent(userId) || !isEnrolled(userId, courseId)) {
        error('assign_grades.${grade['id']} user is not an enrolled student.');
      }
      if (submission == null || submission['status'] != 'submitted') {
        error('assign_grades.${grade['id']} has no submitted attempt.');
      }
      final score = grade['grade'];
      if (score is! num || score < 0 || score > 100) {
        error('assign_grades.${grade['id']}.grade must be within 0..100.');
      }
      gradesByAssignmentAndUser[key] = grade;
    }

    final gradeItems = rowsById['grade_items']!;
    for (final item in gradeItems.values) {
      final assignment = assignments[item['iteminstance']];
      if (item['itemtype'] != 'mod' ||
          item['itemmodule'] != 'assign' ||
          assignment == null ||
          assignment['course'] != item['courseid']) {
        error(
          'LOCAL_SYNTHETIC_CONVENTION: grade_items.${item['id']} must map '
          'to assign through itemmodule/iteminstance in the same course.',
        );
      }
    }
    for (final grade in tables['grade_grades']!) {
      final item = gradeItems[grade['itemid']]!;
      final assignmentId = item['iteminstance'] as int;
      final assignment = assignments[assignmentId]!;
      final userId = grade['userid'] as int;
      final key = '$assignmentId:$userId';
      if (!isStudent(userId) ||
          !isEnrolled(userId, assignment['course']! as int)) {
        error('grade_grades.${grade['id']} user is not an enrolled student.');
      }
      final finalGrade = grade['finalgrade'];
      final moduleGrade = gradesByAssignmentAndUser[key];
      if (finalGrade == null && moduleGrade != null) {
        error('grade_grades.${grade['id']} is null but module grade exists.');
      }
      if (finalGrade != null &&
          (moduleGrade == null || moduleGrade['grade'] != finalGrade)) {
        error('grade_grades.${grade['id']} does not match assign_grades.');
      }
    }

    for (final completion in tables['course_modules_completion']!) {
      final module = courseModules[completion['coursemoduleid']]!;
      final userId = completion['userid'] as int;
      if (!isStudent(userId) || !isEnrolled(userId, module['course']! as int)) {
        error(
          'course_modules_completion.${completion['id']} user is not '
          'an enrolled student.',
        );
      }
      final state = completion['completionstate'];
      if (state is! int || (state != 0 && state != 1)) {
        error(
          'course_modules_completion.${completion['id']} has invalid state.',
        );
      }
    }

    for (final file in tables['files']!) {
      final context = contexts[file['contextid']];
      final module = context == null || context['contextlevel'] != 70
          ? null
          : courseModules[context['instanceid']];
      final resource =
          module == null || moduleNames[module['module']] != 'resource'
          ? null
          : resources[module['instance']];
      if (file['component'] != 'mod_resource' ||
          file['filearea'] != 'content' ||
          resource == null ||
          file['itemid'] != resource['id']) {
        error(
          'LOCAL_SYNTHETIC_CONVENTION: files.${file['id']} must map through '
          'a module context to its resource and use itemid=resource.id.',
        );
      }
      if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(file['contenthash']! as String) ||
          !RegExp(
            r'^[0-9a-f]{40}$',
          ).hasMatch(file['pathnamehash']! as String)) {
        error('files.${file['id']} hashes must be 40 lowercase hex digits.');
      }
    }

    for (final event in tables['event']!) {
      final assignment = assignments[event['instance']];
      if (event['component'] != 'mod_assign' ||
          event['modulename'] != 'assign' ||
          assignment == null ||
          assignment['course'] != event['courseid']) {
        error(
          'LOCAL_SYNTHETIC_CONVENTION: event.${event['id']} must map '
          'to an assignment in the same course.',
        );
      }
      final userId = event['userid'];
      if (userId != 0 && !users.containsKey(userId)) {
        error('event.${event['id']}.userid must be 0 or a fixture user.');
      }
    }
  }

  void _validateLearningStateCoverage(Map<String, Object?> metadata) {
    final referenceTime = metadata['reference_time_epoch'];
    if (referenceTime is! int) {
      return;
    }
    const threeDays = 3 * 24 * 60 * 60;
    for (final assignment in tables['assign']!) {
      final dueDate = assignment['duedate'] as int;
      final availableDate = assignment['allowsubmissionsfromdate'] as int;
      if (availableDate > referenceTime) {
        stateCoverage.add('future');
      }
      if (availableDate <= referenceTime &&
          dueDate >= referenceTime &&
          dueDate <= referenceTime + threeDays) {
        stateCoverage.add('soon');
      }
      if (dueDate < referenceTime) {
        stateCoverage.add('overdue');
      }
    }

    final submissionKeys = <String>{};
    final submittedKeys = <String>{};
    for (final submission in tables['assign_submission']!) {
      final key = '${submission['assignment']}:${submission['userid']}';
      submissionKeys.add(key);
      if (submission['status'] == 'draft') {
        stateCoverage.add('draft');
      }
      if (submission['status'] == 'submitted') {
        stateCoverage.add('submitted');
        submittedKeys.add(key);
      }
    }
    final gradedKeys = <String>{};
    for (final grade in tables['assign_grades']!) {
      final key = '${grade['assignment']}:${grade['userid']}';
      gradedKeys.add(key);
      final score = grade['grade'] as num;
      if (score < 50) {
        stateCoverage.add('grade_low');
      } else if (score < 85) {
        stateCoverage.add('grade_medium');
      } else {
        stateCoverage.add('grade_high');
      }
    }
    if (submittedKeys.difference(gradedKeys).isNotEmpty) {
      stateCoverage.add('ungraded');
    }
    if (gradedKeys.isNotEmpty) {
      stateCoverage.add('graded');
    }

    final enrolCourse = <int, int>{
      for (final enrol in tables['enrol']!)
        enrol['id']! as int: enrol['courseid']! as int,
    };
    final studentIds = <int>{
      for (final user in tables['user']!)
        if ((user['idnumber'] as String).startsWith('SVTEST'))
          user['id']! as int,
    };
    final studentsByCourse = <int, Set<int>>{};
    for (final enrolment in tables['user_enrolments']!) {
      final userId = enrolment['userid'] as int;
      if (studentIds.contains(userId)) {
        studentsByCourse
            .putIfAbsent(enrolCourse[enrolment['enrolid']]!, () => <int>{})
            .add(userId);
      }
    }
    for (final assignment in tables['assign']!) {
      for (final studentId
          in studentsByCourse[assignment['course']] ?? <int>{}) {
        if (!submissionKeys.contains('${assignment['id']}:$studentId')) {
          stateCoverage.add('not_submitted');
        }
      }
    }

    const requiredStates = <String>{
      'future',
      'soon',
      'overdue',
      'draft',
      'submitted',
      'not_submitted',
      'graded',
      'ungraded',
      'grade_low',
      'grade_medium',
      'grade_high',
    };
    final missing = requiredStates.difference(stateCoverage);
    if (missing.isNotEmpty) {
      error('Missing required assignment/grade states: ${missing.join(', ')}.');
    }
  }

  void _validatePrivacy(Object? value, [String path = r'$']) {
    const forbiddenKeys = <String>{
      'password',
      'token',
      'secret',
      'private_key',
      'access_key',
    };
    if (value is Map<String, Object?>) {
      for (final entry in value.entries) {
        final lowerKey = entry.key.toLowerCase();
        if (forbiddenKeys.any(
          (forbidden) => lowerKey == forbidden || lowerKey.contains(forbidden),
        )) {
          error('$path contains forbidden credential field "${entry.key}".');
        }
        _validatePrivacy(entry.value, '$path.${entry.key}');
      }
    } else if (value is List<Object?>) {
      for (var index = 0; index < value.length; index++) {
        _validatePrivacy(value[index], '$path[$index]');
      }
    }
  }
}

bool _sameSet<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);
