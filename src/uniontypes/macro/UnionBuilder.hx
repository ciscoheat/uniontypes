package uniontypes.macro;

import haxe.macro.MacroStringTools;
#if macro
import haxe.macro.Expr.FieldType;
import haxe.macro.Expr.ExprDef;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.TypeDefKind;
import haxe.macro.Context;
import haxe.macro.Type;

using Lambda;
using haxe.macro.ExprTools;

class UnionBuilder {
    static final nameTable = [
        "Bool" => "Boolean",
        "Float" => "Floating",
        "Int" => "Integer"
    ];

    static public function build(checkUnknownType = false) {
        var localType : ClassType = null;

        final unionTypes = switch Context.getLocalType() {
            case TInst(t, params): 
                localType = t.get();
                params;
            case _: Context.error("Class expected", Context.currentPos());
        }

        // Sort Int before Float to avoid casting issues
        {
            final float = unionTypes.find(f -> switch f {
                case TAbstract(t, _) if(t.get().name == "Float"): true;
                case _: false;
            });

            if(float != null) {
                unionTypes.remove(float);
                unionTypes.push(float);
            }
        }

        final unionName = [for(t in unionTypes) switch t {
            case TInst(t, _): t.get().name;
            case TAbstract(t, _): 
                t.get().name;
            case t: Context.error('Unsupported Union name type: $t', Context.currentPos());
        }].join('Or');

        trace('===== $unionName =====');

        final unionType = {
            function ifExpr(it) {
                final t : Type = it.next();
                final enumValue = switch t {
                    case TInst(t, _):
                        final inst = t.get();
                        nameTable.exists(inst.name) ? nameTable[inst.name] : inst.name;
                    case TAbstract(t, _): 
                        final inst = t.get();
                        nameTable.exists(inst.name) ? nameTable[inst.name] : inst.name;
                    case _:
                        Context.error('Unsupported Union type: $t', Context.currentPos());
                }
                final enumValue = ECall(macro $i{enumValue}, [macro cast this]);

                final typeToCheck = switch t {
                    case TInst(t, _):
                        final inst = t.get();
                        MacroStringTools.toDotPath(inst.pack, inst.name);
                    case TAbstract(t, _): 
                        final inst = t.get();
                        MacroStringTools.toDotPath(inst.pack, inst.name);    
                    case _:
                        Context.error('Unsupported Union type: $t', Context.currentPos());
                }

                return if(it.hasNext()) EIf(
                    macro Std.isOfType(this, $i{typeToCheck}), 
                    {expr: enumValue, pos: Context.currentPos()}, 
                    {expr: ifExpr(it), pos: Context.currentPos()}
                ) else
                    enumValue;
            }

            final ifExpr = EIf(
                macro this == null, 
                macro Null, 
                {expr: ifExpr(unionTypes.iterator()), pos: Context.currentPos()}
            );

            final typeField = {
                pos: Context.currentPos(),
                name: 'type',
                meta: null,
                doc: null,
                access: [APublic],
                kind: FFun({
                    ret: null,
                    params: null,
                    expr: {expr: ifExpr, pos: Context.currentPos()},
                    args: []
                })
            }

            trace({expr: ifExpr, pos: Context.currentPos()}.toString());

            {
                pos: Context.currentPos(),
                params: null,
                pack: localType.pack,
                name: unionName,
                meta: null,
                kind: TypeDefKind.TDAbstract(macro : Dynamic, unionTypes.map(Context.toComplexType), []),
                isExtern: null,
                fields: [typeField],
                doc: null
            }
        }

        return null;
    }
}
#end