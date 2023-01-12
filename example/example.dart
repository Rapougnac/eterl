import 'package:eterl/eterl.dart';

void main(List<String> args) {
  final packed = eterl.pack({'no': 1, 2: 'dont like it'});
  print(packed);

  // Be aware that all keys are stringified in Maps.
  final unpacked = eterl.unpack(packed);
  print(unpacked);
}
