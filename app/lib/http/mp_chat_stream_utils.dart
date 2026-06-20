/// 聊天 SSE 流拼接工具：恢复 SSE 协议层丢失的换行。
class MPChatStreamUtils {
  MPChatStreamUtils._();

  static final RegExp _markdownBlockStartPattern = RegExp(r'^(#{1,6}\s|---|\d+\.\s|-\s)');

  /// 标准化单个 SSE event 的 payload，补回 [data:] 行尾被协议吃掉的换行。
  static String normalizeEventChunk(String chunk, {required bool isJsonDelta}) {
    if (chunk.isEmpty) {
      return '\n\n';
    }
    if (chunk.endsWith('\n\n') || chunk.endsWith('\n')) {
      return chunk;
    }
    if (isJsonDelta) {
      if (chunk.contains('\n') || chunk.runes.length <= 4) {
        return chunk;
      }
      return '$chunk\n';
    }
    return '$chunk\n';
  }

  /// 将新 chunk 拼接到 buffer，块级 Markdown 前补空行。
  static String appendToBuffer(String buffer, String chunk) {
    if (chunk.isEmpty) {
      return buffer;
    }
    if (buffer.isEmpty) {
      return chunk;
    }
    if (_isMarkdownBlockStart(chunk.trimLeft()) && !buffer.endsWith('\n\n')) {
      buffer = buffer.endsWith('\n') ? '$buffer\n' : '$buffer\n\n';
    }
    return buffer + chunk;
  }

  static bool _isMarkdownBlockStart(String chunk) {
    return _markdownBlockStartPattern.hasMatch(chunk);
  }
}
