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

    static function toDotPath(t : {module: String}, name : String) {
        final moduleName = t.module.split('.');
        return if(moduleName[moduleName.length-1] == name)
            t.module
        else
            t.module + '.' + name;
    }

    static function typeName(t : Type) return switch t {
        case TInst(t, _): t.get().name;
        case TAbstract(t, _): t.get().name;
        case TType(t, _): t.get().name;
        case TEnum(t, _): t.get().name;
        case t: Context.error('Unsupported Union name type: $t', Context.currentPos());
    }

    static public function build(trusted : Null<Bool> = null) {
        final localClass = Context.getLocalClass().get();
        final curPos = Context.currentPos();

        final checkNull = if(trusted == null) true else !trusted;
        final checkUnknownType = if(trusted == null) false else !trusted;

        final unionTypes = switch Context.getLocalType() {
            case TInst(_, params): params;
            case _: Context.error("Class expected", curPos);
        }

        final unionName = (if(trusted == null) '' else (trusted ? 'Trusted' : 'Untrusted')) + 
            unionTypes.map(typeName).join('Or');

        final unionUniqueName = unionName + "<" + [for(t in unionTypes) Std.string(t)].join(',') + ">";

        //trace(unionUniqueName);

        // Check cache
        if(createdUnions.exists(unionUniqueName)) {
            return createdUnions[unionUniqueName];
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

                final unknownField = {
                    pos: curPos,
                    name: 'Unknown',
                    kind: FFun({
                        ret: null,
                        expr: null,
                        args: [{
                            type: macro : Dynamic,
                            name: 'u'
                        }]
                    })
                }

                {
                    pos: curPos,
                    pack: localClass.pack,
                    name: unionEnumName,
                    kind: TDEnum,
                    fields: [for(t in unionTypes) {
                        final name = typeName(t);
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
                    }]
                    .concat(checkNull ? [nullField] : [])
                    .concat(checkUnknownType ? [unknownField] : [])
                }
            }

            Context.defineType(enumType);

            unionEnumName;
        }

        //trace('===== $unionName =====');

        final unionType = {
            function ifExpr(it) {
                final t : Type = it.next();
                final enumValue = ECall(macro $p{[unionEnumName, typeName(t)]}, [macro cast this]);

                final typeToCheck = (switch t {
                    case TInst(t, _):
                        final inst = t.get();
                        toDotPath(inst, inst.name);
                    case TAbstract(t, _): 
                        final inst = t.get();
                        toDotPath(inst, inst.name);    
                    case TType(t, _): 
                        final inst = t.get();
                        toDotPath(inst, inst.name);
                    case TEnum(t, _): 
                        final inst = t.get();
                        toDotPath(inst, inst.name);            
                    case _:
                        Context.error('Unsupported Union type: $t', curPos);
                }).split('.');

                return if(it.hasNext()) EIf(
                    macro Std.isOfType(this, $p{typeToCheck}), 
                    {expr: enumValue, pos: curPos}, 
                    {expr: ifExpr(it), pos: curPos}
                ) else if(checkUnknownType) EIf(
                    macro Std.isOfType(this, $p{typeToCheck}), 
                    {expr: enumValue, pos: curPos}, 
                    {expr: (macro Unknown(cast this)).expr, pos: curPos}
                ) else
                    enumValue;
            }

            // Check for null unless trusted
            final ifExpr = if(checkNull)
                EIf(
                    macro this == null, 
                    macro $p{[unionEnumName, "Null"]},
                    {expr: ifExpr(unionTypes.iterator()), pos: curPos}
                )
            else
                ifExpr(unionTypes.iterator());

            final typeField = {
                pos: curPos,
                name: 'type',
                meta: null,
                doc: null,
                access: [APublic],
                kind: FFun({
                    ret: TPath({pack: localClass.pack, name: unionEnumName}),
                    params: null,
                    expr: macro return ${{expr: ifExpr, pos: curPos}},
                    args: []
                })
            }

            //trace({expr: ifExpr, pos: curPos}.toString());

            {
                pos: curPos,
                params: null,
                pack: localClass.pack,
                name: unionName,
                meta: null,
                kind: TypeDefKind.TDAbstract(macro : Dynamic, unionTypes.map(Context.toComplexType), []),
                isExtern: null,
                fields: [typeField],
                doc: null
            }
        }

        Context.defineType(unionType);
        createdUnions.set(unionUniqueName, TPath({pack: localClass.pack, name: unionName}));

        //trace(createdUnions[unionUniqueName]);

        return createdUnions[unionUniqueName];
    }
}
#end