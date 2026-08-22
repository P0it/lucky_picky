import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// 웹에는 사진 앨범이 없으므로 브라우저 다운로드로 대신한다.
Future<void> savePng(Uint8List bytes, String name) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = '$name.png'
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

/// Web Share API 로 파일 공유를 시도하고, 불가하면 다운로드로 폴백한다.
Future<void> sharePng(Uint8List bytes, String name, String text) async {
  final file = web.File(
    [bytes.toJS].toJS,
    '$name.png',
    web.FilePropertyBag(type: 'image/png'),
  );
  final data = web.ShareData(files: [file].toJS, text: text);
  if (web.window.navigator.canShare(data)) {
    await web.window.navigator.share(data).toDart;
    return;
  }
  await savePng(bytes, name);
}
