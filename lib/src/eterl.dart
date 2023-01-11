import 'dart:typed_data';
import 'dart:convert';

import 'package:eterl/src/decoder.dart';
import 'package:eterl/src/encoder.dart';

/// Eterl encoder and decoder.
class Eterl {
  const Eterl._();

  /// Unpack encoded data from the Erlang External Term Format into a Dart object.
  ///
  /// The decoded data is then returned as a Dart object.
  /// The type of the returned object is specified as [T].
  T unpack<T extends Object?>(List<int> toDecode) {
    final decoder = Decoder(Uint8List.fromList(toDecode));
    var decoded = decoder.decode();

    return decoded;
  }

  Uint8List pack<T extends Object?>(T toEncode,
      [int defaultBufferSize = Encoder.defaultBufferSize]) {
    final encoder = Encoder(defaultBufferSize);

    return encoder.encode(toEncode);
  }

  EterlDecoder<T> unpacker<T extends Object?>() => EterlDecoder<T>();
}

class EterlDecoder<T> extends Converter<List<int>, T> {
  @override
  T convert(List<int> input) => eterl.unpack(input);

  @override
  ByteConversionSink startChunkedConversion(Sink<T> sink) {
    return _EterlConversionSink<T>(sink);
  }
}

/// Instance of the erlpack encoder and decoder.
const eterl = Eterl._();

/// Shorthand for [eterl.unpack].
///
/// This is useful when a shadowing `eterl` variable is present.
T eterlUnpack<T extends Object?>(List<int> toDecode) => eterl.unpack(toDecode);

/// Shorthand for [eterl.pack].
///
/// This is useful when a shadowing `eterl` variable is present.
Uint8List eterlPack<T extends Object?>(T toEncode,
        [int defaultBufferSize = Encoder.defaultBufferSize]) =>
    eterl.pack(toEncode, defaultBufferSize);

class _EterlConversionSink<T> extends ByteConversionSink {
  final Sink<T> _sink;
  _EterlConversionSink(this._sink);

  @override
  void add(List<int> chunk) {
    _sink.add(eterl.unpack<T>(chunk));
  }

  @override
  void close() {}

  @override
  void addSlice(List<int> chunk, int startIndex, int endIndex, bool isLast) {
    if (isLast) close();
  }
}
