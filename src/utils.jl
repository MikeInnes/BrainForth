compile(path::String, bf) = open(io -> write(io, compile(bf)), path, "w")

bfrun(t::Tape, x) = interpret(t, compile(x))
bfrun(x) = bfrun(Tape(), x)

macro run(ex)
  :(bfrun(@bf($(esc(ex)))))
end

function stack(t::Tape)
  stk = similar(t.tape, 0)
  interpret(t, "[<<]")
  while get(t.tape, t.pos + 2, 0) ≠ 0
    push!(stk, t.tape[t.pos + 1])
    t.pos += 2
  end
  return stk
end

for T in [Native, Flip, Word, Quote]
  @eval a::$T == b::$T = a.code == b.code
end
