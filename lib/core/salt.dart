import 'dart:convert';
import 'package:crypto/crypto.dart';

class Salt {
  Salt._();

  static String compute({
    required String packageName,
    required String firstGitCommitHash,
  }) {
    final input = '$packageName:$firstGitCommitHash';
    return sha256.convert(utf8.encode(input)).toString();
  }
}


