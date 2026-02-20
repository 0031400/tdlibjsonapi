import 'dart:convert';

import 'package:tdjsonapi/tdjsonapi.dart';

void main() async {
  TdJson.init();
  final clientId = TdJson.tdCreateClientId!();
  final client = Client(clientId: clientId);
  TdJson.send(clientId, {
    '@type': 'setLogVerbosityLevel',
    'new_verbosity_level': 1,
  });
  client.start();
  client.updates.listen((event) {
    print(jsonEncode(event));
  });
  final data = await client.send({'@type': 'getAuthorizationState'});
  print(jsonEncode(data));}
