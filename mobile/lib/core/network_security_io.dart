import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client? createPinnedClient(Map<String, List<String>> pinnedHashes) {
  final securityContext = SecurityContext(withTrustedRoots: true);
  final httpClient = HttpClient(context: securityContext);

  httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
    final hostHashes = pinnedHashes[host];
    if (hostHashes == null || hostHashes.isEmpty) {
      return false;
    }

    final certHash = sha256.convert(cert.der);
    final certHashStr = 'sha256/${base64.encode(certHash.bytes)}';

    final matches = hostHashes.any((pinned) => pinned == certHashStr);
    return matches;
  };

  return IOClient(httpClient);
}
