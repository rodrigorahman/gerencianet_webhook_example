import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = 'localhost';

void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '443';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest);

  // final serverSecurityContext = SecurityContext();
  // serverSecurityContext.useCertificateChain(
  //     '/etc/letsencrypt/live/gerencianetpoc.academiadoflutter.com.br/fullchain.pem');
  // serverSecurityContext.usePrivateKey(
  //     '/etc/letsencrypt/live/gerencianetpoc.academiadoflutter.com.br/privkey.pem');
  // // serverSecurityContext.setTrustedCertificates(file)
  final server = await io.serve(handler, _hostname, port,
  );
      // securityContext: serverSecurityContext);

  print('Serving at http://${server.address.host}:${server.port}');
}

shelf.Response _echoRequest(shelf.Request request) =>
    shelf.Response.ok('Request for "${request.url}"');
