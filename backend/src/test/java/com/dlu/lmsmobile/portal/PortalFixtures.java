package com.dlu.lmsmobile.portal;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Invented Portal bodies (docs/V3_PORTAL_PROMPT.md §2.9). Shapes copy the API docs; every value
 * is made up: years 2098–2100, class ITK99Z, program CQ99CT(-PM), students 2399Z00x.
 * Contact/birth/English fields are present on purpose so tests can prove they never leak.
 */
final class PortalFixtures {
    static final ObjectMapper JSON = new ObjectMapper();
    static final String ME = "2399Z001";

    private PortalFixtures() {
    }

    static JsonNode json(String s) {
        try {
            return JSON.readTree(s);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private static String row(String id, String name, int credits, String s10, String s4, String letter, String pass,
                              String notCompute, String tb4, String tl4, String datTl, String year, String term) {
        return """
            {"CurriculumID":"%s","CurriculumName":"%s","Credits":"%d","DiemTK_10":"%s","DiemTK_4":"%s","DiemTK_Chu":"%s",
             "IsPass":"%s","IsGather":"x","NotComputeAverageScore":"%s","TB_HK_4":"%s","TB_HK_10":"","TB_TL_HK_4":"%s",
             "TB_TL_HK_10":"","Dat_HK":"","Dat_TL_HK":"%s","TenXepLoai":"Khá","YearStudy":"%s","TermID":"%s",
             "MobilePhone":"0900000000","BirthDay":"01/01/2080","BirthPlace":"Nơi bịa","StudentName_Eng":"Nguyen Van An",
             "SoHieuBang":"XX-0000","QuyetDinhTotNghiep":"QD-0000","UpdateStaff":"staff"}"""
            .formatted(id, name, credits, s10, s4, letter, pass, notCompute, tb4, tl4, datTl, year, term);
    }

    /** Cumulative GPA after 2099-2100 HK01 = (4·3 + 2·3 + 3·3 + 3·4 + 4·3) / 16 = 51/16 = 3.1875 → Portal "3.19". */
    static JsonNode transcript() {
        return json("""
            [{"NamHoc":"2098-2099","DanhSachDiem":[
               {"HocKy":"HK01","DanhSachDiemHK":[%s,%s,%s]},
               {"HocKy":"HK02","DanhSachDiemHK":[%s,%s]}]},
             {"NamHoc":"2099-2100","DanhSachDiem":[
               {"HocKy":"HK01","DanhSachDiemHK":[%s,%s]},
               {"HocKy":"HK02","DanhSachDiemHK":[%s,%s]}]}]""".formatted(
            row("TIN1001", "Nhập môn lập trình", 3, "8.6", "4", "A", "x", "False", "3.00", "3.00", "6", "2098-2099", "HK01"),
            row("TIN1002", "Toán rời rạc", 3, "6.0", "2", "C", "x", "False", "3.00", "3.00", "6", "2098-2099", "HK01"),
            row("GDTC1", "Giáo dục thể chất 1", 1, "7.0", "3", "B", "x", "True", "3.00", "3.00", "6", "2098-2099", "HK01"),
            row("TIN1003", "Cấu trúc dữ liệu", 3, "7.5", "3", "B", "x", "False", "1.29", "2.08", "9", "2098-2099", "HK02"),
            row("TIN1004", "Cơ sở dữ liệu", 4, "3.5", "0", "F", "", "False", "1.29", "2.08", "9", "2098-2099", "HK02"),
            row("TIN1004", "Cơ sở dữ liệu", 4, "7.2", "3", "B", "x", "False", "3.43", "3.19", "16", "2099-2100", "HK01"),
            row("TIN2001", "Lập trình web", 3, "9.0", "4", "A", "x", "False", "3.43", "3.19", "16", "2099-2100", "HK01"),
            row("TIN3206", "Kiểm thử phần mềm", 3, "", "", "", "", "False", "", "", "", "2099-2100", "HK02"),
            row("SHCD", "Sinh hoạt công dân", 0, "", "", "", "", "True", "", "", "", "2099-2100", "HK02")));
    }

    private static String pc(String code, String name, int stc, String hk, String bb, String tq, String ht, String program) {
        return """
            {"MaHP":"%s","TenHP":"%s","STC":%d,"LT":2,"TH":1,"HocKy":"%s","BatBuoc":"%s","HPTienQuyet":"%s",
             "HPHocTruoc":"%s","MaCTDT":"%s","TermID":"HK01","YearStudy":"2098-2099","GhiChu":"","Khoa":"Khoa bịa"}"""
            .formatted(code, name, stc, hk, bb, tq, ht, program);
    }

    static JsonNode programBase() {
        return json("""
            {"tbStudyPrograms":[%s,%s,%s,%s,%s,%s],"groupSelection":[],"groupSelection2":[]}""".formatted(
            pc("TIN1001", "Nhập môn lập trình", 3, "Học kỳ 1", "Bắt Buộc", "", "", "CQ99CT"),
            pc("TIN1002", "Toán rời rạc", 3, "Học kỳ 1", "Bắt Buộc", "", "", "CQ99CT"),
            pc("TIN1003", "Cấu trúc dữ liệu", 3, "Học kỳ 2", "Bắt Buộc", "", "", "CQ99CT"),
            pc("TIN1004", "Cơ sở dữ liệu", 4, "Học kỳ 2", "Bắt Buộc", "", "", "CQ99CT"),
            pc("TIN2001", "Lập trình web", 3, "Học kỳ 3", "Tự Chọn", "", "", "CQ99CT"),
            pc("TIN2002", "Mạng máy tính", 3, "Học kỳ 3", "Bắt Buộc", "TIN1003; TIN1004", "", "CQ99CT")));
    }

    static JsonNode programSpec() {
        return json("""
            {"tbStudyPrograms":[%s,%s,%s,%s],"groupSelection":[],"groupSelection2":[]}""".formatted(
            pc("TIN3206", "Kiểm thử phần mềm", 3, "Học kỳ 5", "Bắt Buộc", "TIN1003", "", "CQ99CT-PM"),
            pc("TIN3301", "Phát triển ứng dụng di động", 3, "Học kỳ 6", "Tự Chọn", "TIN2001, TIN9999", "", "CQ99CT-PM"),
            pc("TIN3302", "Đồ án chuyên ngành", 4, "Học kỳ 7", "Bắt Buộc", "", "TIN3206", "CQ99CT-PM"),
            pc("TIN1001", "Nhập môn lập trình", 3, "Học kỳ 1", "Bắt Buộc", "", "", "CQ99CT-PM")));
    }

    static JsonNode conduct(Integer me, Integer other) {
        return json("""
            {"CheckData":true,"resultDanhSach":[
              {"StudentID":"%s","StudentScore":%s,"ClassScore":%s,"DepartmentScore":%s,"LastScore":%s,"StatusID":"1",
               "FirstName":"An","LastName":"Nguyễn Văn","BirthDay":"01/01/2080","UpdateStaff":"staff"},
              {"StudentID":"2399Z002","StudentScore":90,"ClassScore":90,"DepartmentScore":90,"LastScore":%s,"StatusID":"1"}]}"""
            .formatted(ME, n(me), n(me), n(me), n(me), n(other)));
    }

    private static String n(Integer v) {
        return v == null ? "null" : v.toString();
    }

    static JsonNode decisions() {
        return json("""
            [{"DecisionName":"Quyết định khác","DecisionTypeID":16,"FullText":"Nội dung bịa","SignDate":"01/09/2098",
              "YearStudy":"2098-2099","TermID":"HK01","StudentID":"2399Z001","UpdateStaff":"staff"},
             {"DecisionName":"Cảnh báo học vụ lần 1","DecisionTypeID":5,"FullText":"Nội dung bịa 2","SignDate":"15/02/2100",
              "YearStudy":"2099-2100","TermID":"HK01","StudentID":"2399Z001"}]""");
    }

    // ------------------------------------------------------------ advisor class ITK99Z
    private static String grade(String id, String ho, String ten, String a4, String rank) {
        return """
            {"StudentID":"%s","HoLot":"%s","FirstName":"%s","STC":"15","AverageScore":"%s","AverageScore4":"%s",
             "AverageGatherScore":"","AverageGatherScore4":"%s","Ranks":"%s","BehaviorScore":"","BehaviorScoreRank":"",
             "BirthDay":"01/01/2080","STT":1}""".formatted(id, ho, ten, a4.isEmpty() ? "" : "7.0", a4, a4, rank);
    }

    /** 2099-2100 HK01 (current): averages 3.0, 1.8, 3.4 and one student without a score. */
    static JsonNode classGradesCurrent() {
        return json("[" + String.join(",",
            grade("2399Z003", "Trần Thị", "Bình", "3.4", "Giỏi"),
            grade("2399Z001", "Nguyễn Văn", "An", "3.0", "Khá"),
            grade("2399Z002", "Lê", "Cường", "1.8", "Yếu"),
            grade("2399Z004", "Phạm", "Dung", "", "KXL")) + "]");
    }

    /** 2098-2099 HK02 (previous): averages 2.8, 2.0, 3.2. */
    static JsonNode classGradesPrevious() {
        return json("[" + String.join(",",
            grade("2399Z001", "Nguyễn Văn", "An", "2.8", "Khá"),
            grade("2399Z002", "Lê", "Cường", "2.0", "Trung bình"),
            grade("2399Z003", "Trần Thị", "Bình", "3.2", "Giỏi"),
            grade("2399Z004", "Phạm", "Dung", "", "KXL")) + "]");
    }

    /** Rows exist for every term (as the real API does) but carry no values. */
    static JsonNode classGradesEmpty() {
        return json("[" + String.join(",",
            grade("2399Z001", "Nguyễn Văn", "An", "", "KXL"),
            grade("2399Z002", "Lê", "Cường", "", "KXL")) + "]");
    }

    static JsonNode classConductCurrent() {
        return json("""
            {"resultDanhSach":[
              {"StudentID":"2399Z001","LastScore":80},{"StudentID":"2399Z002","LastScore":45},
              {"StudentID":"2399Z003","LastScore":90},{"StudentID":"2399Z004","LastScore":null}]}""");
    }

    static JsonNode classMembers() {
        return json("""
            [{"StudentID":"2399Z001","StudentNameWithoutID":"Nguyễn Văn An","ClassStudentID":"ITK99Z","StudyProgramID":"CQ99CT-PM",
              "IsInClass":true,"ClassRoleID":"","MobilePhone":"0900000000","Gender":"Nam"},
             {"StudentID":"2399Z002","StudentNameWithoutID":"Lê Cường","ClassStudentID":"ITK99Z","StudyProgramID":"CQ99CT-PM","IsInClass":true},
             {"StudentID":"2399Z003","StudentNameWithoutID":"Trần Thị Bình","ClassStudentID":"ITK99Z","StudyProgramID":"CQ99CT","IsInClass":true},
             {"StudentID":"2399Z004","StudentNameWithoutID":"Phạm Dung","ClassStudentID":"ITK99Z","StudyProgramID":"CQ99CT","IsInClass":false}]""");
    }
}
