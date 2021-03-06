import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = '0.0.0.0';
final root = Directory.current.path;
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

  var router = Router();
  router.post('/gerencianet/webhook', (shelf.Request request) async {
    print(request.requestedUri.hasAuthority);
    print(request.headers);
    print(request.url.data);
    print(request.url.hasAuthority);
    print(await request.readAsString());

    return shelf.Response(200,
        body: '', headers: {'content-type': 'application/json'});
  });

  router.post('/teste', (shelf.Request request) async {
    print(request.requestedUri.hasAuthority);
    print(request.headers);
    print(request.url.data);
    print(request.url.hasAuthority);
    print('BODY: ${await request.readAsString()}');

    return shelf.Response(200,
        body: '', headers: {'content-type': 'application/json'});
  });

  router.post('/gerencianet/webhook/pix', (shelf.Request request) async {
    print(request.requestedUri.hasAuthority);
    print(request.headers);
    print(request.url.data);
    print(request.url.hasAuthority);
    print(await request.readAsString());

    return shelf.Response(200,
        body: '', headers: {'content-type': 'application/json'});
  });

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(router);

  // final serverSecurityContext = SecurityContext(withTrustedRoots: true);
  // serverSecurityContext.useCertificateChain(
  //     '/etc/letsencrypt/live/gerencianetpoc.academiadoflutter.com.br/fullchain.pem');
  // serverSecurityContext.usePrivateKey(
  //     '/etc/letsencrypt/live/gerencianetpoc.academiadoflutter.com.br/privkey.pem');
  // // openssl x509 -in pix.prod.crt -out pix.prod.pem -outform PEM
  // serverSecurityContext.setClientAuthorities('$root/bin/pix.prod.crt');
  // // serverSecurityContext.setTrustedCertificates('$root/bin/pix.prod.pem');
  // // serverSecurityContext.setClientAuthorities('$root/bin/pix.prod.pem');
  // serverSecurityContext.setAlpnProtocols(['TLSv1.2'], true);

  final server = await io.serve(
    handler,
    _hostname,
    port,
    // securityContext: serverSecurityContext,
  );

  io.serveRequests(server, handler);

  print('Serving at http://${server.address.host}:${server.port}');
  print('registrando webhook');
  // ignore: unawaited_futures
  registerWebHook();
}

Future<void> registerWebHook() async {
  // final clientID = 'Client_Id_25ddeffb1d665c8251a960f29e1adb84a8a0c57c';
  // final clientSecret = 'Client_Secret_556539b3956cc4fa3929bff5e80d9428b0aeee84';
  final clientID = 'Client_Id_c7e0896d3ed2ef64e69713eba1d44f1abdf53c68';
  final clientSecret = 'Client_Secret_56e48992d271eff5e80e6178290f37547e7943f2';

  final authBytes = utf8.encode('$clientID:$clientSecret');
  final autorizacao = base64Encode(authBytes);
  final headers = {
    'authorization': 'Basic $autorizacao',
    'content-type': 'application/json'
  };
  // print(headers);
  try {
    final dio = Dio();
    // dio.interceptors.add(dio_client.LogInterceptor());
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(
        onClientCreate: (uri, config) {
          // final root = Directory.current.path;
          final sc = SecurityContext(withTrustedRoots: true);
          // sc.useCertificateChain('$root/cert/newfile.crt.pem');
          // sc.usePrivateKey('$root/cert/newfile.key.pem');
          sc.useCertificateChain('$root/bin/prod.crt.pem');
          sc.usePrivateKey('$root/bin/prod.key.pem');
          config.context = sc;
        },
      ),
    );

    final resp = await dio.post(
      'https://api-pix.gerencianet.com.br/oauth/token',
      data: {'grant_type': 'client_credentials'},
      // data: formData,
      options: Options(
        headers: headers,
        contentType: 'application/json',
      ),
    );
    print(resp);
    var accessToken = resp.data['access_token'];
    print(accessToken);
    await registrarWEbHook(dio, accessToken);
    // return Response.ok(jsonEncode(resp.data));
  } on DioError catch (e, s) {
    // print(e);
    print(s);
  }
}

Future<void> registrarWEbHook(Dio dio, String accessToken) async {
  try {
    print('----------------------- registrarWEbHook ------------------');
    final resp = await dio.put(
      'https://api-pix.gerencianet.com.br/v2/webhook/ce80b00b-add8-4016-9516-022cce3c8be5',
      data: {
        'webhookUrl': 'https://gerencianetpoc.academiadoflutter.com.br/gerencianet/webhook'
      },
      options: Options(
        headers: {
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json'
        },
        contentType: 'application/json',
      ),
    );
    print('----------------------- Criando cobran??a ------------------');
    print(resp.data);
  } on DioError catch (e, s) {
    print(e.response?.data);
    print(s);
  } catch (e, s) {
    print(e);
    print(s);
  }
}
