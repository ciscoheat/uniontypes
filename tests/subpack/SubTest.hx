package subpack;

class SubTest {
    public static function test() {
        final d = Date.now();
        final x : Union<String, Date> = d;        
        return x.type().equals(subpack.SubTest.StringOrDateType.Date(d));
    }
}