local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s("inclc", fmt("#ifdef __LOCAL__\n#include <leetcode.h>\n#endif", {})),
    s("x", t("std::")),
    s("pln", fmt('fmt::print("{}\\n", {});', { i(1) })),
    s("ponce", t("#pragma once")),
    s("str", t("const std::string")),
    s("uset", fmt("std::unordered_set<{}> {};", { i(1, "int"), i(2, "set") })),
    s("umap", fmt("std::unordered_map<{}, {}> {};", { i(1, "int"), i(2, "int"), i(3, "map") })),
    s("vector", fmt("std::vector<{}> vec{};", { i(1, "int"), i(0) })),
    s("sleep", fmt("using namespace std::chrono_literals;\nstd::this_thread::sleep_for(2000ms);", {}))
}
