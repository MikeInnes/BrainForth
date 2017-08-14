using BrainForth: @bf, @run, stack
using Base.Test

@testset "BrainForth" begin

@test @run([8, 5, dup])  == @run([8, 5, 5])
@test @run([8, 5, swap]) == @run([5, 8])
@test @run([8, 5, drop]) == @run([8])

@test @run([0, !])     == @run([1])
@test @run([8, !])     == @run([0])
@test @run([8, 5, +])  == @run([13])
@test @run([8, 5, -])  == @run([3])
@test @run([8, 5, *])  == @run([40])

@test @run([8, 5, [1, +], dip])         == @run([9, 5])
@test @run([8, 5, nip])                 == @run([5])
@test @run([8, 5, over])                == @run([8, 5, 8])
@test @run([8, 5, [sq], keep])          == @run([8, 25, 5])
@test @run([1, 2, 3, rot])              == @run([2, 3, 1])
@test @run([8, 5, [1, +], [1, -], bi])  == @run([8, 6, 4])
@test @run([8, 5, [1, +], [1, -], bi_]) == @run([9, 4])
@test @run([8, 5, [1, +], bia])         == @run([9, 6])

@test @run([5, [[1, +], call, [1, +], call], call]) == @run([7])

@test @run([10, 1, [1, +], [1, -], iff]) == @run([11])
@test @run([10, 0, [1, +], [1, -], iff]) == @run([ 9])
@test @run([10, 1, [1, +], [1, -], pass, iff]) == @run([11])
@test @run([10, 0, [1, +], [1, -], pass, iff]) == @run([ 9])
@test @run([10, 1, [[[1, +], call], [[1, -], call], pass, iff], call]) == @run([11])

@bf factorial = [dup, 1, ==, [dup, 1, -, factorial, *], unless]
@test stack(@run([5, factorial])) == [120]

end
