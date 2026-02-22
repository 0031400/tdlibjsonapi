import 'dart:isolate';
import 'client.dart';
import 'tdjsonapi_base.dart';

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

class ClientManager {
  static final receivePort = ReceivePort();
  static final exitReceivePort = ReceivePort();
  static final clientList = <Client>[];
  static Isolate? isolate;
  static double timeout = 10.0;
  static void isolateEntry(IsolateEntryArgument isolateEntryArgument) {
    TdJson.init(tdlibPath: isolateEntryArgument.tdlibPath);
    while (true) {
      final msg = TdJson.receive(isolateEntryArgument.timeout);
      isolateEntryArgument.sendPort.send(msg);
    }
  }

  static void start({String tdlibPath = 'tdjson.dll'}) async {
    isolate = await Isolate.spawn(
      isolateEntry,
      IsolateEntryArgument(
        sendPort: receivePort.sendPort,
        tdlibPath: tdlibPath,
        timeout: timeout,
      ),
      onExit: exitReceivePort.sendPort,
    );
    receivePort.listen((msg) {
      final clientId = msg['@client_id'];
      for (final client in clientList) {
        if (client.clientId == clientId) {
          client.receivePort.sendPort.send(msg);
        }
      }
    });
  }
}
