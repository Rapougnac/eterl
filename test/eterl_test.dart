// ignore_for_file: prefer_void_to_null

import 'dart:math';
import 'dart:typed_data';

import 'package:eterl/eterl.dart';
import 'package:test/test.dart';

// TODO: Maybe create a separate file for encoding/decoding.

const helloWorldList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
const helloWorldListWithNull = [1, 2, 3, 4, 5, 0, 6, 7, 8, 9, 10, 11];

void main() {
  group('Decoder', () {
    test('Short list via string with null byte', () {
      final unpacked =
          eterl.unpack<List<int>>([131, 107, 0, 12, ...helloWorldListWithNull]);
      expect(unpacked, equals(helloWorldListWithNull));
    });

    test('Short list via string without null byte', () {
      final unpacked =
          eterl.unpack<List<int>>([131, 107, 0, 11, ...helloWorldList]);

      expect(unpacked, equals(helloWorldList));
    });

    test('Binary with null byte', () {
      expect(
        eterl.unpack<String>([
          131,
          109,
          0,
          0,
          0,
          12,
          104,
          101,
          108,
          108,
          111,
          0,
          32,
          119,
          111,
          114,
          108,
          100
        ]),
        'hello\u0000 world',
      );
    });

    test('Binary without null byte', () {
      final unpacked = eterl.unpack<String>([
        131,
        109,
        0,
        0,
        0,
        11,
        104,
        101,
        108,
        108,
        111,
        32,
        119,
        111,
        114,
        108,
        100
      ]);

      expect(unpacked, 'hello world');
    });

    test('Map', () {
      final data = [
        131,
        116,
        0,
        0,
        0,
        3,
        109,
        0,
        0,
        0,
        1,
        97,
        97,
        1,
        109,
        0,
        0,
        0,
        1,
        50,
        97,
        2,
        109,
        0,
        0,
        0,
        1,
        51,
        108,
        0,
        0,
        0,
        3,
        97,
        1,
        97,
        2,
        97,
        3,
        106
      ];

      expect(
        eterl.unpack<Map>(data),
        equals(
          {
            'a': 1,
            '2': 2,
            '3': [1, 2, 3]
          },
        ),
      );
    });

    test('False', () {
      expect(
        eterl.unpack<bool>([131, 115, 5, 102, 97, 108, 115, 101]),
        false,
      );
    });

    test('True', () {
      expect(eterl.unpack<bool>([131, 115, 4, 116, 114, 117, 101]), true);
    });

    test('Nil token is an empty list', () {
      expect(eterl.unpack<List>([131, 106]), []);
    });

    test('Nil atom is null', () {
      expect(eterl.unpack<Null>([131, 115, 3, 110, 105, 108]), null);
    });

    test('Null is null', () {
      expect(eterl.unpack<Null>([131, 115, 4, 110, 117, 108, 108]), null);
    });

    group('Doubles', () {
      test('First double', () {
        final data = [
          131,
          99,
          50,
          46,
          53,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          48,
          101,
          43,
          48,
          48,
          0,
          0,
          0,
          0,
          0,
        ];

        expect(eterl.unpack<double>(data), equals(2.5));
      });

      test('Second double', () {
        final data = [
          131,
          99,
          53,
          46,
          49,
          53,
          49,
          50,
          49,
          50,
          51,
          56,
          52,
          49,
          50,
          51,
          52,
          51,
          49,
          50,
          53,
          48,
          48,
          48,
          101,
          43,
          49,
          51,
          0,
          0,
          0,
          0,
          0,
        ];

        expect(eterl.unpack<double>(data), equals(51512123841234.31));
      });

      test('New double 1', () {
        expect(eterl.unpack<double>([131, 70, 64, 4, 0, 0, 0, 0, 0, 0]),
            equals(2.5));
      });

      test('New double 2', () {
        final unpacked = [131, 70, 66, 199, 108, 204, 235, 237, 105, 40];
        expect(eterl.unpack<double>(unpacked), equals(51512123841234.31));
      });
    });
    test('Small int', () {
      int total = 0;
      for (int i = 0; i < 256; i++) {
        final unpacked = eterl.unpack<int>([131, 97, i]);
        total += unpacked;
      }

      expect(total, equals(32640));
    });

    group('Int32', () {
      test('Int32 - 1', () {
        expect(eterl.unpack<int>([131, 98, 0, 0, 4, 0]), equals(1024));
      });
      test('Int32 - 2', () {
        expect(eterl.unpack<int>([131, 98, 128, 0, 0, 0]), equals(-2147483648));
      });
      test('Int32 - 3', () {
        expect(eterl.unpack<int>([131, 98, 127, 255, 255, 255]),
            equals(2147483647));
      });
    });

    group('Small BigInts', () {
      test('Small BigInts - 1', () {
        expect(eterl.unpack([131, 110, 4, 1, 1, 2, 3, 4]), equals(-67305985));
      });
      test('Small BigInts - 2', () {
        expect(eterl.unpack([131, 110, 4, 0, 1, 2, 3, 4]), equals(67305985));
      });
      test('Small BigInts - 3', () {
        expect(eterl.unpack([131, 110, 10, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
            equals(BigInt.parse('47390263963055590408705')));
      });
    });

    group('Large BigInts', () {
      late final List<int> data;
      test('Large BigInt - 1', () {
        data = [
          131,
          111,
          0,
          0,
          1,
          0,
          0,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          28,
          199,
          113,
          22,
          163,
          161,
          231,
          18,
          130,
          10,
          140,
          88,
          232,
          79,
          41,
          99,
          87,
          160,
          31,
          239,
          212,
          9,
          5,
          208,
          206,
          87,
          81,
          246,
          53,
          178,
          215,
          172,
          140,
          169,
          180,
          33,
          82,
          13,
          69,
          8,
          242,
          141,
          255,
          96,
          221,
          202,
          68,
          140,
          189,
          213,
          98,
          4,
          49,
          253,
          0,
          197,
          202,
          104,
          209,
          131,
          150,
          170,
          19,
          94,
          212,
          245,
          195,
          220,
          229,
          139,
          107,
          230,
          29,
          60,
          56,
          237,
          150,
          126,
          12,
          44,
          208,
          207,
          249,
          80,
          146,
          221,
          125,
          152,
          15,
          39,
          124,
          20,
          199,
          180,
          178,
          209,
          155,
          138,
          97,
          145,
          61,
          252,
          128,
          215,
          20,
          37,
          196,
          3,
          126,
          19,
          0,
          255,
          1,
          88,
          136,
          207,
          38,
          78,
          46,
          46,
          145,
          149,
          228,
          150,
          44,
          20,
          72,
          9,
          57,
          165,
          193,
          69,
          132,
          207,
          89,
          254,
          121,
          28,
          3,
          31,
          151,
          8,
          119,
          77,
          187,
          226,
          242,
          129,
          144,
          212,
          140,
          1,
          94,
          91,
          227,
          101,
          4,
          64,
          45,
          96,
          102,
          81,
          218,
          17,
          160,
          136,
          47,
          63,
          204,
          120,
          202,
          146,
          67,
          172,
          167,
          189,
          251,
          227,
          28,
          87,
          4,
          88,
        ];
        expect(eterl.unpack(data), equals(BigInt.parse('1' * 617)));
      });

      test('Large BigInt - 2', () {
        final uin8ListData = Uint8List.fromList(data);
        uin8ListData.buffer.asByteData().setUint8(6, 1);
        expect(
            eterl.unpack(uin8ListData), equals(BigInt.parse('-${'1' * 617}')));
      });
    });

    test('Atoms', () {
      expect(
          eterl.unpack([
            131,
            100,
            0,
            13,
            103,
            117,
            105,
            108,
            100,
            32,
            109,
            101,
            109,
            98,
            101,
            114,
            115
          ]),
          equals('guild members'));
    });

    group('Tuples', () {
      test('Tuple - 1', () {
        final unpacked = [
          131,
          104,
          3,
          109,
          0,
          0,
          0,
          6,
          118,
          97,
          110,
          105,
          115,
          104,
          97,
          1,
          97,
          4
        ];
        expect(eterl.unpack(unpacked), equals(['vanish', 1, 4]));
      });

      test('Tuple - 2', () {
        final unpacked = [
          131,
          105,
          0,
          0,
          0,
          3,
          109,
          0,
          0,
          0,
          6,
          118,
          97,
          110,
          105,
          115,
          104,
          97,
          1,
          97,
          4
        ];
        expect(eterl.unpack(unpacked), equals(['vanish', 1, 4]));
      });
    });

    group('Malformed tokens', () {
      test('Malformed token - 1', () {
        final data = [
          131,
          113,
          0,
          0,
          0,
          3,
          97,
          2,
          97,
          2,
          97,
          3,
          108,
          0,
          0,
          0,
          3,
          97,
          1,
          97,
          2,
          97,
          3,
          106,
          109,
          0,
          0,
          0,
          1,
          97,
          97,
          1,
        ];
        expect(() => eterl.unpack(data), throwsException);
      });

      test('Malformed token - 2', () {
        expect(() => eterl.unpack([131, 107, 0]), throwsRangeError);
      });
    });

    test('Malformed list', () {
      expect(() => eterl.unpack([131, 116, 0, 0, 0, 3, 97, 2, 97, 2, 97, 3]),
          throwsRangeError);
    });

    test('Wrong version', () {
      expect(() => eterl.unpack([130]), throwsException);
    });
  });

  group('Encoder', () {
    test('String with null byte', () {
      final expected = [
        131,
        109,
        0,
        0,
        0,
        12,
        104,
        101,
        108,
        108,
        111,
        0,
        32,
        119,
        111,
        114,
        108,
        100
      ];

      expect(expected, equals(eterl.pack('hello\u0000 world')));
    });

    test('String without null byte', () {
      final expected = [
        131,
        109,
        0,
        0,
        0,
        11,
        104,
        101,
        108,
        108,
        111,
        32,
        119,
        111,
        114,
        108,
        100
      ];

      expect(expected, equals(eterl.pack('hello world')));
    });

    test('Map', () {
      final expected = [
        131,
        116,
        0,
        0,
        0,
        3,
        109,
        0,
        0,
        0,
        1,
        97,
        97,
        1,
        109,
        0,
        0,
        0,
        1,
        50,
        97,
        2,
        109,
        0,
        0,
        0,
        1,
        51,
        108,
        0,
        0,
        0,
        3,
        97,
        1,
        97,
        2,
        97,
        3,
        106
      ];

      expect(
        expected,
        equals(
          eterl.pack(
            {
              'a': 1,
              2: 2,
              3: [1, 2, 3]
            },
          ),
        ),
      );
    });

    test('False', () {
      final expected = [131, 119, 5, 102, 97, 108, 115, 101];
      expect(expected, equals(eterl.pack(false)));
    });

    test('True', () {
      final expected = [131, 119, 4, 116, 114, 117, 101];
      expect(expected, equals(eterl.pack(true)));
    });

    test('Null is nil atom', () {
      final expected = [131, 119, 3, 110, 105, 108];
      expect(expected, equals(eterl.pack(null)));
    });

    group('Doubles as new doubles', () {
      test('New Double - 1', () {
        final expected = [131, 70, 64, 4, 0, 0, 0, 0, 0, 0];
        expect(expected, equals(eterl.pack(2.5)));
      });

      test('Double - 2', () {
        final expected = [131, 70, 66, 199, 108, 204, 235, 237, 105, 40];
        expect(expected, equals(eterl.pack(51512123841234.31)));
      });
    });

    test('Small ints', () {
      // Keep loop?
    }, skip: 'Add a way to go to 256 ints while testing');

    group('Int32', () {
      test('Int32 - 1', () {
        final expected = [131, 98, 0, 0, 4, 0];
        expect(expected, equals(eterl.pack(1024)));
      });

      test('Int32 - 2', () {
        final expected = [131, 98, 128, 0, 0, 0];
        expect(expected, equals(eterl.pack(1 << 31)));
      });

      test('Int32 - 3', () {
        final expected = [131, 98, 127, 255, 255, 255];
        expect(expected, equals(eterl.pack(-(1 << 31) - 1)));
      });
    });

    group('BigInts', () {
      test('BigInt - 1', () {
        final expected = [131, 98, 128, 0, 0, 0];
        expect(expected, equals(eterl.pack(pow(2, 31))));
      });
      test('BigInt - 2', () {
        final expected = [131, 98, 127, 255, 255, 255];
        expect(expected, equals(eterl.pack(-1 - pow(2, 31))));
      });
      test('BigInt - 3', () {
        final expected = [131, 110, 4, 1, 1, 2, 3, 4];
        expect(expected, equals(eterl.pack(BigInt.from(-67305985))));
      });
      test('BigInt - 4', () {
        final expected = [131, 110, 4, 0, 1, 2, 3, 4];
        expect(expected, equals(eterl.pack(BigInt.from(67305985))));
      });
      test('BigInt - 5', () {
        final expected = [131, 110, 8, 1, 1, 2, 3, 4, 5, 6, 7, 8];
        expect(expected, equals(eterl.pack(BigInt.from(-578437695752307201))));
      });
      test('BigInt - 6', () {
        final expected = [131, 110, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8];
        expect(expected, equals(eterl.pack(BigInt.from(578437695752307201))));
      });
    });

    test('List', () {
      final expected = [
        131,
        108,
        0,
        0,
        0,
        4,
        97,
        1,
        109,
        0,
        0,
        0,
        3,
        116,
        119,
        111,
        70,
        64,
        8,
        204,
        204,
        204,
        204,
        204,
        205,
        109,
        0,
        0,
        0,
        4,
        102,
        111,
        117,
        114,
        106,
      ];

      expect(expected, equals(eterl.pack([1, 'two', 3.1, 'four'])));
    });

    test('Empty list', () {
      expect([131, 106], equals(eterl.pack([])));
    });
  });
}
