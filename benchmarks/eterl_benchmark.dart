import 'dart:convert';

import 'package:benchmark/benchmark.dart';
import 'package:eterl/eterl.dart';

final parsedData = {
  'a': 1,
  'b': {
    'c': [3, 4, 5],
    'd': {
      'c': [
        {'1': 2},
        3,
        'é	><,péé~~😀😉😐😑😍🤩😑😪😴😓😲'
      ]
    }
  },
  'd': null,
  'e': {
    'g': [
      {'h': null, 'i': 'j'},
      '147878194'
    ],
    'a__bb': '124',
    '124': 4,
    '9': []
  },
  '6': null,
};

void main() {
  final data = json.encode(parsedData);
  final encodedData = eterl.pack(parsedData, 500);
  benchmark('json.decode', () => json.decode(data));
  benchmark('json.encode', () => json.encode(parsedData));

  benchmark('eterl.unpack', () => eterl.unpack(encodedData));
  benchmark('eterl.pack', () => eterl.pack(parsedData, 500));
  benchmark('eterl.pack known length',
      () => eterl.pack(parsedData, encodedData.length));
}
/**
 *  DONE  ./benchmarks/erlpack_benchmark.dart (11 s)
 ✓ json.decode (186 us)
 ✓ json.encode (147 us)
 ✓ eterl.unpack (118 us)
 ✓ eterl.pack (159 us)
 ✓ eterl.pack known length (314 us)

Benchmark suites: 1 passed, 1 total
Benchmarks:       5 passed, 5 total
Time:             11 s
Ran all benchmark suites.
 */