import 'tdjsonapi_base.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:convert';

class Client {
  int sendId = 1;
  int clientId = 0;
  ReceivePort receivePort = ReceivePort();
  double timeout = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pendding = {};
  final StreamController<Map<String, dynamic>> _updates =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get updates => _updates.stream;
  Client({required this.clientId, this.timeout = 10.0, int logLevel = 1}) {
    receivePort.listen((msg) {
      final sendId = msg['@extra']?['send_id'];
      if (sendId is int && _pendding.containsKey(sendId)) {
        _pendding[sendId]!.complete(msg);
        _pendding.remove(sendId);
      } else {
        _updates.add(msg);
      }
    });
    send({'@type': 'setLogVerbosityLevel', 'new_verbosity_level': logLevel});
  }

  Future<Map<String, dynamic>> send(Map<String, dynamic> data) {
    sendId++;
    data['@extra'] = {'send_id': sendId};
    final c = Completer<Map<String, dynamic>>();
    _pendding[sendId] = c;
    TdJson.send(clientId, data);
    return c.future.timeout(
      Duration(seconds: timeout.toInt()),
      onTimeout: () {
        _pendding.remove(sendId);
        throw TimeoutException('Request timed out');
      },
    );
  }
}
