import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:eterl/src/constants.dart';
import 'max_int_value.dart' if (dart.library.io) 'max_int_value_vm.dart';

class Encoder {
  static const int defaultBufferSize = 128;

  late Uint8List _buffer;
  late ByteData _bytes;
  int _offset = 1;

  Encoder([int defaultBufferSize = Encoder.defaultBufferSize]) {
    _buffer = Uint8List(defaultBufferSize);
    _bytes = _buffer.buffer.asByteData();
    _bytes.setUint8(0, version);
  }

  void _ensure(int size) {
    final capacity = _buffer.length;
    final minCapacity = _offset + size + 1;
    if (minCapacity > capacity) {
      final len = math.max(capacity * 2, minCapacity);
      final oldBuffer = _buffer;
      _buffer = Uint8List(len);
      for (int i = 0; i < oldBuffer.length; i++) {
        _buffer[i] = oldBuffer[i];
      }
      _bytes = _buffer.buffer.asByteData();
    }
  }

  void _append8(int value) {
    _bytes.setUint8(_offset++, value);
  }

  void _append32(int value) {
    _bytes.setUint32(_offset, value);
    _offset += 4;
  }

  Uint8List encode(value) {
    _encodeValue(value);
    return _buffer.sublist(0, _offset);
  }

  _encodeValue(value) {
    if (value == null) {
      _encodeAtom('nil');
      return;
    }

    if (value is List) {
      if (value.isEmpty) {
        _ensure(1);
        _append8(nilExt);
        return;
      }

      _ensure(1 + 4 + 1);
      _append8(listExt);
      _append32(value.length);

      for (var i = 0; i < value.length; i++) {
        _encodeValue(value[i]);
      }

      _append8(nilExt);
      return;
    }

    if (value is Map) {
      _ensure(1 + 4);
      _append8(mapExt);
      final keys = value.keys;
      _append32(keys.length);

      for (var i = 0; i < keys.length; i++) {
        _encodeString(keys.toList()[i].toString());
        _encodeValue(value[keys.toList()[i]]);
      }

      return;
    }

    if (value is String) {
      _encodeString(value);
      return;
    }

    if (value is num) {
      if (value is int) {
        if (value > -1 && value < 1 << 8) {
          _ensure(1 + 1);
          _append8(smallIntegerExt);
          _append8(value);
          return;
        }

        // Hello js 32 bits ints :3
        if (const bool.fromEnvironment('dart.library.js_util')) {
          if (value >= 1 << 31 && value < -(1 << 31)) {
            _ensure(1 + 4);
            _append8(integerExt);
            _bytes.setInt32(_offset, value);
            _offset += 4;
            return;
          }
        } else {
          // Max int value
          if (value >= 1 << 63 && value < maxIntValue) {
            _ensure(1 + 4);
            _append8(integerExt);
            _bytes.setInt32(_offset, value);
            _offset += 4;
            return;
          }
        }

        _encodeBigInt(BigInt.from(value));
        return;
      }

      _ensure(1 + 8);
      _append8(newFloatExt);
      _bytes.setFloat64(_offset, value.toDouble());
      _offset += 8;
      return;
    }

    if (value is bool) {
      // 'true' or 'false'
      _encodeAtom(value.toString());
    }

    if (value is BigInt) {
      _encodeBigInt(value);
      return;
    }
  }

  void _encodeBigInt(BigInt value) {
    _ensure(1 + 1 + 1);
    _append8(smallBigExt);

    final byteLengthIndex = _offset++;
    _append8(value < BigInt.zero ? 1 : 0);
    var ull = value < BigInt.zero ? -value : value;
    var byteLength = 0;
    while (ull > BigInt.zero) {
      _ensure(1);
      _append8((ull & BigInt.from(0xff)).toInt());
      ull >>= 8;
      byteLength++;
    }

    if (byteLength < 256) {
      _bytes.setUint8(byteLengthIndex, byteLength);
      return;
    }

    _bytes.setUint8(byteLengthIndex - 1, largeBigExt);

    _ensure(3);
    for (var i = _offset; i >= byteLengthIndex; i--) {
      _buffer[i + 3] = _buffer[i];
    }

    _offset += 3;

    _bytes.setUint32(byteLengthIndex, byteLength);
  }

  void _encodeAtom(String atom) {
    _ensure(1 + 1 + atom.length);
    _append8(smallAtomUtf8Ext);
    _append8(atom.length);

    // atom is always ASCII ('true', 'false', or 'nil').
    for (int i = 0; i < atom.length; i++) {
      _buffer[_offset++] = atom.codeUnitAt(i);
    }
  }

  void _encodeString(String string) {
    final encoded = utf8.encode(string);
    final stringLength = encoded.length;
    _ensure(1 + 4 + stringLength);
    _append8(binaryExt);
    _append32(stringLength);
    for (int i = 0; i < encoded.length; i++) {
      _buffer[_offset + i] = encoded[i];
    }
    _offset += stringLength;
  }
}
