using MacroTools

struct BFNative
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

macro bf(ex)
  @capture(ex, x_ = [w__]) && return :(words[$(Expr(:quote, x))] = @bf [$(esc.(w)...)])
  @capture(ex, [xs__])
  xs = [isexpr(x, :$) ? esc(x.args[1]) :
        isexpr(x, Symbol) ? Expr(:quote, x) :
        @capture(x, [w__]) ? :(Quote(@bf [$(esc.(w)...)])) :
        esc(x) for x in xs]
  :(Word([$(xs...)]))
end

struct Context{IO}
  io::IO
  quotes::Vector{Quote}
end

Context(io::IO) = Context(io, Quote[])
Context() = Context(IOBuffer())

compile(ctx::Context, nat::BFNative) = print(ctx.io, nat.code)

compile(ctx::Context, f::Flip) =
  print(ctx.io, map(c -> c == '<' ? '>' : c == '>' ? '<' : c, compile(f.code)))

compilers = Dict{Any,Any}()

function compile(ctx::Context, w::Word)
  isempty(w.code) && return
  haskey(compilers, w.code[end]) && return compilers[w.code[end]](ctx, w)
  compile(ctx, Word(w.code[1:end-1]))
  compile(ctx, w.code[end])
end

function compile(ctx::Context, q::Quote)
  push!(ctx.quotes, q)
  compile(ctx, length(ctx.quotes))
end

words = Dict{Symbol,Any}()

compile(ctx::Context, s::Symbol) = compile(ctx, words[s])

function compile(x)
  ctx = Context()
  compile(ctx, x)
  takebuf_string(ctx.io)
end

bfrun(x) = interpret(compile(x))

@bf inc!   = [BFNative("+")]
@bf dec!   = [BFNative("-")]
@bf left!  = [BFNative("<")]
@bf right! = [BFNative(">")]
@bf bug!   = [BFNative("!")]

compilers[:while!] = function (ctx::Context, w::Word)
  if length(w.code) >= 2 && w.code[end-1] isa Quote
    compile(ctx, Word([w[1:end-2], BFNative("["), Word(w.code[end-1].code), BFNative("]")]))
  else
    error("while! loop must be a compile-time quote")
  end
end

repeated(w, i) = Word([w for _ = 1:i])

compile(ctx::Context, i::Int) = compile(ctx, @bf [right!, repeated(:inc!, i), right!, inc!])

step!(n) = repeated(n > 0 ? :right! : :left!, abs(n))

@bf stack! = [[step!(2)], while!, step!(2), [step!(2)], while!, step!(-2)]
@bf rstack! = [Flip(:stack!)]

@bf stackswitch! = [dec!, left!,
                    [dec!, left!, rstack!, left!, inc!, right!, stack!, right!], while!,
                    left!, rstack!, left!, left!, inc!]

@bf rpush = [stackswitch!, stack!]
@bf rpop = [rstack!, Flip(:stackswitch!)]

iff(t, f) = @bf [left!, [right!, $t, dec!], while!, right!,
                 [$f, dec!, right!], while!,
                 left!, inc!]

compilers[:iff] = function (ctx::Context, w::Word)
  length(w.code) ≥ 3 && w.code[end-1] isa Quote && w.code[end-2] isa Quote ||
    return compile_(ctx, w)
  compile(ctx, w[1:end-3])
  t, f = map(i -> @bf([drop, Word(w.code[end-i].code), 0]), (2, 1))
  compile(ctx, @bf [iff(t, f), drop])
end

compilers[:interp!] = function (ctx::Context, w::Word)
  compile(ctx, w[1:end-1])
  is = map(ctx.quotes) do q
    code = @bf [stack!, q.code..., rstack!]
    code = @bf [drop, Flip(code), 0]
    @bf [1, -, iff(Word([]), code)]
  end
  compile(ctx, Flip(@bf [[is..., drop], while!, rstack!]))
end

@bf reset! = [[dec!], while!]

function move!(locs...; mode = :inc!)
  @assert !any(x -> x == 0, locs)
  step = Word([@bf [step!(l), $mode, step!(-l)] for l in locs])
  @bf [[dec!, $step], while!]
end

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

@bf ! = [left!, [right!, dec!, left!, reset!], while!, # Set flag, reset
         right!, [left!, inc!, right!, dec!], while!, inc!]

@bf + = [dec!, left!, move!(-2), left!]
@bf - = [dec!, left!, move!(-2, mode = :dec!), left!]

@bf * = [dec!, step!(-2), dec!, left!, move!(1), right!,
         [dec!, right!, move!(1, -2), right!, move!(-1), step!(-2)], while!,
         right!, reset!, left!, inc!]

# End of macros

@bf call = [stackswitch!, interp!]

@bf != = [-]
@bf == = [-, !]
@bf sq = [dup, *]

@bf dip = [swap, rpush, [rpop], rpush, call]
@bf iff = [pick, [drop, call], [swap, drop, call], iff]

# @bf factorial = [0, ==, [1], [dup, 1, -, factorial, *], iff]

# bfrun(@bf [8, [dup, *], [6, +], drop, call])
# bfrun(@bf [8, [dup, *], [6, +], swap, drop, call])

bfrun(@bf [8, 5, [dup, *, bug!], dip])
