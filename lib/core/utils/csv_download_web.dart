import 'package:web/web.dart' as web;

void saveTextFileForWeb(String content, String filename) {
  final dataUrl = 'data:text/csv;charset=utf-8,${Uri.encodeComponent('\uFEFF$content')}';
  final anchor = web.HTMLAnchorElement();
  anchor.href = dataUrl;
  anchor.download = filename;
  anchor.style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
}