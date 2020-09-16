# Uniontypes

For those libraries that return one thing *or* another. Similar to [Union types in Typescript](https://www.typescriptlang.org/docs/handbook/unions-and-intersections.html).

## Installation

`haxelib install uniontypes`

## Usage

```haxe
final x : Union<Int, String> = "A string";

switch x.type() {
    case Int(i): trace('It was an Int: $i');
    case String(s): trace('It was a String: ${s.toUpperCase()}');
    case Null: trace('It was null');
}
```

The `Union` type is for two types, but the library also includes `Union3`, `Union4`, `Union5` and `Union6` for more extreme cases.

## To trust, or not to trust

Depending on how much you trust the data in the union, you can specify different types of unions:

- `Union.TrustedUnion` assumes a value will never be `null`, meaning a `Null` enum constructor will *not* exist.
- `Union.UntrustedUnion` includes both a `Null` and an `Unknown(u : Dynamic)` enum constructor.