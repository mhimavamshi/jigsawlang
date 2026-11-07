# JigSaw Language

## What is it?
This is just a fun hobby project to learn basic stuff by implementing a simple language and making upgrades for it.

The language is made of:
- Function Definitions
- Entry point for an expression to evaluate

An expression is a composition of functions which have arguments.

Arguments are values or other outputs of other functions. 

First version would only include untyped values. 

Types will be added after that's built (hopefully). Types would be really cool though.

Functions are either user defined or provided by runtime. 
User defined functions can override runtime ones, though we can add a warning.

There are no named variables except the parameters which will act as placeholders for substitution in function definition, for now.

Functions can have any number of arguments defined in the signature. For the basic version there are no default arguments and argument values in a call are mapped by positions to parameter names. 

Implicit return statement as expressions are just function compositions.

Normal function calls' arguments are evaluated eagerly from left to right, and are returned in that order, and after they're done their values are passed as arguments.

Branching is a special runtime defined function. Takes 2 other functions (or value) and a condition (function or value) and evaluates one of them based on the value of condition, which is evaluated first. 

Functions can ask for data during runtime. 

Recursion is allowed by repeated function calls inside bodies including the same function, but no imperative loops.

There's a REPL. And you can update function definitions there.

I am thinking of hot reload of functions during an execution of a program also. But that's also after the basic stuff is built. 

## Syntax and Meaning

- Function Definition:
```
` this is a comment `

functionname (args) {
 expression ` is evaluated and implicitly returned `
}
```
- Expressions:
```
` this is a comment `

` simplest is runtime defined function with values `
add(4, 5)

` or compose them `
print(add(4, 5))

` or more expressions (assume ifelse is branch function, which is unique in evaluation order - condition is evaluated first!) `
print(ifelse("that's wrong...", add(1, 2), isgreater(askuser("enter number greater than 5: "), 5)))

` probably a nice formatter would help...`

```
- Entry point
```
` this is a comment `

` all programs must have main function which is evaluated first`

main() {
    print("main!)
}

```

