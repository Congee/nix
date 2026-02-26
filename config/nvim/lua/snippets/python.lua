local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s("br", t("breakpoint()")),
    s("exit", t("__import__('sys').exit()")),
    s("wwdb", fmt("with __import__('wdb').trace():\n\t{}", { i(1) })),
    s("wdb", t("__import__('wdb').set_trace()")),
    s("aio", fmt("#!/usr/bin/env python3\n# -*- coding: utf-8 -*-\n\nimport asyncio\nimport uvloop\n\n\nasync def fire():\n\tawait {}\n\n\ndef main():\n\tloop = uvloop.new_event_loop()\n\tasyncio.set_event_loop(loop)\n\tloop.run_until_complete(fire())\n\n\nif __name__ == '__main__':\n\tmain()", { i(1) })),
    s("py", fmt("#!/usr/bin/env python3\n# -*- coding: utf-8 -*-\n\nfrom typing import *\n\n\n{}\n\n\ndef main():\n\t...\n\n\nif __name__ == '__main__':\n\tmain()", { i(1) })),
    s("exc", t("__import__('traceback').print_exc()"))
}
