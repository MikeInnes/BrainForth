mutable struct Tape
  count::Int
  pos::Int
  tape::Vector{UInt8}
end

Tape() = Tape(0, 1, [0])

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
inc!(t::Tape) = (t.tape[t.pos] = clip(t.tape[t.pos] + 1))
dec!(t::Tape) = (t.tape[t.pos] = clip(t.tape[t.pos] - 1))

# Gets ~0.15 GHz

function interpret(t::Tape, bf)
  loops = Int[]
  scan = 0
  ip = 1
  while ip <= length(bf)
    t.count += 1
    @inbounds op = bf[ip]
    if op == '['
      scan > 0 || t.tape[t.pos] == 0 ? (scan += 1) :
      push!(loops, ip)
    elseif op == ']'
      scan > 0 ? (scan -= 1) :
      t.tape[t.pos] == 0 ? pop!(loops) :
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

interpret(bf) = interpret(Tape(), bf)
