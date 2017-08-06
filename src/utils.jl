using MacroTools

macro bf(ex)
  @capture(ex, x_ = [w__]) && return :(words[$(Expr(:quote, x))] = @bf [$(esc.(w)...)])
  @capture(ex, [xs__])
  xs = [isexpr(x, :$) ? esc(x.args[1]) :
        isexpr(x, Symbol) ? Expr(:quote, x) :
        @capture(x, [w__]) ? :(Quote(@bf [$(esc.(w)...)])) :
        esc(x) for x in xs]
  :(Word([$(xs...)]))
end

macro run(ex)
  :(bfrun(@bf($(esc(ex)))))
end

function stack(t::Tape)
  stk = similar(t.tape, 0)
  bfrun(t, @bf [[step!(-2)], while!])
  while get(t.tape, t.pos + 2, 0) ≠ 0
    push!(stk, t.tape[t.pos + 1])
    t.pos += 2
  end
  return stk
end
