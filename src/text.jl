@bf read = [right!, read!, right!, inc!]
@bf write = [left!, write!, right!, drop]

@bf print = [[write], each]
@bf println = ['\n', pushe, print]

@bf readln_ = [nil, [head, '\n', !=], [read, push], doloop]
@bf readln = [readln_, reverse]
