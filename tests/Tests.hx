using buddy.Should;

import UnionClass.UnionClassType;

class SomeClass {
  public final s : String;
  public function new(s) this.s = s;
}

typedef Name = String;

enum Color {
  Red;
  Blue;
  Green;
}

class Tests extends buddy.SingleSuite {
  public function new() {
    describe("Uniontypes", {
      it("should work with basic types according to the example", {
        final x : UnionClass = null;
        x.type().should.equal(UnionClassType.Null);

        final x : UnionClass = "string";
        x.type().should.equal(UnionClassType.String("string"));

        final x : UnionClass = 123;
        x.type().should.equal(UnionClassType.Int(123));

        final date = std.Date.now();
        final x : UnionClass = date;
        x.type().should.equal(UnionClassType.Date(date));

        final x : UnionClass = true;
        x.type().should.equal(UnionClassType.Bool(true));

        final x : UnionClass = 123.45;
        x.type().should.equal(UnionClassType.Float(123.45));
      });

      it("should work with the macro builder", {
        final x : Union3<String, Float, Int> = null;
        x.type().should.equal(StringOrFloatOrIntType.Null);

        final x : Union3<String, Float, Int> = "string";
        x.type().should.equal(StringOrFloatOrIntType.String("string"));

        final x : Union3<String, Float, Int> = 123;
        x.type().should.equal(StringOrFloatOrIntType.Int(123));

        final x : Union3<String, Float, Int> = 123.45;
        x.type().should.equal(StringOrFloatOrIntType.Float(123.45));
      });

      it("should work with switch statements", {
        function testUnion(inp : StringOrFloatOrInt)
          return switch inp.type() {
            case Null: false;
            case String(s): s == "test";
            case Int(i): i == 123;
            case Float(f): f == 123.45;
          }
  
        final x : Union3<String, Float, Int> = "test";
        testUnion(x).should.be(true);

        final x : Union3<String, Float, Int> = 123;
        testUnion(x).should.be(true);

        final x : Union3<String, Float, Int> = 123.45;
        testUnion(x).should.be(true);

        final x : Union3<String, Float, Int> = null;
        testUnion(x).should.be(false);
      });

      it("should work with classes", {
        final x : Union<SomeClass, Bool> = new SomeClass("A class");
        
        switch x.type() {
          case Null: fail("x was null");
          case Bool(b): fail('x was bool $b');
          case SomeClass(s): s.s.should.be("A class");
        }

        final x : Union<SomeClass, Bool> = true;
        
        switch x.type() {
          case Null: fail("x was null");
          case Bool(b): b.should.be(true);
          case SomeClass(s): fail('x was SomeClass $s');
        }

        final x : Union<SomeClass, Bool> = null;
        
        switch x.type() {
          case Null: x.should.be(null);
          case Bool(b): fail('x was bool $b');
          case SomeClass(s): fail('x was SomeClass $s');
        }
      });

      it("should work with packages", {
        subpack.SubTest.test().should.be(true);
      });

      it("should support Typedefs", {
        final x : Union<Float, Name> = "A name";
        x.type().should.equal(FloatOrNameType.Name("A name"));
      });

      it("should support Enums", {
        final x : Union<Float, Color> = Green;
        x.type().should.equal(FloatOrColorType.Color(Green));
      });

      it("should have Trusted and Untrusted Unions in each module.", {
        // Also checks for name clashes
        final x : Union.Union<Int, String> = "neutral";
        switch x.type() {
          case Null: fail('x was null');
          case Int(i): fail('x was Int $i');
          case String(s): s.should.be("neutral");
        }        

        final x : Union.TrustedUnion<Int, String> = "trusted";
        switch x.type() {
          case Int(i): fail('x was Int $i');
          case String(s): s.should.be("trusted");
        }        

        final x : Union.UntrustedUnion<Int, String> = "untrusted";
        switch x.type() {
          case Null: fail('x was null');
          case Int(i): fail('x was Int $i');
          case String(s): s.should.be("untrusted");
          case Unknown(u): fail('x was unknown: $u');
        }

        final unknown = {test: 123};
        final x : Union.UntrustedUnion<Int, String> = cast unknown;
        x.type().should.equal(UntrustedIntOrStringType.Unknown(unknown));
      });

      it("should be comparable with identity, even if in different packages", {
        final x : Union<Float, Name> = "A name";
        final y : Union<Float, Name> = "A name";
        x.should.be(y);

        final date = std.Date.now();
        final x : Union<Int, Date> = date;
        final y : Union<Int, Date> = date;
        x.should.be(y);

        final x : Union<String, Int> = 12345;
        x.should.be(subpack.SubTest.comparer());
        
        final x : Union<subpack.SubTest.SubClass, Int> = 12345;
        x.should.be(subpack.SubTest.comparer());
      });
    });
  }
}