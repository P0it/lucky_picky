import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 사진 앨범에 저장. 권한이 없으면 요청한다.
Future<void> savePng(Uint8List bytes, String name) async {
  final hasAccess = await Gal.hasAccess(toAlbum: true);
  if (!hasAccess) {
    await Gal.requestAccess(toAlbum: true);
  }
  await Gal.putImageBytes(bytes, name: name);
}

/// 임시 파일로 써서 시스템 공유 시트를 연다.
Future<void> sharePng(Uint8List bytes, String name, String text) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name.png');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: 'image/png')], text: text),
  );
}
