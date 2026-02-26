local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s("main", fmt("fn main() -> Result<(), std::io::Error> {{\n    {}\n    Ok(())\n}}", { i(0) })),
    s("sleep", fmt("std::thread::sleep(std::time::Duration::from_secs({}));", { i(0) }))
}
