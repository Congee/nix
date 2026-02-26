local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s("rdt", fmt("export const {name} = '{name}';\nexport type {name} = typeof {name};", { name = i(1, "typename") }))
}
