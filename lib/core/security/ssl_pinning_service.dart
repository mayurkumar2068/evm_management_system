import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/io.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';

class SslPinningService {
  const SslPinningService(this._config);

  final EnvironmentConfig _config;

  IOHttpClientAdapter buildAdapter() {
    return IOHttpClientAdapter(
      createHttpClient: () {
        final HttpClient client = HttpClient();
        if (!_config.enableSslPinning || _config.sslPinSha256.isEmpty) {
          return client;
        }
        client.badCertificateCallback = (_, __, ___) => false;
        return client;
      },
      validateCertificate: (X509Certificate? cert, String host, int port) {
        if (!_config.enableSslPinning || _config.sslPinSha256.isEmpty) {
          return true;
        }
        if (cert == null) return false;
        final String fingerprint = base64.encode(
          sha256.convert(cert.der).bytes,
        );
        final bool matches = fingerprint == _config.sslPinSha256;
        if (!matches) {
          AppLogger.e('SSL pin mismatch for $host:$port');
        }
        return matches;
      },
    );
  }
}
