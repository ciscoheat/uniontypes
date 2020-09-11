using buddy.Should;

import UnionClass.UnionClassType;

class SomeClass {
  public final s : String;
  public function new(s) this.s = s;
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

        /*
        final p = {test: 123};
        final x : UnionClass = cast p;
        x.type().should.equal(UnionClassType.Unknown(p));
        */
      });

      it("should work with the macro builder", {
        final x : Union.Union3<String, Float, Int> = null;
        x.type().should.equal(StringOrFloatOrIntType.Null);

        final x : Union.Union3<String, Float, Int> = "string";
        x.type().should.equal(StringOrFloatOrIntType.String("string"));

        final x : Union.Union3<String, Float, Int> = 123;
        x.type().should.equal(StringOrFloatOrIntType.Int(123));

        final x : Union.Union3<String, Float, Int> = 123.45;
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
  
        final x : Union.Union3<String, Float, Int> = "test";
        testUnion(x).should.be(true);

        final x : Union.Union3<String, Float, Int> = 123;
        testUnion(x).should.be(true);

        final x : Union.Union3<String, Float, Int> = 123.45;
        testUnion(x).should.be(true);

        final x : Union.Union3<String, Float, Int> = null;
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
    });
  }
}