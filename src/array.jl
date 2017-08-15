lower(c::Char) = lower(Int(c))
lower(s::String) = lower(Word([reverse(s)..., length(s)]))

# Basic array ops

@bf nil = [0]
@bf push = [swap, 1, +]
@bf pop = [1, -, swap]
@bf head = [over]
@bf length = [dup]
@bf isempty = [length, !]

# Array-stack ops

@bf pushe = [[isempty], dip, swap,
             [nip, 1], [[pop], dip, swap, [pushe], dip, push], iff]

@bf swapvb = [pushe, 1, -]

@bf dropv = [isempty, [drop], [pop, drop, dropv], iff]

@bf dipv = [[isempty], dip, swap,
            [dip], [[pop], dip, swap, [dipv], dip, push], iff]

@bf swapvv_ = [isempty, [drop], [pop, [swapvv_], dip, swapvb], iff]
@bf swapvv = [[swapvv_], keep, swapvb]

@bf dupv = [isempty, [dup],
            [pop, [dupv], dip, # xs, ys, x
             [swapvb, [push], dipv], keep, # xs:x, ys, x
             push], # xs:x, ys:y
            iff]

@bf keepv = [[dupv], dip, dipv]

# Array lib

@bf iota = [[[dup, 1, !=], [dup, 1, -], loop], keep]

@bf cat = [isempty, [drop], [pop, [cat], dip, push], iff]

@bf reverse = [isempty, [pop, [reverse], dip, pushe], unless]

@bf each = [[isempty], dip, swap,
            [drop, drop], [[pop], dip, [call], keep, each], iff]

@bf map_ = [[pop], dip, tuck, call, [map], dip, push]
@bf map = [[isempty], dip, swap,
           [drop], [map_], iff]

@bf fold_ = [[pop], dip2, [call], keep, fold]
@bf fold = [[isempty], dip2, rotl,
            [drop, nip], [fold_], iff]


@bf sum = [0, [+], fold]
@bf prod = [1, [*], fold]
