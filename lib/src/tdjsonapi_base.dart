import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'dart:convert';

class TdJson {
  late final String tdlibPath;
  late final DynamicLibrary dylib;
  late final int Function() tdCreateClientId;
  late final void Function(int, Pointer<Utf8>) tdSend;
  late final Pointer<Utf8> Function(double) tdReceive;
  void send(int clientId, Map<String, dynamic> data) {
    tdSend(clientId, jsonEncode(data).toNativeUtf8());
  }

  Map<String, dynamic> receive(double timeout) {
    while (true) {
      final resultPtr = tdReceive(timeout);
      if (resultPtr.address == 0) {
        continue;
      }
      final resultStr = resultPtr.toDartString();
      malloc.free(resultPtr);
      return jsonDecode(resultStr);
    }
  }

  TdJson({required this.tdlibPath}) {
    dylib = DynamicLibrary.open(tdlibPath);
    tdCreateClientId = dylib.lookupFunction<Int Function(), int Function()>(
      'td_create_client_id',
    );
    tdSend = dylib
        .lookupFunction<
          Void Function(Int, Pointer<Utf8>),
          void Function(int, Pointer<Utf8>)
        >('td_send');
    tdReceive = dylib
        .lookupFunction<
          Pointer<Utf8> Function(Double),
          Pointer<Utf8> Function(double)
        >('td_receive');
  }
}
