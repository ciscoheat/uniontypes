@:genericBuild(uniontypes.macro.UnionBuilder.build())
class Union3<T, T2, T3> {}

@:genericBuild(uniontypes.macro.UnionBuilder.build(true))
class TrustedUnion3<T, T2, T3> {}

@:genericBuild(uniontypes.macro.UnionBuilder.build(false))
class UntrustedUnion3<T, T2, T3> {}