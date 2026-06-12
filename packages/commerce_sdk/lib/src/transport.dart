import 'dart:convert';
import 'dart:io';

class CommerceResponse {
  const CommerceResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final Object? body;
  final Map<String, String> headers;
}

abstract interface class CommerceTransport {
  Future<CommerceResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  });

  void close();
}

class IoCommerceTransport implements CommerceTransport {
  IoCommerceTransport({
    HttpClient? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? HttpClient();

  final HttpClient _client;
  final Duration timeout;

  @override
  Future<CommerceResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) async {
    final request = await _client.openUrl(method, uri).timeout(timeout);
    headers.forEach(request.headers.set);

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(timeout);
    final responseText = await utf8.decoder.bind(response).join();
    final responseBody = responseText.isEmpty ? null : jsonDecode(responseText);
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name] = values.join(',');
    });

    return CommerceResponse(
      statusCode: response.statusCode,
      body: responseBody,
      headers: responseHeaders,
    );
  }

  @override
  void close() {
    _client.close(force: true);
  }
}
