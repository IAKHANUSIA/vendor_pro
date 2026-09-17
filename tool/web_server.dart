import 'dart:io';

const int defaultPort = 8080;
const String buildWebPath = 'build/web';

final Map<String, String> mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.htm': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json',
};

Future<void> main(List<String> args) async {
  // Resolve directory
  Directory webDir = Directory(buildWebPath);
  if (!webDir.existsSync()) {
    // Check if running from tool directory
    webDir = Directory('../$buildWebPath');
    if (!webDir.existsSync()) {
      print('[ERROR] build/web directory not found. Please run "flutter build web" first.');
      exit(1);
    }
  }

  int port = defaultPort;
  if (args.isNotEmpty) {
    port = int.tryParse(args[0]) ?? defaultPort;
  }

  HttpServer? server;
  for (int attempt = 0; attempt < 10; attempt++) {
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port + attempt);
      break;
    } catch (e) {
      // try next port
    }
  }

  if (server == null) {
    print('[ERROR] Could not bind to any port starting from $port');
    exit(1);
  }

  final url = 'http://localhost:${server.port}';
  print('========================================================');
  print('  🚀 Vendor Pro Web Server is Running!');
  print('  🌐 URL: $url');
  print('  📁 Serving: ${webDir.absolute.path}');
  print('========================================================');
  print('Press Ctrl+C to stop the server.\n');

  // Open browser automatically
  _launchBrowser(url);

  await for (HttpRequest request in server) {
    try {
      _handleRequest(request, webDir);
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('500 Internal Server Error: $e')
        ..close();
    }
  }
}

void _handleRequest(HttpRequest request, Directory webDir) {
  var path = request.uri.path;
  if (path == '/' || path.isEmpty) {
    path = '/index.html';
  }

  // Prevent directory traversal
  final sanitizedPath = path.replaceAll(RegExp(r'\.\.+'), '');
  var file = File('${webDir.path}$sanitizedPath');

  // Fallback to index.html for Single Page Applications (SPA routing)
  if (!file.existsSync()) {
    file = File('${webDir.path}/index.html');
  }

  if (!file.existsSync()) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write('404 Not Found')
      ..close();
    return;
  }

  final ext = file.path.contains('.')
      ? '.${file.path.split('.').last.toLowerCase()}'
      : '';
  final mime = mimeTypes[ext] ?? 'application/octet-stream';

  request.response.headers.set(HttpHeaders.contentTypeHeader, mime);
  // Add CORS & caching headers
  request.response.headers.set('Access-Control-Allow-Origin', '*');
  request.response.headers.set('Cache-Control', 'no-cache');

  file.openRead().pipe(request.response).catchError((err) {
    try {
      request.response.close();
    } catch (_) {}
  });
}

void _launchBrowser(String url) {
  try {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', url]);
    } else if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [url]);
    }
  } catch (e) {
    print('Could not launch browser automatically: $e');
  }
}
