@bf read = [right!, read!, right!, inc!]
@bf write = [left!, write!, right!, drop]

@bf print = [[write], eachr]
@bf println = [print, '\n', write]

@bf readln = [nil, [head, '\n', !=], [read, push], doloop, pop, drop]

@bf panic = ["PANIC: ", print, println, halt]

@bf prompt = [print, readln]

@bf whileempty_ = [[isempty], dip, swap,
                   [[drop], dip, [call], keep, whileempty_], [drop], iff]
@bf whileempty = [nil, swap, whileempty_]

# Printing
@bf charstr = ['\'', swap, '\'', 3]

# Parsing
@bf isdigit = [['0', >=], ['9', <=], bi, and]
@bf digiterr = [charstr, " is not a digit", cat]
@bf assertdigit = [dup, isdigit, [digiterr, panic], unless]
@bf toint = [assertdigit, '0', -]
@bf parseint = [reverse, 0, [[toint], [10, *], bi_, +], fold]
