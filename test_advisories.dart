import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('https://pub.flutter-io.cn/api/packages/archive/advisories'));
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  final idx = 0;
  var start = 0;
  while (true) {
    final i = body.indexOf('advisoriesUpdated', start);
    if (i < 0) break;
    print('at $i: ${body.substring(i, (i + 60).clamp(0, body.length))}');
    start = i + 1;
  }
  final json = jsonDecode(body) as Map;
  print('parsed advisoriesUpdated = ${json['advisoriesUpdated']}');
  // manual parse last 100 chars
  print('tail: ${body.substring(body.length - 120)}');
}
