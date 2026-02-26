local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require('luasnip.extras.fmt').fmt

return {
    s("def", fmt("#define {}", { i(1) })),
    s("#ifndef", fmt("#ifndef {}\n#define {} {}\n#endif /* ifndef {} */", { i(1, "SYMBOL"), i(1), i(2, "value"), i(1) })),
    s("#if", fmt("#if {}\n{}\n#endif", { i(1, "0"), i(0) })),
    s("mark", fmt("#if 0\n#pragma mark -\n#pragma mark {}\n#endif\n\n{}", { i(1), i(0) })),
    s("main", fmt("int main(int argc, char *argv[]) {{\n\t{}\n\treturn 0;\n}}", { i(0) })),
    s("for", fmt("for ({} = 0; {} < {}; ++{}) {{\n\t{}\n}}", { i(2, "i"), i(2), i(1, "count"), i(2), i(0) })),
    s("fori", fmt("for ({} {} = 0; {} < {}; ++{}) {{\n\t{}\n}}", { i(4, "int"), i(2, "i"), i(2), i(1, "count"), i(2), i(0) })),
    s("once", fmt("#ifndef {}\n#define {}\n\n{}\n\n#endif /* end of include guard: {} */", { i(1, "HEADER_H"), i(1), i(0), i(1) })),
    s("fprintf", fmt("fprintf({}, \"{}\\n\");{}", { i(1, "stderr"), i(2, "%s"), i(3) })),
    s("printf", fmt("printf(\"{}\\n\");{}", { i(1, "%s"), i(2) })),
    s("eli", fmt("else if ({}) {{\n\t{}\n}}", { i(1, "/* condition */"), i(0) })),
    s("st", fmt("struct {} {{\n\t{}\n}};", { i(1, "name_t"), i(0, "/* data */") })),
    s("fun", fmt("{} {}({})\n{{\n\t{}\n}}", { i(1, "void"), i(2, "function_name"), i(3), i(0) })),
    s("fund", fmt("{} {}({});", { i(1, "void"), i(2, "function_name"), i(3) })),
}
