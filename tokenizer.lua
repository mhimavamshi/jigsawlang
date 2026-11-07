-- probably not the best tokenizer but well it works and good enough

local tokenizer = {}

local tokenMethods = {}
tokenMethods.__index = tokenMethods

function tokenMethods:print() 
    print("printing tokens")
    for i = 1, #self.stream do 
        print("value: ", self.stream[i].value, "ttype: ", self.stream[i].ttype)
    end
end

local function canBeIncluded(curr, nextc)
    
    if curr == "(" then 
        return false
    end

    if curr == ")" then 
        return false
    end

    if nextc == "(" then 
        return false
    end

    if nextc == ")" then 
        return false
    end

    if nextc == " " then 
        return false 
    end

    -- it is interesting to note and maybe a pattern, something to simplify and do easier checks
    -- that for a char, either exclude for anything if its the next
    -- or if its the current exclude anything next
    -- or if its current, unless its something exclude it
    -- include everything until it hits next which is something above
    -- hmmmmmm.....


    -- combine all whitespace into one token
    if curr == " " then 
        if nextc ~= " " then
            return false 
        end
    end 

    -- right, lol this curr and nextc being the same thing means its a delimiter. interesting!
    if curr == "," then 
        return false 
    end
    if nextc == "," then 
        return false 
    end

    if curr == "{" then 
        return false 
    end
    if nextc == "{" then 
        return false 
    end
    
    if curr == "}" then 
        return false 
    end
    if nextc == "}" then 
        return false 
    end

    if curr == "`" then 
        return false 
    end
    if nextc == "`" then 
        return false 
    end
    
    return true
end

local function mintToken(str)
    local tokenData = {value = str, ttype = "IDENTIFIER"}
    if str == "(" then
        tokenData.ttype = "OPENBRACKET"
    end
    if str == ")" then
        tokenData.ttype = "CLOSEBRACKET"
    end
    if str:match("^%s+$") then
        tokenData.ttype = "WHITESPACE"
    end
    if str == "{" then
        tokenData.ttype = "OPENBRACE"
    end
    if str == "}" then
        tokenData.ttype = "CLOSEBRACE"
    end
    if str == "," then
        tokenData.ttype = "COMMA"
    end
    if str == "`" then
        tokenData.ttype = "BACKTICK"
    end
    return tokenData
end

function tokenMethods:populate(content) 
    local buff = {} -- accumulate chars to make a valid token 
    self.stream = {} -- store all valid tokens so far

    for i = 1, #content do
        local currc = content:sub(i,i)
        local nextc = content:sub(i+1, i+1)

        table.insert(buff, currc)

        local canInclude = canBeIncluded(currc, nextc) -- can handle nextc being nil  

        if not canInclude or i == #content then 
            local str = table.concat(buff, "")
            table.insert(self.stream, mintToken(str))
            buff = {}
        end

    end
end

function tokenMethods:stripWhitespace()
    local cleanStream = {}
    for i = 1, #self.stream do
        if self.stream[i].ttype ~= "WHITESPACE" then
            table.insert(cleanStream, self.stream[i])
        end
    end
    self.stream = cleanStream
end

function tokenMethods:stripComments()
    local cleanStream = {}
    local inComment = false
    for i = 1, #self.stream do
        if self.stream[i].ttype == "BACKTICK" then
            inComment = not inComment
        elseif not inComment then
            table.insert(cleanStream, self.stream[i])
        end
    end
    
    self.stream = cleanStream
end


local function readFile(filename)
    local file, err = io.open(filename, "r")

    if not file then
        print("Error opening file: " .. err)
        return nil
    end

    local content = file:read("*all")

    file:close()

    return content
end

function tokenizer.tokenizeFile(file)
    local content = readFile(file)
    if content ~= nil then 
        print("file:", file)
        print("content:", content)
        local tokens = {}
        setmetatable(tokens, tokenMethods)
        tokens:populate(content)
        tokens:stripWhitespace(content) -- for now 
        return tokens
    end
end

return tokenizer
