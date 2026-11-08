-- entry point for everything jigsaw

local tokenizer = require("tokenizer")
local parser = require("parser")

function repl()
    print("REPL")
end

function getFileNames(args) 
    local files = {}
    for i = 2, #args do 
        if args[i]:sub(-3) == ".jg" then 
            table.insert(files, arg[i])
        end
    end
    return files
end  

function run(args)
    local files = getFileNames(args)
    for i = 1, #files do
        local tokens = tokenizer.tokenizeFile(files[i])
        if tokens.stream ~= nil then
            tokens:print()
            local parsed = parser.parse(tokens)
            if parsed ~= nil then 
                parsed:print()
                parsed:populateBytecode()
            end
        end

    end
end



function help() 
return [[
Usage: jigsaw.lua <mode> [args] 
where modes are:
    -repl: enter REPL mode in CLI
    -run: run the provided .jg files in args
]]
end

if #arg == 0 then 
    print(help())
    os.exit(1)
end

if arg[1]:sub(1, 1) ~= "-" then
    print(help())
    os.exit(1)
end 

local mode = arg[1]:sub(2)
print("in mode:", mode)

if mode == "repl" then 
    repl()
elseif mode == "run" then
    run(arg)
else
    print(help())
    os.exit(1)
end




