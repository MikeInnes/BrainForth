using BrainForth: @bf, @run

@bf promptr = [["Enter your name: ", prompt], whileempty]
@bf greeting = ["Hello, ", print, print, "!", println]

@bf main = [promptr, dupv, greeting,
            "Here's your name in reverse: ", print,
            reverse, println]

@run [main]
