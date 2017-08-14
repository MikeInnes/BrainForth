using BrainForth: @bf, @run, stack
using Base.Test

@testset "BrainForth" begin

@test stack(@run([8, 5, dup]))  == [8, 5, 5]
@test stack(@run([8, 5, swap])) == [5, 8]
@test stack(@run([8, 5, drop])) == [8]

@test stack(@run([0, !]))     == [1]
@test stack(@run([8, !]))     == [0]
@test stack(@run([8, 5, +]))  == [13]
@test stack(@run([8, 5, -]))  == [3]
@test stack(@run([8, 5, *]))  == [40]

@test stack(@run([8, 5, [1, +], dip]))         == [9, 5]
@test stack(@run([8, 5, nip]))                 == [5]
@test stack(@run([8, 5, over]))                == [8, 5, 8]
@test stack(@run([8, 5, [sq], keep]))          == [8, 25, 5]
@test stack(@run([1, 2, 3, rot]))              == [2, 3, 1]
@test stack(@run([8, 5, [1, +], [1, -], bi]))  == [8, 6, 4]
@test stack(@run([8, 5, [1, +], [1, -], bi_])) == [9, 4]
@test stack(@run([8, 5, [1, +], bia]))         == [9, 6]

@test stack(@run([5, [[1, +], call, [1, +], call], call])) == [7]

@test stack(@run([10, 1, [1, +], [1, -], iff])) == [11]
@test stack(@run([10, 0, [1, +], [1, -], iff])) == [ 9]
@test stack(@run([10, 1, [1, +], [1, -], pass, iff])) == [11]
@test stack(@run([10, 0, [1, +], [1, -], pass, iff])) == [ 9]
# TODO: fix the inlined version of `iff` to allow this
@test stack(@run([10, 1, [[[1, +], call], [[1, -], call], pass, iff], call])) == [11]

@bf factorial = [dup, 1, ==, [dup, 1, -, factorial, *], unless]
@test stack(@run([5, factorial])) == [120]

@bf fib = [dup, [1, ==], [0, ==], bi, or,
                [[1, -, fib], [2, -, fib], bi, +], unless]

@test stack(@run([7, fib])) == [13]

end
