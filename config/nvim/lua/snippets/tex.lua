local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require('luasnip.extras.fmt').fmt

return {
    s("del", t("% -----------------------------------------------------------------------------")),
    s("begin", fmt("\\begin{{{}}}\n\t{}\n\\end{{{}}}", { i(1, "something"), i(0), i(1) })),
    s("b", fmt("\\begin{{{}}}\n\t{}\n\\end{{{}}}", { i(1, "something"), i(0), i(1) })),
    s("tab", fmt("\\begin{{{}}}{{{}}}\n\t{}\n\\end{{{}}}", { i(1, "tabular"), i(2, "c"), i(0), i(1) })),
    s("table", fmt("\\begin{{table}}[{}]\n\t\\centering\n\t\\caption{{{}}}\n\t\\label{{tab:{}}}\n\t\\begin{{{}}}{{{}}}\n\t{}\n\t\\end{{{}}}\n\\end{{table}}", { i(1, "htpb"), i(2, "caption"), i(3, "label"), i(4, "tabular"), i(5, "c"), i(0), i(4) })),
    s("fig", fmt("\\begin{{figure}}[{}]\n\t\\centering\n\t\\includegraphics[width={}\\linewidth]{{{}}}\n\t\\caption{{{}}}\n\t\\label{{fig:{}}}\n\\end{{figure}}", { i(1, "htpb"), i(2, "0.8"), i(3, "name.ext"), i(4, "caption"), i(5, "label") })),
    s("enum", fmt("\\begin{{enumerate}}\n\t\\item {}\n\\end{{enumerate}}", { i(0) })),
    s("item", fmt("\\begin{{itemize}}\n\t\\item {}\n\\end{{itemize}}", { i(0) })),
    s("desc", fmt("\\begin{{description}}\n\t\\item[{}] {}\n\\end{{description}}", { i(1), i(0) })),
    s("it", fmt("\\item {}\n{}", { i(1), i(0) })),
    s("part", fmt("\\part{{{}}}\n\\label{{prt:{}}}\n\n{}", { i(1, "part name"), i(2, "part_label"), i(0) })),
    s("cha", fmt("\\chapter{{{}}}\n\\label{{cha:{}}}\n\n{}", { i(1, "chapter name"), i(2, "chapter_label"), i(0) })),
    s("sec", fmt("\\section{{{}}}\n\\label{{sec:{}}}\n\n{}", { i(1, "section name"), i(2, "section_label"), i(0) })),
    s("sub", fmt("\\subsection{{{}}}\n\\label{{sub:{}}}\n\n{}", { i(1, "subsection name"), i(2, "subsection_label"), i(0) })),
    s("ssub", fmt("\\subsubsection{{{}}}\n\\label{{ssub:{}}}\n\n{}", { i(1, "subsubsection name"), i(2, "subsubsection_label"), i(0) })),
    s("par", fmt("\\paragraph{{{}}}\n\\label{{par:{}}}\n\n{}", { i(1, "paragraph name"), i(2, "paragraph_label"), i(0) })),
    s("subp", fmt("\\subparagraph{{{}}}\n\\label{{par:{}}}\n\n{}", { i(1, "subparagraph name"), i(2, "subparagraph_label"), i(0) })),
    s("ni", fmt("\\noindent\n{}", { i(0) })),
    s("pac", fmt("\\usepackage[{}]{{{}}}\n{}", { i(1, "options"), i(2, "package"), i(0) })),
    s("lp", fmt("\\left({}\\right)\n{}", { i(1), i(0) })),
}
