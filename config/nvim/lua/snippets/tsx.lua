local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s("comp", fmt("class {} extends React.Component {{\n    render() {{\n\treturn (\n\n\t       );\n    }}\n}}", { i(0) }))
}
