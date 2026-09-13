import '../branding/config.dart';

class FeedbackMail {
  static const address = AppBrand.supportEmail;
  static const subject = '[ViMai Kids] Phản hồi từ người dùng';

  static Uri mailto({String childName = '', int? age}) {
    final body = StringBuffer()
      ..writeln('Tên bé: $childName')
      ..writeln('Tuổi: ${age ?? ''}')
      ..writeln('Nội dung góp ý:')
      ..writeln();
    return Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: {
        'subject': subject,
        'body': body.toString(),
      },
    );
  }
}
