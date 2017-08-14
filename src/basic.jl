@bf ! = [left!, [right!, dec!, left!, reset!], while!, # Set flag, reset
         right!, [left!, inc!, right!, dec!], while!, inc!]

@bf + = [dec!, left!, move!(-2), left!]
@bf - = [dec!, left!, move!(-2, mode = :dec!), left!]

@bf * = [dec!, step!(-2), dec!, left!, move!(1), right!,
         [dec!, right!, move!(1, -2), right!, move!(-1), step!(-2)], while!,
         right!, reset!, left!, inc!]

# End of unsafe operations

@bf != = [-]
@bf == = [-, !]
@bf or = [+]
@bf and = [*]
@bf sq = [dup, *]

@bf dip = [swap, rpush, [rpop], rpush, call]

@bf nip = [swap, drop]
@bf over = [[dup], dip, swap]
@bf keep = [over, [call], dip]
@bf rot = [[swap], dip, swap]

@bf bi = [[keep], dip, call]
@bf bi_ = [[dip], dip, call] # bi*
@bf bia = [dup, bi_] # bi@

@bf iff = [rot, [], [swap], iff, drop, call]
@bf when = [[], iff]
@bf unless = [[], swap, iff]
