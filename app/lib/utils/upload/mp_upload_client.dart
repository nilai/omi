// getUploadRecordUrl
import 'package:omi/backend/http/mp_api/mp_memory.dart';
import 'package:omi/backend/schema/mp/mp_memory.dart';

// 文件上传工具类
class MpUploadClient {
  // Singleton instance
  static final MpUploadClient _instance = MpUploadClient._internal();
  
  // Private constructor
  MpUploadClient._internal();
  
  // Factory constructor to return the singleton instance
  factory MpUploadClient() => _instance;
  
  // Private property to store the upload URL
  String? _uploadUrl;
  
  // Private property to store the full response
  MPGetUploadRecordUrlResponse? _uploadResponse;
  
  // Getter for the upload response
  MPGetUploadRecordUrlResponse? get uploadResponse => _uploadResponse;
  
  // Method to get upload URL with caching
  Future<String?> getUploadUrl(String contentType) async {
    // If URL already exists, return it directly
    if (_uploadUrl != null) {
      return _uploadUrl;
    }
    
    // If URL doesn't exist, fetch the response
    final request = MPGetUploadRecordUrlRequest(contentType: contentType);
    _uploadResponse = await getUploadRecordUrl(request);
    
    // Set the private URL property and return it
    _uploadUrl = _uploadResponse?.uploadUrl;
    return _uploadUrl;
  }
  
  // Method to clear cached URL (useful for refreshing)
  void clearCache() {
    _uploadUrl = null;
    _uploadResponse = null;
  }
}
