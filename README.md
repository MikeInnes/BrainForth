# BrainForth

```julia
] add https://github.com/MikeInnes/BrainForth
```

Brainforth is a small Forth-like language which compiles to brainfuck. This implementation has a brainfuck interpreter and a small Julia kernel for bootstrapping, then implements the stack abstraction and standard library functions in brainforth itself.

```julia
julia> using BrainForth: @bf, @run

# Interpret a string
julia> BrainForth.interpret("++>+++>")
[7] 2 3 0*

# Compile code
julia> BrainForth.compile(@bf [3, 4, +])
">+++>+>++++>+-<[-<<+>>]<"

# Run code directly
julia> @run [3, 4, +]
[45] 7 1*

# Define a recursive function
julia> @bf factorial = [dup, 1, ==, [dup, 1, -, factorial, *], unless];

julia> @run [5, factorial]
[69372] 120 1*

# Map over a list
julia> @run [5, iota, [dup, *], map]
[1910094] 25 1 16 1 9 1 4 1 1 1 5 1*

# I/O
julia> @run [readln, reverse, println]
hello world
dlrow olleh
[30419408] 0*
```

See the [blog post](http://mikeinnes.github.io/2017/09/13/brainforth.html) for more.
