package subpack;

class SubClass {
    public final s : String;
    public function new(s) this.s = s;
  }
  
class SubTest {
    public static function test() {
        final d = Date.now();
        final x : Union<String, Date> = d;        
        return x.type().equals(subpack.SubTest.StringOrDateType.Date(d));
    }

    public static function comparer() : Union<SubClass, Int> {
        return 12345;
    }
}