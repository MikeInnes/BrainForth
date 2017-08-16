using BrainForth: @bf

cd(@__DIR__)

# --
@bf intro = ["The Guessing Game: Guess a number from 0-255!", println]

# -- name
@bf getname = [["Enter your name: ", prompt], whileempty]
# -- n
@bf getnum = [["Enter your guess: ", prompt], whileempty, parseint]
# --
@bf greeting = ["Hello, ", print, print, "!", println]

# Lacking an RNG, we come up with a number based on the user's name.
# s -- s n
@bf roll = [[1, +], map, dupv, prod]

# n --
@bf game = [[dup, getnum, tuck, !=],
            [dupd, <, ["Too high!"], ["Too low!"], iff, println],
            loop, drop, drop,
            "Correct!", println]

@bf main = [intro, getname, dupv, greeting,
            [1], [roll, game, "", println], loop]

BrainForth.compile("guessing.bf", @bf [[main], call])
