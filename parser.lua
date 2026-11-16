-- probably not the best parser but well it works and good enough

-- 2 kinds of "blocks" in the language
-- function call = name(args ...)
-- function declaration = name(args ...) { function call }
-- common prefix and then after determining its one or the other we need to verify retroactively and error
-- actually realised function declaration can have attached `function` to disambiguate lol but its feels like a fun parser so im keeping

-- idea is this:
-- parse the common prefix properly
-- let the { } classify and then pass that classificiation to a verifier along with the tree
-- let the verifier pass or error
-- then continue with the right parser recursively

local parser = {}
local parserMethods = {}
parserMethods.__index = parserMethods

local function printParserError(message, subs)
    local errormessage = string.gsub(message, "%w+", subs)
    print("Parser Error:", errormessage)
end

-- gathers all top-level declarations, standalone calls, identifiers into a list, and additional fields
function parserMethods:generateMetadata()
    local metadata = {declarations = {}, calls = {}, identifiers = {}}
    for i, node in ipairs(self.tree) do
        if node.type == "declaration" then 
            table.insert(metadata.declarations, node)
        end
        if node.type == "call" then 
            table.insert(metadata.calls, node)
        end
        if node.type == "identifier" then 
            table.insert(metadata.identifiers, node)
        end
    end    
    self.metadata = metadata
end

local function printNode(node, prefix, isLast)
    prefix = prefix or ""
    local connector = isLast and "└── " or "├── "

    if node.type == "identifier" or node.type == "integer" or node.type == "string" or node.type == "float" then
        print(prefix .. connector .. node.type .. ": " .. node.name)

    elseif node.type == "call" then
        print(prefix .. connector .. "Call: " .. node.name)

        local nextPrefix = prefix .. (isLast and "    " or "│   ")
        for i, arg in ipairs(node.args) do
            printNode(arg, nextPrefix, i == #node.args)
        end

    elseif node.type == "declaration" then
        print(prefix .. connector .. "Declaration: " .. node.name)

        local nextPrefix = prefix .. (isLast and "    " or "│   ")
        print(nextPrefix .. "├── Parameters")

        for i, arg in ipairs(node.args) do
            printNode(arg, nextPrefix .. "│   ", i == #node.args)
        end

        print(nextPrefix .. "└── Body")
        for i, bodyNode in ipairs(node.body) do
            printNode(bodyNode, nextPrefix .. "    ", i == #node.body)
        end
    end
end

local function printMetadata(metadata)
    print("Metadata:")
    print("Declarations:", #metadata.declarations)
    for _, node in ipairs(metadata.declarations) do
        print("    " .. node.name)
    end

    print("Calls:", #metadata.calls)
    for _, node in ipairs(metadata.calls) do
        print("    " .. node.name)
    end

    print("Identifiers:", #metadata.identifiers)
    for _, node in ipairs(metadata.identifiers) do
        print("    " .. node.name)
    end
end

function parserMethods:print()
    printMetadata(self.metadata)
    print("Program")
    for i, node in ipairs(self.tree) do
        printNode(node, "", i == #self.tree)
    end
end

function parserMethods:consume()
    local value = self:peek()
    if value ~= nil then 
        self.currTokenPos = self.currTokenPos + 1
        return value 
    end
    printParserError("Consume cannot peek at the stream", {})
    return nil 
end

function parserMethods:expect(expectedType)
    local value = self:peek()
    if value ~= nil then 
        if value.ttype ~= expectedType then 
            value.expectedType = expectedType
            return false
        end
        return true
    end
    printParserError("Expect cannot peek at the stream", {})
    return false
end

function parserMethods:expectWithError(expectedType)
    local value = self:peek()
    if value ~= nil then 
        if value.ttype ~= expectedType then 
            value.expectedType = expectedType
            printParserError("Expected an 'expectedType' type, got 'value' of type 'ttype'", value)
            os.exit(1)
            return false
        end
        return true
    end
    printParserError("Expect cannot peek at the stream", {})
    os.exit(1)
end

function parserMethods:peek()
    if self.currTokenPos > #self.tokens then
        -- printParserError("Peeking but at the end of stream", {})
        return nil
    end
    return self.tokens[self.currTokenPos]
end

function parser.parseDeclaration(parsed)
    parsed:expectWithError("OPENBRACE")
    parsed:consume()
    local node = {}
    while not parsed:expect("CLOSEBRACE") do 
        local bodyNode = parser.parseBlock(parsed)
        table.insert(node, bodyNode)
    end
    parsed:consume()
    return node 
end



function parser.parsePrefix(parsed)
    parsed:expectWithError("IDENTIFIER")  
    local identifier = parsed:consume()
    local node = {type="identifier", name=identifier.value}
    if not parsed:expect("OPENBRACKET") then 
        return node 
    end
    parsed:consume()
    node.type = "call"
    node.args = {}
    if parsed:expect("CLOSEBRACKET") then 
        parsed:consume()
        return node 
    end
    while true do 
        local argNode = parser.parsePrefix(parsed)
        table.insert(node.args, argNode)
        if parsed:expect("COMMA") then 
            parsed:consume()
        elseif parsed:expect("CLOSEBRACKET") then 
            parsed:consume()
            break
        else 
            parsed:expectWithError("CLOSEBRACKET OR COMMA")
        end
    end
    return node
end

function parser.classify(parsed, node) 
    if parsed:expect("OPENBRACE") then 
        node.type = "declaration"
        return 
    end
end

function parser.parseBlock(parsed)
    local node = parser.parsePrefix(parsed)
    parser.classify(parsed, node)
    if node.type == "declaration" then
        node.body = parser.parseDeclaration(parsed) -- ideally serial lines of call nodes, last one is implicit return
    end
    return node 
end

function parser.verifyDeclarationRecursively(node) 
    for i, node in ipairs(node.args) do
        if node.type ~= "identifier" then 
            return false
        end
    end
    for i, node in ipairs(node.body) do
        if node.type == "declaration" then 
            return false
        end
        if node.type == "call" then 
            local success = parser.verifyCallRecursively(node)
            if not success then 
                return false
            end
        end
    end
    return true
end

function parser.verifyCallRecursively(node)
    for i, node in ipairs(node.args) do
        if node.type == "declaration" then 
            return false
        end
        if node.type == "call" then
            local success = parser.verifyCallRecursively(node)
            if not success then
                return false
            end
        end
    end
    return true
end

function parser.verifyTree(parsed)
    for i, node in ipairs(parsed.tree) do
        if node.type == "declaration" then 
            local success = parser.verifyDeclarationRecursively(node)
            if not success then 
                printParserError("Declaration 'name' is improper", {name = node.name})
                os.exit(1)
            end
        end
        if node.type == "call" then 
            local success = parser.verifyCallRecursively(node)
            if not success then 
                printParserError("Call 'name' is improper", {name = node.name})
                os.exit(1)
            end
        end
    end
end

function parser.classifyLiteral(literal)
    if literal.name:match("^%d+$") ~= nil then 
        literal.type = "integer"
        literal.value = tonumber(literal.name)
        return 
    end
    if literal.name:match("^%d+%.%d+$") ~= nil then 
        literal.type = "float"
        literal.value = tonumber(literal.name)
        return 
    end
    if literal.name:match('^".*"$') ~= nil then
    -- if literal.name:match("^%a+$") ~= nil then 
        literal.type = "string"
        return
    end
    -- printParserError("IDENTIFIER of type with value name cannot be classified", literal)
    -- os.exit(1)
end

function parser.classifyLiteralsCall(node)
    for i, argument in ipairs(node.args) do
        if argument.type == "identifier" then 
            parser.classifyLiteral(argument)
        end
        if argument.type == "call" then 
            parser.classifyLiteralsCall(argument)
        end
    end
end

function parser.classifyLiterals(tree)
    for i, node in ipairs(tree) do
        if node.type == "declaration" then 
            parser.classifyLiterals(node.body) 
        end
        if node.type == "call" then 
            parser.classifyLiteralsCall(node)
        end
        if node.type == "identifier" then 
            parser.classifyLiteral(node)
        end
    end
end

function parser.parse(tokens)
    local parsed = {
        tree = {}, -- has to be made
        currTokenPos = 1, -- points at current token
        tokens = tokens.stream
    }
    setmetatable(parsed, parserMethods)
    while parsed:peek() ~= nil do 
        table.insert(parsed.tree, parser.parseBlock(parsed))
    end
    parser.verifyTree(parsed)
    parser.classifyLiterals(parsed.tree)
    return parsed
end

return parser