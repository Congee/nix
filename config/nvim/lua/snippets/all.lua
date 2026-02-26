local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmt = require('luasnip.extras.fmt').fmt

local function get_comment_start()
    local cstr = vim.bo.commentstring
    if not cstr or cstr == "" then return "/* " end
    local start = cstr:match("^(.*)%%s")
    return start and vim.trim(start) .. " " or ""
end

local function get_comment_end()
    local cstr = vim.bo.commentstring
    if not cstr or cstr == "" then return " */" end
    local ending = cstr:match("%%s(.*)$")
    return ending and ending ~= "" and " " .. vim.trim(ending) or ""
end

local function get_date()
    return os.date("%d-%m-%y")
end

return {
    s("todo", fmt("{comment_start}{keyword}: {desc} <{date}, Congee>{comment_end}", {
        comment_start = f(get_comment_start),
        keyword = i(1, "TODO"),
        desc = i(0),
        date = f(get_date),
        comment_end = f(get_comment_end)
    })),
    s("xxx", fmt("{comment_start}{keyword}: {desc} <{date}, Congee>{comment_end}", {
        comment_start = f(get_comment_start),
        keyword = i(1, "XXX"),
        desc = i(0),
        date = f(get_date),
        comment_end = f(get_comment_end)
    })),
    s("fixme", fmt("{comment_start}{keyword}: {desc} <{date}, Congee>{comment_end}", {
        comment_start = f(get_comment_start),
        keyword = i(1, "FIXME"),
        desc = i(0),
        date = f(get_date),
        comment_end = f(get_comment_end)
    }))
}
