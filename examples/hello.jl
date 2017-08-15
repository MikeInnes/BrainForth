using BrainForth: @bf

cd(@__DIR__)

@bf promptr = [["Enter your name: ", prompt], whileempty]
@bf greeting = ["Hello, ", cat, '!', pushe]

@bf main = [promptr, dupv, greeting, println,
            "Here's your name in reverse: ", print,
            reverse, println]

BrainForth.compile("hello.bf", @bf [[main], call])
