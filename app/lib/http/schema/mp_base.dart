class MPBaseResp {
  MPBaseResp({
    required this.code,
    required this.message,
  });

  final int code;
  final String message;

  factory MPBaseResp.fromJson(Map<String, dynamic> json) {
    return MPBaseResp(
      code: (json['code'] as num?)?.toInt() ?? -1,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'message': message,
    };
  }
}
