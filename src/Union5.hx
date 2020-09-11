@:genericBuild(uniontypes.macro.UnionBuilder.build())
class Union5<T, T2, T3, T4, T5> {}

@:genericBuild(uniontypes.macro.UnionBuilder.build(true))
class TrustedUnion5<T, T2, T3, T4, T5> {}

@:genericBuild(uniontypes.macro.UnionBuilder.build(false))
class UntrustedUnion5<T, T2, T3, T4, T5> {}