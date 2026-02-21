import 'tdjsonapi_base.dart';
import 'dart:async';
import 'dart:isolate';

class IsolateEntryArgument {
  SendPort sendPort;
  String tdlibPath;
  double timeout;
  IsolateEntryArgument({
    required this.sendPort,
    required this.tdlibPath,
    required this.timeout,
  });
}

class Client {
  int sendId = 1;
  int clientId = 0;
  ReceivePort receivePort = ReceivePort();
  double timeout = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pendding = {};
  final StreamController<Map<String, dynamic>> _updates =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get updates => _updates.stream;
  Client({required this.clientId, this.timeout = 10.0});
  bool running = false;
  static void isolateEntry(IsolateEntryArgument isolateEntryArgument) {
    TdJson.init(tdlibPath: isolateEntryArgument.tdlibPath);
    while (true) {
      final msg = TdJson.receive(isolateEntryArgument.timeout);
      isolateEntryArgument.sendPort.send(msg);
    }
  }

  void start({String tdlibPath = 'tdjson.dll'}) {
    Isolate.spawn(
      isolateEntry,
      IsolateEntryArgument(
        sendPort: receivePort.sendPort,
        tdlibPath: tdlibPath,
        timeout: timeout,
      ),
    );
    receivePort.listen((msg) {
      final extra = msg['@extra'];
      if (extra is int && _pendding.containsKey(extra)) {
        _pendding[extra]!.complete(msg);
        _pendding.remove(extra);
      } else {
        _updates.add(msg);
      }
    });
  }

  Future<Map<String, dynamic>> send(Map<String, dynamic> data) {
    sendId++;
    data['@extra'] = sendId;
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
