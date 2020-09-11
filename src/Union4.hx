@:genericBuild(uniontypes.macro.UnionBuilder.build())
class Union4<T, T2, T3, T4> {}

@:genericBuild(uniontypes.macro.UnionBuilder.build(true))
class TrustedUnion4<T, T2, T3, T4> {}

@:genericBuild(uniontypes.macro.UnionBuilder.build(false))
class UntrustedUnion4<T, T2, T3, T4> {}