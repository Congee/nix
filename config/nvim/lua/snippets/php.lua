local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s("php", fmt("<?php\n    {}\n\n# vim: sw=4 ts=4 expandtab:", { i(1) }))
}
