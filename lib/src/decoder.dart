import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:eterl/src/constants.dart';

import 'max_int_value.dart' if (dart.library.io) 'max_int_value_vm.dart';

class Decoder {
  int _offset = 1;

  final Uint8List _buffer;

  final ByteData _bytes;

  Decoder(Uint8List buffer)
      : _buffer = buffer,
        _bytes = buffer.buffer.asByteData() {
    final bufferVersion = _buffer.buffer.asByteData().getUint8(0);

    if (bufferVersion != version) {
      throw Exception('The version is un supported'
          '(found: $bufferVersion, required: $version)');
    }
  }

  int _read8() => _bytes.getUint8(_offset++);

  int _read16() {
    final val = _bytes.getUint16(_offset);
    _offset += 2;
    return val;
  }

  int _read32() {
    final val = _bytes.getUint32(_offset);
    _offset += 4;
    return val;
  }

  decode() {
    final tag = _read8();

    switch (tag) {
      case mapExt:
        final len = _read32();
        final map = <String, dynamic>{};

        for (int i = 0; i < len; i++) {
          map[decode().toString()] = decode();
        }

        return map;
      case listExt:
        final list = _decodeList(_read32());
        // assume that the tail marker is always present.
        _offset++;

        return list;
      case nilExt:
        return [];
      case binaryExt:
        return _decodeString(_read32());
      case integerExt:
        final val = _bytes.getInt32(_offset);
        _offset += 4;
        return val;
      case smallIntegerExt:
        return _read8();
      case smallBigExt:
        if (const bool.fromEnvironment('dart.library.js_util')) {
          return _decodeBigInt(BigInt.from(_read8())).toString();
        } else {
          final bigInt = _decodeBigInt(BigInt.from(_read8()));

          if (bigInt > BigInt.from(maxIntValue)) {
            return bigInt;
          } else {
            return bigInt.toInt();
          }
        }
      case largeBigExt:
        return _decodeBigInt(BigInt.from(_read32()));
      case newFloatExt:
        final val = _bytes.getFloat64(_offset);
        _offset += 8;
        return val;
      case smallTupleExt:
        return _decodeList(_read8());
      case largeTupleExt:
        return _decodeList(_read32());
      case atomExt:
      case atomUtf8Ext:
        return _decodeAtom(_read16());
      case smallAtomExt:
      case smallAtomUtf8Ext:
        return _decodeAtom(_read8());
      case stringExt:
        final len = _read16();
        return _buffer.sublist(_offset, (_offset += len));
      case floatExt:
        return Decimal.parse(_decodeString(31, ascii).replaceAll('\u0000', ''))
            .toDouble();
      default:
        throw Exception('Unsupported tag ($tag)');
    }
  }

  List _decodeList(int len) {
    final list = List<dynamic>.filled(len, null);
    for (int i = 0; i < len; i++) {
      list[i] = decode();
    }

    return list;
  }

  String _decodeString(int len, [Encoding encoding = utf8]) =>
      encoding.decode(_buffer.sublist(_offset, (_offset += len)));

  BigInt _decodeBigInt(BigInt len) {
    final sign = _read8();
    // I'm missing the n notation :(
    var val = BigInt.zero;
    for (var i = BigInt.zero; i < len; i += BigInt.one) {
      val |= BigInt.from((_read8())) << (i * BigInt.from(8)).toInt();
    }

    return sign == 0 ? val : -val;
  }

  _decodeAtom(int len) {
    final atom = _decodeString(len);
    switch (atom) {
      case 'nil':
      case 'null':
        return null;
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        return atom;
    }
  }
}
