@bf nil = [0]
@bf push = [swap, 1, +]
@bf pop = [1, -, swap]
@bf head = [over]
@bf isempty = [dup, !]

@bf range = [[[dup, 1, !=], [dup, 1, -], loop], keep]

@bf map_ = [[pop], dip, tuck, call, [map], dip, push]
@bf map = [[isempty], dip, swap,
           [drop], [map_], iff]

@bf fold_ = [[pop], dip2, [call], keep, fold]
@bf fold = [[isempty], dip2, rotl,
            [drop, nip], [fold_], iff]

@bf pushe = [[isempty], dip, swap,
             [nip, 1], [[pop], dip, swap, [pushe], dip, push], iff]

@bf reverse = [isempty, [pop, [reverse], dip, pushe], unless]

@bf sum = [0, [+], fold]
@bf prod = [1, [*], fold]
