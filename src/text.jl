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
