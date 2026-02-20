import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'dart:convert';

class TdJson {
  static DynamicLibrary? dylib;
  static int Function()? tdCreateClientId;
  static void Function(int, Pointer<Utf8>)? tdSend;
  static Pointer<Utf8> Function(double)? tdReceive;
  static void send(int clientId, Map<String, dynamic> data) {
    tdSend!(clientId, jsonEncode(data).toNativeUtf8());
  }

  static void init(String tdlibPath) {
    dylib = DynamicLibrary.open(tdlibPath);
    tdCreateClientId = dylib!.lookupFunction<Int Function(), int Function()>(
      'td_create_client_id',
    );
    tdSend = dylib!
        .lookupFunction<
          Void Function(Int, Pointer<Utf8>),
          void Function(int, Pointer<Utf8>)
        >('td_send');
    tdReceive = dylib!
        .lookupFunction<
          Pointer<Utf8> Function(Double),
          Pointer<Utf8> Function(double)
        >('td_receive');
  }

  static Map<String, dynamic> receive(double timeout) {
    while (true) {
      final resultPtr = tdReceive!(timeout);
      if (resultPtr.address == 0) {
        continue;
      }
      final resultStr = resultPtr.toDartString();
      return jsonDecode(resultStr);
    }
  }
}
