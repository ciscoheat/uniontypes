package uniontypes.macro;

#if macro
import haxe.macro.MacroStringTools;
import haxe.macro.Expr.FieldType;
import haxe.macro.Expr.ExprDef;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.TypeDefKind;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr.ComplexType;

using Lambda;
using haxe.macro.ExprTools;

class UnionBuilder {
    static final createdUnions = new Map<String, ComplexType>();

    static final nameTable = [
        "Bool" => "Boolean",
        "Float" => "Floating",
        "Int" => "Integer"
    ];

    static function toDotPath(t : {pack : Array<String>, module: String}, name : String) {
        trace(t.pack.join('.') + "." + t.module + "." + name);
        return MacroStringTools.toDotPath(
            t.pack.concat((t.module == name || t.module == '') ? [] : [t.module]), 
            name
        );
    }

    static public function build(checkUnknownType = false) {
        final curPos = Context.currentPos();
        final localModule = Context.getLocalModule();
        var localType : ClassType = null;

        final unionTypes = switch Context.getLocalType() {
            case TInst(t, params): 
                localType = t.get();
                params;
            case _: Context.error("Class expected", curPos);
        }

        final unionName = [for(t in unionTypes) switch t {
            case TInst(t, _): t.get().name;
            case TAbstract(t, _): 
                t.get().name;
            case t: Context.error('Unsupported Union name type: $t', curPos);
        }].join('Or');

        // The path is irrelevant since the type will be defined in the current module.
        final unionFullName = toDotPath({pack: [], module: ''}, unionName);
        if(createdUnions.exists(unionFullName)) {
            return createdUnions[unionFullName];
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

        // Define Enum for Union
        final unionEnumName = {
            final unionEnumName = unionName + "Type";
            final enumType = {
                final nullField = {
                    pos: curPos,
                    name: 'Null',
                    kind: FFun({
                        ret: null,
                        expr: null,
                        args: []
                    })
                }

                {
                    pos: curPos,
                    pack: localType.pack,
                    name: unionEnumName,
                    kind: TDEnum,
                    fields: [for(t in unionTypes) {
                        final name = switch t {
                            case TInst(t, _):
                                final inst = t.get();
                                nameTable.exists(inst.name) ? nameTable[inst.name] : inst.name;
                            case TAbstract(t, _): 
                                final inst = t.get();
                                nameTable.exists(inst.name) ? nameTable[inst.name] : inst.name;
                            case _:
                                Context.error('Unsupported Union enum type: $t', curPos);
                        }

                        {
                            pos: curPos,
                            name: name,
                            kind: FFun({
                                ret: null,
                                expr: null,
                                args: [{
                                    type: Context.toComplexType(t),
                                    name: name.charAt(0).toLowerCase()
                                }]
                            })
                        }
                    }].concat([nullField])
                }
            }

            Context.defineType(enumType);

            unionEnumName;
        }

        //trace('===== $unionName =====');

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
                        Context.error('Unsupported Union enum type: $t', curPos);
                }
                final enumValue = ECall(macro $p{[unionEnumName, enumValue]}, [macro cast this]);

                final typeToCheck = (switch t {
                    case TInst(t, _):
                        final inst = t.get();
                        toDotPath(inst, inst.name);
                    case TAbstract(t, _): 
                        final inst = t.get();
                        toDotPath(inst, inst.name);    
                    case _:
                        Context.error('Unsupported Union type: $t', curPos);
                }).split('.');

                return if(it.hasNext()) EIf(
                    macro Std.isOfType(this, $p{typeToCheck}), 
                    {expr: enumValue, pos: curPos}, 
                    {expr: ifExpr(it), pos: curPos}
                ) else
                    enumValue;
            }

            final ifExpr = EIf(
                macro this == null, 
                macro $p{[unionEnumName, "Null"]},
                {expr: ifExpr(unionTypes.iterator()), pos: curPos}
            );

            final typeField = {
                pos: curPos,
                name: 'type',
                meta: null,
                doc: null,
                access: [APublic],
                kind: FFun({
                    ret: TPath({pack: localType.pack, name: unionEnumName}),
                    params: null,
                    expr: macro return ${{expr: ifExpr, pos: curPos}},
                    args: []
                })
            }

            //trace({expr: ifExpr, pos: curPos}.toString());

            {
                pos: curPos,
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

        Context.defineType(unionType);
        createdUnions.set(unionFullName, Context.toComplexType(Context.getType(unionFullName)));

        //trace(createdUnions[unionFullName]);

        return createdUnions[unionFullName];
    }
}
#end