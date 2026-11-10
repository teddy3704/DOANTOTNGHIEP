import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Vietnamese labels for framework controls used by this app; no extra package.
class VietnameseMaterialLocalizations extends DefaultMaterialLocalizations {
  const VietnameseMaterialLocalizations();
  @override
  String get timePickerDialHelpText => 'Chọn giờ';
  @override
  String get timePickerInputHelpText => 'Nhập giờ';
  @override
  String get timePickerHourLabel => 'Giờ';
  @override
  String get timePickerMinuteLabel => 'Phút';
  @override
  String get dialModeButtonLabel => 'Chuyển sang chọn trên mặt đồng hồ';
  @override
  String get inputTimeModeButtonLabel => 'Chuyển sang nhập bằng bàn phím';
  @override
  String get copyButtonLabel => 'Sao chép';
  @override
  String get cutButtonLabel => 'Cắt';
  @override
  String get pasteButtonLabel => 'Dán';
  @override
  String get selectAllButtonLabel => 'Chọn tất cả';
  @override
  String get lookUpButtonLabel => 'Tra cứu';
  @override
  String get searchWebButtonLabel => 'Tìm trên mạng';
  @override
  String get shareButtonLabel => 'Chia sẻ';
  @override
  String get reorderItemUp => 'Di chuyển lên';
  @override
  String get reorderItemDown => 'Di chuyển xuống';
  @override
  String get reorderItemLeft => 'Di chuyển sang trái';
  @override
  String get reorderItemRight => 'Di chuyển sang phải';
  @override
  String get reorderItemToEnd => 'Chuyển xuống cuối';
  @override
  String get reorderItemToStart => 'Chuyển lên đầu';
  @override
  String get backButtonTooltip => 'Quay lại';
  @override
  String get clearButtonTooltip => 'Xóa nội dung';
  @override
  String get closeButtonTooltip => 'Đóng';
  @override
  String get deleteButtonTooltip => 'Xóa';
  @override
  String get moreButtonTooltip => 'Thêm tùy chọn';
  @override
  String get showMenuTooltip => 'Mở trình đơn';
  @override
  String get drawerLabel => 'Trình đơn điều hướng';
  @override
  String get menuBarMenuLabel => 'Thanh trình đơn';
  @override
  String get popupMenuLabel => 'Trình đơn';
  @override
  String get dialogLabel => 'Hộp thoại';
  @override
  String get alertDialogLabel => 'Thông báo';
  @override
  String get searchFieldLabel => 'Tìm kiếm';
  @override
  String get scrimLabel => 'Lớp phủ';
  @override
  String get bottomSheetLabel => 'Bảng lựa chọn';
  @override
  String get cancelButtonLabel => 'Hủy';
  @override
  String get closeButtonLabel => 'Đóng';
  @override
  String get continueButtonLabel => 'Tiếp tục';
  @override
  String get scanTextButtonLabel => 'Quét văn bản';
  @override
  String get okButtonLabel => 'Đồng ý';
  @override
  String get modalBarrierDismissLabel => 'Đóng';
  @override
  String get menuDismissLabel => 'Đóng trình đơn';
  @override
  String get refreshIndicatorSemanticLabel => 'Tải lại';
  @override
  String get expandedIconTapHint => 'Thu gọn';
  @override
  String get collapsedIconTapHint => 'Mở rộng';
  @override
  String get selectedDateLabel => 'Đã chọn';
  @override
  String get expansionTileExpandedHint => 'Nhấn hai lần để thu gọn';
  @override
  String get expansionTileCollapsedHint => 'Nhấn hai lần để mở rộng';
  @override
  String get expansionTileExpandedTapHint => 'Thu gọn';
  @override
  String get expansionTileCollapsedTapHint => 'Mở rộng để xem chi tiết';
  @override
  String get expandedHint => 'Đã thu gọn';
  @override
  String get collapsedHint => 'Đã mở rộng';
  @override
  String tabLabel({required int tabIndex, required int tabCount}) =>
      'Thẻ $tabIndex trong $tabCount';
  @override
  String scrimOnTapHint(String modalRouteContentName) =>
      'Đóng $modalRouteContentName';
  @override
  String selectedRowCountTitle(int selectedRowCount) =>
      'Đã chọn $selectedRowCount mục';
}

class VietnameseMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const VietnameseMaterialDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'vi';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const VietnameseMaterialLocalizations());
  @override
  bool shouldReload(VietnameseMaterialDelegate old) => false;
}

class VietnameseWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const VietnameseWidgetsLocalizations();
  @override
  String get copyButtonLabel => 'Sao chép';
  @override
  String get cutButtonLabel => 'Cắt';
  @override
  String get pasteButtonLabel => 'Dán';
  @override
  String get selectAllButtonLabel => 'Chọn tất cả';
  @override
  String get lookUpButtonLabel => 'Tra cứu';
  @override
  String get searchWebButtonLabel => 'Tìm trên mạng';
  @override
  String get shareButtonLabel => 'Chia sẻ';
  @override
  String get reorderItemUp => 'Di chuyển lên';
  @override
  String get reorderItemDown => 'Di chuyển xuống';
  @override
  String get reorderItemLeft => 'Di chuyển sang trái';
  @override
  String get reorderItemRight => 'Di chuyển sang phải';
  @override
  String get reorderItemToEnd => 'Chuyển xuống cuối';
  @override
  String get reorderItemToStart => 'Chuyển lên đầu';
  @override
  String get searchResultsFound => 'Đã tìm thấy kết quả';
  @override
  String get noResultsFound => 'Không tìm thấy kết quả';
  @override
  String get radioButtonUnselectedLabel => 'Chưa chọn';
}

class VietnameseWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const VietnameseWidgetsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'vi';
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const VietnameseWidgetsLocalizations());
  @override
  bool shouldReload(VietnameseWidgetsDelegate old) => false;
}

class VietnameseCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const VietnameseCupertinoLocalizations();
  @override
  String get clearButtonLabel => 'Xóa nội dung';
  @override
  String get noSpellCheckReplacementsLabel => 'Không có từ thay thế';
  @override
  String get menuDismissLabel => 'Đóng trình đơn';
  @override
  String get cancelButtonLabel => 'Hủy';
  @override
  String get alertDialogLabel => 'Thông báo';
  @override
  String get copyButtonLabel => 'Sao chép';
  @override
  String get cutButtonLabel => 'Cắt';
  @override
  String get pasteButtonLabel => 'Dán';
  @override
  String get selectAllButtonLabel => 'Chọn tất cả';
  @override
  String get lookUpButtonLabel => 'Tra cứu';
  @override
  String get searchWebButtonLabel => 'Tìm trên mạng';
  @override
  String get shareButtonLabel => 'Chia sẻ';
  @override
  String get modalBarrierDismissLabel => 'Đóng';
  @override
  String get searchTextFieldPlaceholderLabel => 'Tìm kiếm';
  @override
  String get backButtonLabel => 'Quay lại';
  @override
  String tabSemanticsLabel({required int tabIndex, required int tabCount}) =>
      'Thẻ $tabIndex trong $tabCount';
}

class VietnameseCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const VietnameseCupertinoDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'vi';
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const VietnameseCupertinoLocalizations());
  @override
  bool shouldReload(VietnameseCupertinoDelegate old) => false;
}
