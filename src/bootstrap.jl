import Base: ==, @get!

macro bf(ex)
  @capture(ex, x_ = [w__]) && return :(words[$(Expr(:quote, x))] = @bf [$(esc.(w)...)])
  @capture(ex, [xs__])
  xs = [isexpr(x, :$) ? esc(x.args[1]) :
        isexpr(x, Symbol) ? Expr(:quote, x) :
        @capture(x, [w__]) ? :(Quote(@bf [$(esc.(w)...)])) :
        esc(x) for x in xs]
  :(Word([$(xs...)]))
end

struct Native
  code::String
end

struct Word
  code::Vector{Any}
end

Base.getindex(w::Word, i::AbstractArray) = Word(w.code[i])
Base.endof(w::Word) = endof(w.code)

struct Context
  icode::Vector{Any}
  cache::Dict{Symbol,Any}
end

Context() = Context([], Dict())

literal(ctx, x) = literal(x)
literal(x) = x

const cwords = Dict{Symbol,Any}()

lower(ctx, x) = x

lower_(ctx, w::Word) = Word([lower(ctx, w[1:end-1]).code..., lower(ctx, w.code[end])])

function lower(ctx, w::Word)
  w′ = Word([])
  for i = length(w.code):-1:1
    if haskey(cwords, w.code[i])
      unshift!(w′.code, cwords[w.code[i]](ctx, w[1:i]))
      return w′
    else
      unshift!(w′.code, literal(ctx, w.code[i]))
    end
  end
  return w′
end

const words = Dict{Symbol,Any}()

inline(ctx, x) = x
inline(ctx, w::Symbol) = @get!(ctx.cache, w, inline(ctx, words[w]))
inline(ctx, w::Word) = Word(inline.(ctx, lower(ctx, w).code))

function flatten(w::Word)
  w′ = Word([])
  for w in w.code
    w isa Word ? append!(w′.code, flatten(w).code) : push!(w′.code, w)
  end
  return w′
end

function compile_static(ctx, x)
  c = flatten(inline(ctx, x))
  for x in c.code
    x isa Native || error("Couldn't compile $x")
  end
  join(map(c -> c.code, c.code))
end

@bf inc!   = [Native("+")]
@bf dec!   = [Native("-")]
@bf left!  = [Native("<")]
@bf right! = [Native(">")]
@bf read!  = [Native(",")]
@bf write! = [Native(".")]
@bf debug! = [Native("#")]

struct Quote
  code::Vector{Any}
end

Quote(w::Word) = Quote(w.code)
Word(q::Quote) = Word(q.code)

struct Flip
  code::Any
end

flip(x) = Flip(x)
flip(x::Flip) = x.code
flip(w::Native) = w.code == ">" ? Native("<") : w.code == "<" ? Native(">") : w

lower(ctx, w::Flip) = Flip(lower(ctx, w.code))
inline(ctx, w::Flip) = Word(flip.(flatten(inline(ctx, w.code)).code))

cwords[:while!] = function (ctx, w::Word)
  if length(w.code) >= 2 && w.code[end-1] isa Quote
    lower(ctx, Word([w[1:end-2], Native("["), Word(w.code[end-1].code), Native("]")]))
  else
    lower_(ctx, w)
  end
end

repeated(w, i) = Word([w for _ = 1:i])

step!(n) = repeated(n > 0 ? :right! : :left!, abs(n))

@bf pass = []

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

@bf drop = [dec!, left!, reset!, left!]

if!(t, f) = @bf [left!, [right!, $t, dec!], while!, right!,
                 [$f, dec!, right!], while!,
                 left!, inc!]

cwords[:if!] = function (ctx, w::Word)
  length(w.code) ≥ 3 && w.code[end-1] isa Quote && w.code[end-2] isa Quote ||
    return lower_(ctx, w)
  t, f = map(i -> @bf([drop, Word(w.code[end-i]), 0]), (2, 1))
  lower(ctx, @bf [w[1:end-3], if!(t, f), drop])
end

function bytecode(ctx::Context, code)
  n = findfirst(ctx.icode, code)
  n == 0 && (push!(ctx.icode, code); n = length(ctx.icode))
  return n
end

literal(ctx, w::Quote) = literal(bytecode(ctx, Word(w)))

struct Call end

words[:call] = Call()

function partition(w::Word)
  w′ = Word([])
  cur = Word([])
  for w in w.code
    if w == Call()
      push!(cur.code, :rpush)
      push!(w′.code, cur)
      cur = Word([])
    else
      push!(cur.code, w)
    end
  end
  !isempty(cur.code) && push!(w′.code, cur)
  return w′
end

function compile_dynamic(ctx::Context, w::Word)
  bytecode(ctx, w)
  is, i = [], 1
  while i ≤ length(ctx.icode)
    q = ctx.icode[i]
    q = partition(flatten(inline(ctx, q)))
    code = if q isa Word && length(q.code) > 1
      Word(reverse([bytecode(ctx, w) for w in q.code]))
    else
      Flip(@bf [stack!, $q, rstack!])
    end
    push!(is, @bf [1, -, if!(:pass, @bf [drop, $code, 0])])
    i += 1
  end
  interp = @bf [[is..., drop], while!, rstack!]
  compile_static(ctx, @bf [1, stackswitch!, Flip(interp)])
end

function compile(w::Word)
  compile_dynamic(Context(), w)
end
