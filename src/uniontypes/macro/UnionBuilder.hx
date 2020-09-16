package uniontypes.macro;

#if macro
import haxe.macro.Expr;
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

    static function typeName(t : Type) {
        final name = switch t {
            case TInst(t, _): t.get().name;
            case TAbstract(t, _): t.get().name;
            case TType(t, _): t.get().name;
            case TEnum(t, _): t.get().name;
            case TAnonymous(_):
                Context.error(
                    'Cannot use an anynomous type directly, name it with a typedef.', 
                    Context.currentPos()
                );
            case t: 
                Context.error('Unsupported Union type: $t', Context.currentPos());
        }
        //trace(name);
        return name;
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

        // Sort types to make them commutative and to reduce type checking
        // (anonymous types is a more time-consuming check)

        function actualType(a : Type, followed = false) return switch a {
            case TType(t, _): actualType(Context.followWithAbstracts(a));
            case TAbstract(t, _) if(!followed): actualType(Context.followWithAbstracts(a), true);
            case _: a;
        }

        function sortTypes(a : Type, b : Type) : Int {
            return switch actualType(a) {
                case TAnonymous(_): 
                    switch actualType(b) {
                        case TAnonymous(_): 
                            // If both are anonymous, just compare names.
                            typeName(a) > typeName(b) ? 1 : -1;
                        case _:
                            1;
                    }
                case _: switch actualType(b) {
                    case TAnonymous(_): 
                        -1;
                    case _:
                        typeName(a) > typeName(b) ? 1 : -1;
                }
            }
        }

        unionTypes.sort(sortTypes);

        final unionName = (if(trusted == null) '' else (trusted ? 'Trusted' : 'Untrusted')) + 
            unionTypes.map(typeName).join('Or');

        final sortedUnionTypes = [for(t in unionTypes) Std.string(t)];
        sortedUnionTypes.sort((a, b) -> a > b ? 1 : -1);

        final unionUniqueName = unionName + "<" + sortedUnionTypes.join(',') + ">";
        
        //trace(unionUniqueName);

        // Check cache
        if(createdUnions.exists(unionUniqueName)) {
            //trace("===== Found above type in cache =====");
            return createdUnions[unionUniqueName];
        }

        // Sort Int before Float to avoid casting issues
        {
            final float = unionTypes.find(f -> switch actualType(f) {
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

                //trace('== $t');

                function generateIf(t, followed = false) : Expr return switch t {
                    case TInst(t, _):
                        final inst = t.get();
                        final typeToCheck = toDotPath(inst, inst.name);
                        macro Std.isOfType(this, $p{typeToCheck.split('.')});
                    case TAbstract(t, _): 
                        final inst = t.get();
                        if(followed) {
                            final typeToCheck = toDotPath(inst, inst.name);
                            macro Std.isOfType(this, $p{typeToCheck.split('.')});
                        } else {
                            generateIf(Context.followWithAbstracts(inst.type), true);
                        }                            
                    case TType(t, _): 
                        generateIf(Context.followWithAbstracts(t.get().type));
                    case TEnum(t, _): 
                        final inst = t.get();
                        final typeToCheck = toDotPath(inst, inst.name);
                        macro Std.isOfType(this, $p{typeToCheck.split('.')});
                    case TAnonymous(a):
                        // Check all non-optional fields
                        final fields = a.get().fields.filter(f -> !f.meta.has(":optional")).map(f -> {
                            expr: EConst(CString(f.name)), pos: curPos
                        });
                        macro Type.typeof(this).equals(TObject) && 
                            !Lambda.exists($a{fields}, f -> !Reflect.hasField(this, f));
                    case _:
                        Context.error('Unsupported Union type: $t', curPos);
                }

                final ifExpression = generateIf(t);

                return if(it.hasNext()) EIf(
                    ifExpression, 
                    {expr: enumValue, pos: curPos}, 
                    {expr: ifExpr(it), pos: curPos}
                ) else if(checkUnknownType) EIf(
                    ifExpression,
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