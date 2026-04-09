class AppUpdate {
  final int versionCode;
  final String versionName;
  final String url;
  final bool isMandatory;
  final String? changelog;

  AppUpdate({
    required this.versionCode,
    required this.versionName,
    required this.url,
    this.isMandatory = false,
    this.changelog,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      versionCode: json['versionCode'] ?? 0,
      versionName: json['versionName'] ?? '',
      url: json['url'] ?? '',
      isMandatory: json['isMandatory'] ?? false,
      changelog: json['changelog'],
    );
  }
}
