package uniontypes.macro;

#if macro
import haxe.macro.Context;

class UnionBuilder {
    static public function build() {
        trace(Context.getLocalType());
        return null;
    }
}
#end