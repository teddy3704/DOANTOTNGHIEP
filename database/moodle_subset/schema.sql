-- DLU LMS Mobile / MOODLE_SUBSET_V1
-- Classification: PROJECT_SUBSET_SCHEMA
-- Reference only: Moodle LMS 3.9 schema, MySQL 5.7.31, generated 2020-08-12
-- Source: https://moodleschema.zoola.io/
--
-- This is a selected-column, disposable development projection. It is NOT a
-- dump of the DLU database, NOT a complete Moodle schema, and cannot run a
-- Moodle site. Every FOREIGN KEY below is shown as a declared relationship on
-- the referenced SchemaSpy table pages. Logical fixture joins that are not
-- declared physical foreign keys are deliberately not promoted to constraints.

SET NAMES utf8mb4;

CREATE TABLE `user` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `auth` VARCHAR(20) NOT NULL DEFAULT 'manual',
  `confirmed` BIT(1) NOT NULL DEFAULT b'0',
  `deleted` BIT(1) NOT NULL DEFAULT b'0',
  `suspended` BIT(1) NOT NULL DEFAULT b'0',
  `username` VARCHAR(100) NOT NULL,
  `idnumber` VARCHAR(255) NOT NULL,
  `firstname` VARCHAR(100) NOT NULL,
  `lastname` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) NOT NULL,
  `institution` VARCHAR(255) NOT NULL,
  `department` VARCHAR(255) NOT NULL,
  `city` VARCHAR(120) NOT NULL,
  `country` VARCHAR(2) NOT NULL,
  `lang` VARCHAR(30) NOT NULL DEFAULT 'en',
  `timezone` VARCHAR(100) NOT NULL DEFAULT '99',
  `picture` BIGINT(19) NOT NULL DEFAULT 0,
  `timecreated` BIGINT(19) NOT NULL DEFAULT 0,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `user_ema_ix` (`email`),
  KEY `user_idn_ix` (`idnumber`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `course_categories` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `idnumber` VARCHAR(100) NULL,
  `description` LONGTEXT NULL,
  `sortorder` BIGINT(19) NOT NULL DEFAULT 0,
  `coursecount` BIGINT(19) NOT NULL DEFAULT 0,
  `visible` BIT(1) NOT NULL DEFAULT b'1',
  `depth` BIGINT(19) NOT NULL DEFAULT 0,
  `path` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `shortname` VARCHAR(100) NOT NULL,
  `description` LONGTEXT NOT NULL,
  `sortorder` BIGINT(19) NOT NULL DEFAULT 0,
  `archetype` VARCHAR(30) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `role_sho_uix` (`shortname`),
  UNIQUE KEY `role_sor_uix` (`sortorder`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `course` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `category` BIGINT(19) NOT NULL DEFAULT 0,
  `sortorder` BIGINT(19) NOT NULL DEFAULT 0,
  `fullname` VARCHAR(254) NOT NULL,
  `shortname` VARCHAR(255) NOT NULL,
  `idnumber` VARCHAR(100) NOT NULL,
  `summary` LONGTEXT NULL,
  `summaryformat` TINYINT(3) NOT NULL DEFAULT 0,
  `format` VARCHAR(21) NOT NULL DEFAULT 'topics',
  `startdate` BIGINT(19) NOT NULL DEFAULT 0,
  `enddate` BIGINT(19) NOT NULL DEFAULT 0,
  `visible` BIT(1) NOT NULL DEFAULT b'1',
  `timecreated` BIGINT(19) NOT NULL DEFAULT 0,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  `enablecompletion` BIT(1) NOT NULL DEFAULT b'0',
  PRIMARY KEY (`id`),
  KEY `cour_cat_ix` (`category`),
  KEY `cour_idn_ix` (`idnumber`),
  KEY `cour_sho_ix` (`shortname`),
  CONSTRAINT `cour_cat2_fk`
    FOREIGN KEY (`category`) REFERENCES `course_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `context` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `contextlevel` BIGINT(19) NOT NULL DEFAULT 0,
  `instanceid` BIGINT(19) NOT NULL DEFAULT 0,
  `path` VARCHAR(255) NULL,
  `depth` TINYINT(3) NOT NULL DEFAULT 0,
  `locked` TINYINT(3) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cont_conins_uix` (`contextlevel`, `instanceid`),
  KEY `cont_ins_ix` (`instanceid`),
  KEY `cont_pat_ix` (`path`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `enrol` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `enrol` VARCHAR(20) NOT NULL,
  `status` BIGINT(19) NOT NULL DEFAULT 0,
  `courseid` BIGINT(19) NOT NULL,
  `sortorder` BIGINT(19) NOT NULL DEFAULT 0,
  `name` VARCHAR(255) NULL,
  `timecreated` BIGINT(19) NOT NULL DEFAULT 0,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `enro_cou_ix` (`courseid`),
  KEY `enro_enr_ix` (`enrol`),
  CONSTRAINT `enro_cou2_fk`
    FOREIGN KEY (`courseid`) REFERENCES `course` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_enrolments` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `status` BIGINT(19) NOT NULL DEFAULT 0,
  `enrolid` BIGINT(19) NOT NULL,
  `userid` BIGINT(19) NOT NULL,
  `timestart` BIGINT(19) NOT NULL DEFAULT 0,
  `timeend` BIGINT(19) NOT NULL DEFAULT 2147483647,
  `modifierid` BIGINT(19) NOT NULL DEFAULT 0,
  `timecreated` BIGINT(19) NOT NULL DEFAULT 0,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `userenro_enruse_uix` (`enrolid`, `userid`),
  KEY `userenro_enr_ix` (`enrolid`),
  KEY `userenro_use_ix` (`userid`),
  KEY `userenro_mod_ix` (`modifierid`),
  CONSTRAINT `userenro_enr2_fk`
    FOREIGN KEY (`enrolid`) REFERENCES `enrol` (`id`),
  CONSTRAINT `userenro_use2_fk`
    FOREIGN KEY (`userid`) REFERENCES `user` (`id`),
  CONSTRAINT `userenro_mod2_fk`
    FOREIGN KEY (`modifierid`) REFERENCES `user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `course_sections` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `course` BIGINT(19) NOT NULL DEFAULT 0,
  `section` BIGINT(19) NOT NULL DEFAULT 0,
  `name` VARCHAR(255) NULL,
  `summary` LONGTEXT NULL,
  `summaryformat` TINYINT(3) NOT NULL DEFAULT 0,
  `sequence` LONGTEXT NULL,
  `visible` BIT(1) NOT NULL DEFAULT b'1',
  `availability` LONGTEXT NULL,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `coursect_cousec_uix` (`course`, `section`),
  CONSTRAINT `coursect_cou_fk`
    FOREIGN KEY (`course`) REFERENCES `course` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `modules` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(20) NOT NULL,
  `cron` BIGINT(19) NOT NULL DEFAULT 0,
  `lastcron` BIGINT(19) NOT NULL DEFAULT 0,
  `search` VARCHAR(255) NOT NULL,
  `visible` BIT(1) NOT NULL DEFAULT b'1',
  PRIMARY KEY (`id`),
  KEY `modu_nam_ix` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `course_modules` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `course` BIGINT(19) NOT NULL DEFAULT 0,
  `module` BIGINT(19) NOT NULL DEFAULT 0,
  `instance` BIGINT(19) NOT NULL DEFAULT 0,
  `section` BIGINT(19) NOT NULL DEFAULT 0,
  `idnumber` VARCHAR(100) NULL,
  `added` BIGINT(19) NOT NULL DEFAULT 0,
  `visible` BIT(1) NOT NULL DEFAULT b'1',
  `visibleoncoursepage` BIT(1) NOT NULL DEFAULT b'1',
  `completion` BIT(1) NOT NULL DEFAULT b'0',
  `completionview` BIT(1) NOT NULL DEFAULT b'0',
  `completionexpected` BIGINT(19) NOT NULL DEFAULT 0,
  `availability` LONGTEXT NULL,
  PRIMARY KEY (`id`),
  KEY `courmodu_cou_ix` (`course`),
  KEY `courmodu_mod_ix` (`module`),
  KEY `courmodu_ins_ix` (`instance`),
  CONSTRAINT `courmodu_cou2_fk`
    FOREIGN KEY (`course`) REFERENCES `course` (`id`),
  CONSTRAINT `courmodu_mod2_fk`
    FOREIGN KEY (`module`) REFERENCES `modules` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `resource` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `course` BIGINT(19) NOT NULL DEFAULT 0,
  `name` VARCHAR(255) NOT NULL,
  `intro` LONGTEXT NULL,
  `introformat` SMALLINT(5) NOT NULL DEFAULT 0,
  `display` SMALLINT(5) NOT NULL DEFAULT 0,
  `displayoptions` LONGTEXT NULL,
  `revision` BIGINT(19) NOT NULL DEFAULT 0,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `reso_cou_ix` (`course`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `assign` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `course` BIGINT(19) NOT NULL DEFAULT 0,
  `name` VARCHAR(255) NOT NULL,
  `intro` LONGTEXT NOT NULL,
  `introformat` SMALLINT(5) NOT NULL DEFAULT 0,
  `alwaysshowdescription` TINYINT(3) NOT NULL DEFAULT 0,
  `submissiondrafts` TINYINT(3) NOT NULL DEFAULT 0,
  `duedate` BIGINT(19) NOT NULL DEFAULT 0,
  `allowsubmissionsfromdate` BIGINT(19) NOT NULL DEFAULT 0,
  `grade` BIGINT(19) NOT NULL DEFAULT 0,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  `completionsubmit` TINYINT(3) NOT NULL DEFAULT 0,
  `cutoffdate` BIGINT(19) NOT NULL DEFAULT 0,
  `gradingduedate` BIGINT(19) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `assi_cou_ix` (`course`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `assign_submission` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `assignment` BIGINT(19) NOT NULL DEFAULT 0,
  `userid` BIGINT(19) NOT NULL DEFAULT 0,
  `timecreated` BIGINT(19) NOT NULL DEFAULT 0,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  `status` VARCHAR(10) NULL,
  `groupid` BIGINT(19) NOT NULL DEFAULT 0,
  `attemptnumber` BIGINT(19) NOT NULL DEFAULT 0,
  `latest` TINYINT(3) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `assisubm_assusegroatt_uix`
    (`assignment`, `userid`, `groupid`, `attemptnumber`),
  KEY `assisubm_ass_ix` (`assignment`),
  KEY `assisubm_use_ix` (`userid`),
  CONSTRAINT `assisubm_ass3_fk`
    FOREIGN KEY (`assignment`) REFERENCES `assign` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `assign_grades` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `assignment` BIGINT(19) NOT NULL DEFAULT 0,
  `userid` BIGINT(19) NOT NULL DEFAULT 0,
  `timecreated` BIGINT(19) NOT NULL DEFAULT 0,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  `grader` BIGINT(19) NOT NULL DEFAULT 0,
  `grade` DECIMAL(10,5) NULL DEFAULT 0.00000,
  `attemptnumber` BIGINT(19) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `assigrad_assuseatt_uix`
    (`assignment`, `userid`, `attemptnumber`),
  KEY `assigrad_ass_ix` (`assignment`),
  KEY `assigrad_use_ix` (`userid`),
  CONSTRAINT `assigrad_ass2_fk`
    FOREIGN KEY (`assignment`) REFERENCES `assign` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `grade_items` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `courseid` BIGINT(19) NULL,
  `itemname` VARCHAR(255) NULL,
  `itemtype` VARCHAR(30) NOT NULL,
  `itemmodule` VARCHAR(30) NULL,
  `iteminstance` BIGINT(19) NULL,
  `itemnumber` BIGINT(19) NULL,
  `idnumber` VARCHAR(255) NULL,
  `gradetype` SMALLINT(5) NOT NULL DEFAULT 1,
  `grademax` DECIMAL(10,5) NOT NULL DEFAULT 100.00000,
  `grademin` DECIMAL(10,5) NOT NULL DEFAULT 0.00000,
  `gradepass` DECIMAL(10,5) NOT NULL DEFAULT 0.00000,
  `sortorder` BIGINT(19) NOT NULL DEFAULT 0,
  `hidden` BIGINT(19) NOT NULL DEFAULT 0,
  `locked` BIGINT(19) NOT NULL DEFAULT 0,
  `timecreated` BIGINT(19) NULL,
  `timemodified` BIGINT(19) NULL,
  PRIMARY KEY (`id`),
  KEY `graditem_cou_ix` (`courseid`),
  CONSTRAINT `graditem_cou2_fk`
    FOREIGN KEY (`courseid`) REFERENCES `course` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `grade_grades` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `itemid` BIGINT(19) NOT NULL,
  `userid` BIGINT(19) NOT NULL,
  `rawgrade` DECIMAL(10,5) NULL,
  `rawgrademax` DECIMAL(10,5) NOT NULL DEFAULT 100.00000,
  `rawgrademin` DECIMAL(10,5) NOT NULL DEFAULT 0.00000,
  `usermodified` BIGINT(19) NULL,
  `finalgrade` DECIMAL(10,5) NULL,
  `hidden` BIGINT(19) NOT NULL DEFAULT 0,
  `locked` BIGINT(19) NOT NULL DEFAULT 0,
  `feedback` LONGTEXT NULL,
  `feedbackformat` BIGINT(19) NOT NULL DEFAULT 0,
  `timecreated` BIGINT(19) NULL,
  `timemodified` BIGINT(19) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `gradgrad_useite_uix` (`userid`, `itemid`),
  KEY `gradgrad_ite_ix` (`itemid`),
  KEY `gradgrad_use_ix` (`userid`),
  KEY `gradgrad_use2_ix` (`usermodified`),
  CONSTRAINT `gradgrad_ite2_fk`
    FOREIGN KEY (`itemid`) REFERENCES `grade_items` (`id`),
  CONSTRAINT `gradgrad_use3_fk`
    FOREIGN KEY (`userid`) REFERENCES `user` (`id`),
  CONSTRAINT `gradgrad_use4_fk`
    FOREIGN KEY (`usermodified`) REFERENCES `user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_assignments` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `roleid` BIGINT(19) NOT NULL DEFAULT 0,
  `contextid` BIGINT(19) NOT NULL DEFAULT 0,
  `userid` BIGINT(19) NOT NULL DEFAULT 0,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  `modifierid` BIGINT(19) NOT NULL DEFAULT 0,
  `component` VARCHAR(100) NOT NULL,
  `itemid` BIGINT(19) NOT NULL DEFAULT 0,
  `sortorder` BIGINT(19) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `roleassi_rol_ix` (`roleid`),
  KEY `roleassi_con_ix` (`contextid`),
  KEY `roleassi_use_ix` (`userid`),
  CONSTRAINT `roleassi_rol2_fk`
    FOREIGN KEY (`roleid`) REFERENCES `role` (`id`),
  CONSTRAINT `roleassi_con2_fk`
    FOREIGN KEY (`contextid`) REFERENCES `context` (`id`),
  CONSTRAINT `roleassi_use2_fk`
    FOREIGN KEY (`userid`) REFERENCES `user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `files` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `contenthash` VARCHAR(40) NOT NULL,
  `pathnamehash` VARCHAR(40) NOT NULL,
  `contextid` BIGINT(19) NOT NULL,
  `component` VARCHAR(100) NOT NULL,
  `filearea` VARCHAR(50) NOT NULL,
  `itemid` BIGINT(19) NOT NULL,
  `filepath` VARCHAR(255) NOT NULL,
  `filename` VARCHAR(255) NOT NULL,
  `userid` BIGINT(19) NULL,
  `filesize` BIGINT(19) NOT NULL,
  `mimetype` VARCHAR(100) NULL,
  `status` BIGINT(19) NOT NULL DEFAULT 0,
  `timecreated` BIGINT(19) NOT NULL,
  `timemodified` BIGINT(19) NOT NULL,
  `sortorder` BIGINT(19) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `file_pat_uix` (`pathnamehash`),
  KEY `file_con2_ix` (`contextid`),
  KEY `file_use_ix` (`userid`),
  CONSTRAINT `file_con3_fk`
    FOREIGN KEY (`contextid`) REFERENCES `context` (`id`),
  CONSTRAINT `file_use2_fk`
    FOREIGN KEY (`userid`) REFERENCES `user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `course_modules_completion` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `coursemoduleid` BIGINT(19) NOT NULL,
  `userid` BIGINT(19) NOT NULL,
  `completionstate` BIT(1) NOT NULL,
  `viewed` BIT(1) NULL,
  `overrideby` BIGINT(19) NULL,
  `timemodified` BIGINT(19) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `courmoducomp_usecou_uix` (`userid`, `coursemoduleid`),
  KEY `courmoducomp_cou_ix` (`coursemoduleid`),
  CONSTRAINT `courmoducomp_cou2_fk`
    FOREIGN KEY (`coursemoduleid`) REFERENCES `course_modules` (`id`),
  CONSTRAINT `courmoducomp_use_fk`
    FOREIGN KEY (`userid`) REFERENCES `user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `event` (
  `id` BIGINT(19) NOT NULL AUTO_INCREMENT,
  `name` LONGTEXT NOT NULL,
  `description` LONGTEXT NOT NULL,
  `format` SMALLINT(5) NOT NULL DEFAULT 0,
  `categoryid` BIGINT(19) NOT NULL DEFAULT 0,
  `courseid` BIGINT(19) NOT NULL DEFAULT 0,
  `groupid` BIGINT(19) NOT NULL DEFAULT 0,
  `userid` BIGINT(19) NOT NULL DEFAULT 0,
  `component` VARCHAR(100) NULL,
  `modulename` VARCHAR(20) NOT NULL,
  `instance` BIGINT(19) NOT NULL DEFAULT 0,
  `type` SMALLINT(5) NOT NULL DEFAULT 0,
  `eventtype` VARCHAR(20) NOT NULL,
  `timestart` BIGINT(19) NOT NULL DEFAULT 0,
  `timeduration` BIGINT(19) NOT NULL DEFAULT 0,
  `timesort` BIGINT(19) NULL,
  `visible` SMALLINT(5) NOT NULL DEFAULT 1,
  `uuid` VARCHAR(255) NOT NULL,
  `sequence` BIGINT(19) NOT NULL DEFAULT 1,
  `timemodified` BIGINT(19) NOT NULL DEFAULT 0,
  `priority` BIGINT(19) NULL,
  `location` LONGTEXT NULL,
  PRIMARY KEY (`id`),
  KEY `even_cat_ix` (`categoryid`),
  KEY `even_cou_ix` (`courseid`),
  KEY `even_use_ix` (`userid`),
  KEY `even_tim_ix` (`timestart`),
  CONSTRAINT `even_cat2_fk`
    FOREIGN KEY (`categoryid`) REFERENCES `course_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Intentionally no FK for these reference-schema logical/implied joins:
-- course_modules.section -> course_sections.id
-- course_modules.(module, instance) -> resource.id / assign.id
-- resource.course -> course.id
-- assign.course -> course.id
-- assign_submission.userid -> user.id
-- assign_grades.userid/grader -> user.id
-- grade_items.(itemmodule, iteminstance) -> assign.id
-- context.(contextlevel, instanceid) -> contextual owner
-- files.itemid -> resource.id
-- event.courseid/userid/instance -> course/user/activity
