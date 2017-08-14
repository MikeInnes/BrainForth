mutable struct Tape
  count::Int
  pos::Int
  tape::Vector{UInt8}
end

Tape() = Tape(0, 1, [0])

Base.getindex(t::Tape) = t.tape[t.pos]
Base.setindex!(t::Tape, v) = t.tape[t.pos] = v

function Base.show(io::IO, t::Tape)
  print(io, "[$(t.count)] ")
  for i = 1:length(t.tape)
    print(io, t.tape[i], i == t.pos ? "* " : " ")
  end
end

Base.:(==)(a::Tape, b::Tape) = a.tape == b.tape

function left!(t::Tape)
  t.pos == length(t.tape) && t.tape[end] == 0 && pop!(t.tape)
  t.pos == 1 ? unshift!(t.tape, 0) : (t.pos -= 1)
  return
end

function right!(t::Tape)
  t.pos == 1 && t.tape[1] == 0 && (shift!(t.tape); t.pos -= 1)
  t.pos == length(t.tape) && push!(t.tape, 0)
  t.pos += 1
  return
end

clip(n) = n > 255 ? n - 256 : n < 0 ? n + 256 : n
inc!(t::Tape) = (t[] = clip(t[] + 1))
dec!(t::Tape) = (t[] = clip(t[] - 1))

# Gets ~370 MHz

function interpret(t::Tape, bf)
  loops = Int[]
  scan = 0
  ip = 1
  @inbounds while ip <= length(bf)
    t.count += 1
    op = bf[ip]
    if op == '['
      scan > 0 || t[] == 0 ? (scan += 1) :
      push!(loops, ip)
    elseif op == ']'
      scan > 0 ? (scan -= 1) :
      t[] == 0 ? pop!(loops) :
      (ip = loops[end])
    elseif scan == 0
      op == '+' ? inc!(t) :
      op == '-' ? dec!(t) :
      op == '<' ? left!(t) :
      op == '>' ? right!(t) :
      op == '#' ? println(t) :
        nothing
    end
    ip += 1
  end
  return t
end

interpret(t::Tape, bf::String) = interpret(t, collect(bf))

interpret(bf) = interpret(Tape(), bf)
