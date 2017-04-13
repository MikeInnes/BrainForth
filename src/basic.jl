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

compile(io::IO, nat::BFNative) = print(io, nat.code)

compile(io::IO, f::Flip) =
  print(io, map(c -> c == '<' ? '>' : c == '>' ? '<' : c, compile(f.code)))

compilers = Dict{Any,Any}()

function compile(io::IO, w::Word)
  isempty(w.code) && return
  haskey(compilers, w.code[end]) && return compilers[w.code[end]](io, w)
  compile(io, Word(w.code[1:end-1]))
  compile(io, w.code[end])
end

words = Dict{Symbol,Any}()

compile(io::IO, s::Symbol) = compile(io, words[s])

function compile(x)
  buf = IOBuffer()
  compile(buf, x)
  takebuf_string(buf)
end

bfrun(x) = interpret(compile(x))

compilers[:while!] = function (io::IO, w::Word)
  if length(w.code) >= 2 && w.code[end-1] isa Quote
    compile(io, Word([w[1:end-2], BFNative("["), Word(w.code[end-1].code), BFNative("]")]))
  else
    error("while! loop must be a compile-time quote")
  end
end

iff(t, f) = @bf [left!, [right!, $t, dec!], while!, right!,
                 [$f, dec!, right!], while!,
                 left!, inc!]

@bf inc!   = [BFNative("+")]
@bf dec!   = [BFNative("-")]
@bf left!  = [BFNative("<")]
@bf right! = [BFNative(">")]

repeated(w, i) = Word([w for _ = 1:i])

compile(io::IO, i::Int) = compile(io, @bf [right!, repeated(:inc!, i), right!, inc!])

step!(n) = repeated(n > 0 ? :right! : :left!, abs(n))

@bf stack! = [[step!(2)], while!, step!(2), [step!(2)], while!, step!(-2)]
@bf rstack! = [Flip(:stack!)]

@bf stackswitch! = [dec!, left!,
                    [dec!, left!, rstack!, left!, inc!, right!, stack!, right!], while!,
                    left!, rstack!, left!, left!, inc!]

@bf rpush = [stackswitch!, stack!]
@bf rpop = [rstack!, Flip(:stackswitch!)]

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

@bf drop = [dec!, left!, reset!, left!]

@bf ! = [left!, [right!, dec!, left!, reset!], while!, # Set flag, reset
         right!, [left!, inc!, right!, dec!], while!, inc!]

@bf + = [dec!, left!, move!(-2), left!]
@bf - = [dec!, left!, move!(-2, mode = :dec!), left!]

@bf * = [dec!, step!(-2), dec!, left!, move!(1), right!,
         [dec!, right!, move!(1, -2), right!, move!(-1), step!(-2)], while!,
         right!, reset!, left!, inc!]

@bf != = [-]
@bf == = [-, !]

@bf sq = [dup, *]

# @bf factorial = [0, ==, [1], [dup, 1, -, factorial, *], iff]

bfrun(@bf [8, dup, sq, swap, -])
