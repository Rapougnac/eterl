# Eterl (External Term Erlang (format))

Eterl is a fast packer and unpacker for the External Term Erlang Format (version 131).

## Example
```dart
import 'package:eterl/eterl.dart';

void main() {
    final data = [{'hello': ['eterl', 1,2,3], 'l': [{'im': 'nested', 'i': {'also': 'support unicode 💀🗿🥀 èè¨àà¨ü!ääüäöä£üüöäüéèéè>>>><<<<>>~~~'}}]}];
    final packed = eterl.pack(data, 200);
    final unpacked = eterl.unpack(packed);
    print(unpacked);
}
```

## Supported terms

- `String`s
- `Atom`s (only while decoding)
- `bool`s
- `double`s
- `int`s
- `BigInt`s\*
- `Map`s
- `List`s
- `Tuple`s (only while decoding)

> **Warning**
> `BigInt`s are serialized into `String`s when dart is transpiled to javascript, and `int`s when 64-bits ints are supported.
> This behaviour may change later.
