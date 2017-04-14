using MacroTools

struct Native
  code::String
end

struct Flip
  code::Any
end

struct Word
  code::Vector{Any}
end

Base.getindex(w::Word, i::AbstractArray) = Word(w.code[i])
Base.endof(w::Word) = endof(w.code)

struct Quote
  code::Vector{Any}
end

Quote(w::Word) = Quote(w.code)

const words = Dict{Symbol,Any}()

macro bf(ex)
  @capture(ex, x_ = [w__]) && return :(words[$(Expr(:quote, x))] = @bf [$(esc.(w)...)])
  @capture(ex, [xs__])
  xs = [isexpr(x, :$) ? esc(x.args[1]) :
        isexpr(x, Symbol) ? Expr(:quote, x) :
        @capture(x, [w__]) ? :(Quote(@bf [$(esc.(w)...)])) :
        esc(x) for x in xs]
  :(Word([$(xs...)]))
end

const lowers = Dict{Symbol,Any}()

lower(x) = x

lower_(w::Word) = Word([lower(w[1:end-1]).code..., lower(w.code[end])])

lower(w::Word) =
  isempty(w.code) ? w :
  haskey(lowers, w.code[end]) ? lowers[w.code[end]](w) :
    lower_(w)

lower(w::Symbol) = lower(words[w])

function flatten(w::Word)
  w′ = Word([])
  for w in w.code
    w isa Word ? append!(w′.code, flatten(w).code) : push!(w′.code, w)
  end
  return w′
end

struct Context{IO}
  io::IO
  quotes::Vector{Quote}
end

Context(io::IO) = Context(io, Quote[])
Context() = Context(IOBuffer())

const compiles = Dict{Symbol,Any}()

compile(ctx::Context, nat::Native) = print(ctx.io, nat.code)

compile(ctx::Context, f::Flip) =
  print(ctx.io, map(c -> c == '<' ? '>' : c == '>' ? '<' : c, compile(f.code)))

function compile(ctx::Context, w::Word)
  isempty(w.code) && return
  haskey(compiles, w.code[end]) && return compiles[w.code[end]](ctx, w)
  for w in w.code
    compile(ctx, w)
  end
end

function compile(ctx::Context, q::Quote)
  push!(ctx.quotes, q)
  compile(ctx, lower(length(ctx.quotes)))
end

function compile(x)
  ctx = Context()
  compile(ctx, lower(x))
  takebuf_string(ctx.io)
end

bfrun(x) = interpret(compile(x))

@bf inc!   = [Native("+")]
@bf dec!   = [Native("-")]
@bf left!  = [Native("<")]
@bf right! = [Native(">")]
@bf debug! = [Native("#")]

lowers[:while!] = function (w::Word)
  if length(w.code) >= 2 && w.code[end-1] isa Quote
    lower(Word([w[1:end-2], Native("["), Word(w.code[end-1].code), Native("]")]))
  else
    lower_(w)
  end
end

repeated(w, i) = Word([w for _ = 1:i])

lower(i::Int) = lower(@bf [right!, repeated(:inc!, i), right!, inc!])

step!(n) = repeated(n > 0 ? :right! : :left!, abs(n))

@bf stack! = [[step!(2)], while!, step!(2), [step!(2)], while!, step!(-2)]
@bf rstack! = [Flip(:stack!)]

@bf stackswitch! = [dec!, left!,
                    [dec!, left!, rstack!, left!, inc!, right!, stack!, right!], while!,
                    left!, rstack!, left!, left!, inc!]

@bf rpush = [stackswitch!, stack!]
@bf rpop = [rstack!, Flip(:stackswitch!)]

function move!(locs...; mode = :inc!)
  @assert !any(x -> x == 0, locs)
  step = Word([@bf [step!(l), $mode, step!(-l)] for l in locs])
  @bf [[dec!, $step], while!]
end

@bf reset! = [[dec!], while!]

@bf dup = [dec!, step!(-1), move!(1),
           step!(1), move!(-1, 1), inc!,
           step!(2), inc!]

@bf swap = [step!(-2), dec!, step!(-1), move!(1),
            step!(2), move!(-2),
            step!(-1), move!(1), inc!, step!(2)]

@bf over = [dec!, step!(-3), move!(3),
            step!(3), move!(-3, 1), inc!, step!(2), inc!]

@bf pick = [dec!, step!(-5), move!(5),
            step!(5), move!(-5, 1), inc!, step!(2), inc!]

@bf drop = [dec!, left!, reset!, left!]

iff(t, f) = @bf [left!, [right!, $t, dec!], while!, right!,
                 [$f, dec!, right!], while!,
                 left!, inc!]

lowers[:iff] = function (w::Word)
  length(w.code) ≥ 3 && w.code[end-1] isa Quote && w.code[end-2] isa Quote ||
    return lower_(w)
  t, f = map(i -> @bf([drop, Word(w.code[end-i].code), 0]), (2, 1))
  lower(@bf [w[1:end-3], iff(t, f), drop])
end

lowers[:interp!] = w -> @bf [lower(w[1:end-1]), interp!]

compiles[:interp!] = function (ctx::Context, w::Word)
  compile(ctx, w[1:end-1])
  is = map(ctx.quotes) do q
    code = @bf [stack!, q.code..., rstack!]
    code = @bf [drop, Flip(code), 0]
    @bf [1, -, iff(Word([]), code)]
  end
  compile(ctx, lower(Flip(@bf [[is..., drop], while!, rstack!])))
end

@bf call = [stackswitch!, interp!]

@bf ! = [left!, [right!, dec!, left!, reset!], while!, # Set flag, reset
         right!, [left!, inc!, right!, dec!], while!, inc!]

@bf + = [dec!, left!, move!(-2), left!]
@bf - = [dec!, left!, move!(-2, mode = :dec!), left!]

@bf * = [dec!, step!(-2), dec!, left!, move!(1), right!,
         [dec!, right!, move!(1, -2), right!, move!(-1), step!(-2)], while!,
         right!, reset!, left!, inc!]

# End of bootstrap

@bf != = [-]
@bf == = [-, !]
@bf sq = [dup, *]

@bf dip = [swap, rpush, [rpop], rpush, call]
@bf iff = [pick, [drop, call], [swap, drop, call], iff]

# @bf factorial = [0, ==, [1], [dup, 1, -, factorial, *], iff]

bfrun(@bf [1, [10], [5], iff])
bfrun(@bf [8, [dup, *], [6, +], drop, call])
bfrun(@bf [8, [dup, *], [6, +], swap, drop, call])
