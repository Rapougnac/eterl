import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:eterl/eterl.dart';

const data = {
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

class EterlBenchmark extends BenchmarkBase {
  const EterlBenchmark() : super('Eterl');

  @override
  void run() {
    final encoded = eterl.pack(data);
    final decoded = eterl.unpack(encoded);
    if (decoded.toString() != data.toString()) {
      throw Exception('The decoded data is not equal to the original data');
    }
  }

  @override
  void setup() {}

  @override
  void teardown() {}

  static void main() {
    const EterlBenchmark().report();
  }
}

void main() {
  EterlBenchmark.main();
}