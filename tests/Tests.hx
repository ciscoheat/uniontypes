using buddy.Should;

import UnionClass.UnionClassType;

class Tests extends buddy.SingleSuite {
  function testUnion(given, expected) {

  }

  public function new() {
    describe("Uniontypes", {
      it("should work with basic types according to the example", {
        final x : UnionClass = null;
        x.type().should.equal(UnionClassType.Null);

        final x : UnionClass = "string";
        x.type().should.equal(UnionClassType.String("string"));

        final x : UnionClass = 123;
        x.type().should.equal(UnionClassType.Integer(123));

        final date = std.Date.now();
        final x : UnionClass = date;
        x.type().should.equal(UnionClassType.Date(date));

        final x : UnionClass = true;
        x.type().should.equal(UnionClassType.Boolean(true));

        final x : UnionClass = 123.45;
        x.type().should.equal(UnionClassType.Floating(123.45));
      });
    });
  }
}