-- capturing upvalues
-- https://github.com/wbthomason/packer.nvim/issues/1001#issuecomment-1206609769

--- @param id string
--- @param what "'fg'" | "'bg'"
--- @param mode "'gui'" | "'cterm'" | "'term'"
--- @return string
_G.hiof = function(id, what, mode)
    return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(id)), what, mode)
end

--- @generic K, V
--- @param tbl table<K, V>
--- @return K[]
_G.keys = function(tbl)
    local ks = {}
    for k, _ in pairs(tbl) do
        ks[#ks + 1] = k
    end
    return ks;
end

--- @generic K, V
--- @param tbl table<K, V>
--- @return V[]
_G.values = function(tbl)
    local vals = {}
    for _, v in pairs(tbl) do
        vals[#vals + 1] = v;
    end
    return vals
end

--- @generic T
--- @param object T
--- @return T
_G.trace = function(object)
    local inspect = require('inspect')
    print(inspect(object));
    return object
end

---Pretty print lua table
function _G.dump(...)
    local objects = vim.tbl_map(vim.inspect, { ... })
    assert(objects ~= nil)
    print(table.unpack(objects))
end

if _VERSION == "Lua 5.1" or _VERSION == "LuaJIT" then
    ---@diagnostic disable: deprecated
    table.unpack = unpack
end

-- Use nvim-treesitter instead of vim-polyglot for:
-- filetype => module
_G.treesitter_ft_mod = {
    bibtex          = 'bibtex',
    cmake           = 'cmake',
    comment         = 'comment',
    fennel          = 'fennel',
    gitattributes   = 'gitattributes',
    graphql         = 'graphql',
    haskell         = 'haskell',
    hcl             = 'hcl',
    html            = 'html',
    lua             = 'lua',
    nix             = 'nix',
    ocaml           = 'ocaml',
    ocaml_interface = 'ocaml_interface',
    proto           = 'proto',
    python          = 'python',
    regex           = 'regex',
    scala           = 'scala',
    sql             = 'sql',
    tla             = 'tlaplus',
    toml            = 'toml',
    typescript      = 'typescript',
    vim             = 'vim',
    yaml            = 'yaml',
    zig             = 'zig',
};

return {
    {
        'glacambre/firenvim',
        config = function()
            vim.g.firenvim_config = {
                globalSettings = {
                    alt = 'all',
                },
                localSettings = {
                    ['.*'] = {
                        takeover = 'never',
                        priority = 0,
                    },
                    ['https?:..leetcode.com.*'] = {
                        selector = 'div.ReactCodeMirror div.CodeMirror textarea:not([readonly])',
                        filename = '/tmp/{hostname}_{pathname%32}.{extension}',
                        takeover = 'always',
                        priority = 1,
                    }
                }
            }
            vim.cmd [[au BufEnter leetcode.com_* set guifont=monospace:h16]] -- no longer italic
        end,
        build = function() vim.fn['firenvim#install'](0) end,
    },
    {
        'sheerun/vim-polyglot',
        init = function()
            vim.g.polyglot_disabled = { 'sensible', '', table.unpack(values(treesitter_ft_mod)) }
        end,
        enabled = function()
            -- not working with vim-markdown
            local set = { 'sensible', '' }
            return set[vim.bo.filetype] == nil and _G.treesitter_ft_mod[vim.bo.filetype] == nil;
        end,
        event = "FileType", -- better than FileType as plugins may set ft
    },
    {
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            require('indent_blankline').setup { use_treesitter = true };
            vim.g.indent_blankline_filetype_exclude = { 'help', 'coc-explorer' }
            vim.g.indent_blankline_char = '│';

            -- Actually need something like the freground color of the text
            vim.cmd([[autocmd ColorScheme hi IndentBlanklineChar guifg=synIDattr(synIDtrans(hlID('Normal')), 'fg', 'gui')]])
        end,
        lazy = true,
        event = "ColorScheme",
    },
    {
        "fladson/vim-kitty", -- syntax highlighting for kitty cnofig
        lazy = true,
        ft = "kitty",
    },
    {
        "EdenEast/nightfox.nvim",
        config = function()
            vim.cmd [[colorscheme carbonfox]]
            vim.cmd [[hi Operator gui=None ]] -- no longer italic

            -- make indent area contrast
            vim.o.guicursor = table.concat({
                'n-v-c:block',
                'i-ci-ve:hor100',
                'r-cr:hor20',
                'o:hor50',
                'a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor',
                'sm:block-blinkwait175-blinkoff150-blinkon175',
            }, ',');
            vim.cmd [[hi Cursor guifg=NONE guibg=NONE gui=nocombine ]]
        end,
        enabled = function() return vim.fn.has('mac') == 1 end,
    },
    {
        'olimorris/onedarkpro.nvim',
        config = function()
            local onedarkpro = require('onedarkpro')
            local colors = onedarkpro.get_colors('onedark')
            onedarkpro.setup({
                options = { transparency = true },
                hlgroups = {
                    Normal = { fg = '#abb2bf' },
                    DiffAdd = { fg = 'green', bg = 'NONE' },
                    DiffDelete = { fg = 'red', bg = 'NONE' },
                    DiffChange = { fg = '#d2a8ff', bg = 'NONE' },
                    diffChanged = { fg = '#d2a8ff', bg = 'NONE' },
                    CocFloating = { link = 'Pmenu' }, -- originally NormalFloat
                    -- CocUnusedHighlight -> CocFadeOut -> Conceal
                    CocUnusedHighlight = { fg = colors.gray, bg = 'NONE' },
                    CocInfoSign = { fg = 'LightBlue' },
                    CocHintSign = { fg = colors.cyan },
                },
            })
            onedarkpro.load()
            vim.cmd [[hi Operator gui=None ]] -- no longer italic

            -- make indent area contrast
            vim.o.guicursor = table.concat({
                'n-v-c:block',
                'i-ci-ve:hor100',
                'r-cr:hor20',
                'o:hor50',
                'a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor',
                'sm:block-blinkwait175-blinkoff150-blinkon175',
            }, ',');
            vim.cmd [[hi Cursor guifg=NONE guibg=NONE gui=nocombine ]]
        end,
        enabled = function() return vim.fn.has('linux') == 1 end,
    },

    'qxxxb/vim-searchhi',

    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { {
            'pwntester/octo.nvim',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-symbols.nvim',
            'xiyaowong/telescope-emoji.nvim',
            'fannheyward/telescope-coc.nvim',
            'luc-tielen/telescope_hoogle',
            'MrcJkb/telescope-manix',
            'AckslD/nvim-neoclip.lua',
        } },
        config = function()
            require('octo').setup()
            require('neoclip').setup()
            local telescope = require('telescope')
            local actions = require('telescope.actions')

            telescope.setup {
                set_env = { ['COLORTERM'] = 'truecolor' }, -- default = nil,
                extensions = {
                    fzf = {
                        override_filter_sorter = true,
                    }
                },
                defaults = {
                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-u>"] = false, -- do not scroll up in preview
                            ["<C-b>"] = actions.preview_scrolling_up,
                            ["<C-f>"] = actions.preview_scrolling_down,
                        },
                        n = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                        }
                    }
                }
            }

            telescope.load_extension('coc')
            telescope.load_extension('hoogle')
            telescope.load_extension('fzf')
        end,
        event = "VeryLazy",
    },
    { 'rafcamlet/nvim-luapad', lazy = true, ft = "lua" },

    {
        'numToStr/Comment.nvim',
        dependencies = 'JoosepAlviste/nvim-ts-context-commentstring',
        config = function()
            local cms_internal = require('ts_context_commentstring.internal');
            local cms_utils = require('ts_context_commentstring.utils');
            require 'nvim-treesitter.configs'.setup {
                context_commentstring = {
                    enable = true,
                    enable_autocmd = false,
                },
            }

            require('Comment').setup {
                pre_hook = function(ctx)
                    local U = require('Comment.utils')
                    local ty = ctx.type == U.ctype.line and '__single' or '__multi'

                    local location = nil;

                    if vim.bo.filetype == 'typescriptreact' then
                        if ctx.ctype == U.ctype.block then
                            location = cms_utils.get_cursor_location()
                        elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
                            location = cms_utils.get_visual_start_location()
                        end
                    end

                    return cms_internal.calculate_commentstring({
                        key = ty,
                        location = location,
                    })
                end,
                mappings = {
                    basic = true,
                    extra = false,
                }
            }
        end,
    },
    {
        'kylechui/nvim-surround',
        config = function() require('nvim-surround').setup({}) end
    },
    'junegunn/vim-easy-align',
    'junegunn/vim-peekaboo',
    'ojroques/vim-oscyank',
    {
        'FooSoft/vim-argwrap',
        config = function() vim.g.argwrap_tail_comma = 1 end
    },
    {
        'sbdchd/neoformat',
        config = function()
            vim.g.neoformat_enabled_typescript = { 'clang-format' };
            -- Enable alignment

            vim.g.neoformat_basic_format_align = 1
            -- Enable tab to spaces conversion
            vim.g.neoformat_basic_format_retab = 1
            -- Enable trimmming of trailing whitespace
            vim.g.neoformat_basic_format_trim = 1
        end
    },

    { 'Olical/conjure', lazy = true },
    {
        'Olical/aniseed',
        config = function() vim.g["aniseed#env"] = true end,
        lazy = true,
    },

    {
        'iamcco/markdown-preview.nvim',
        ft = { 'markdown' },
        build = 'cd app && yarn install',
        cmd = 'MarkdownPreview',
        config = function()
            vim.g.mkdp_open_ip = 'localhost'
            -- To debug
            -- vim.env.NVIM_MKDP_LOG_FILE = '/tmp/mkdp.log'
            -- vim.env.NVIM_MKDP_LOG_LEVEL = 'debug'

            -- wsl2
            if vim.fn.has('wsl') == 1 then
                vim.cmd([[
                    function! g:OpenBrowser(url)
                        silent exe '!/mnt/c/Windows/System32/cmd.exe /c start' a:url
                    endfunction
                ]]);
                vim.g.mkdp_browserfunc = 'g:OpenBrowser'
            end
        end
    },
    {
        'epwalsh/obsidian.nvim',
        dependencies = { 'hrsh7th/nvim-cmp' },
        config = function() require('obsidian').setup({
                dir = "~/OneDrive/obsidian",
                use_advanced_uri = true,
            })
        end,
        lazy = true,
        ft = "markdown",
    },

    'ryvnf/readline.vim',
    'kana/vim-fakeclip',
    'chrisbra/unicode.vim',
    { 'tpope/vim-liquid', lazy = true, ft = 'liquid' },
    {
        'tpope/vim-dadbod', -- for SQL. TODO: help exrc
        dependencies = 'kristijanhusak/vim-dadbod-ui',
        lazy = true,
        cmd = "DB",
    },
    'dhruvasagar/vim-table-mode',

    {
        'rhysd/git-messenger.vim',
        keys = { '<leader>gm', '<cmd>GitMessenger<cr>' },
        config = function() vim.g.git_messenger_include_diff = "current" end
    },

    -- use 'jbyuki/instant.nvim'  -- coediting

    -- https://github.com/rhysd/conflict-marker.vim
    -- https://github.com/christoomey/vim-conflicted
    'tpope/vim-fugitive',
    'cohama/agit.vim',

    -- The default netrw#BrowseX() is broken. It always opens `file:///...` in
    -- vim despite netrw#CheckIfRemote() returns 1.
    --
    -- So may be xdg-open.
    -- xdg-open uses both Chromium and Firefox🤷, and it does not care about
    -- fragments in a url.
    {
        'tyru/open-browser.vim',
        config = function()
            vim.g.netrw_nogx = 1
            if vim.fn.has('linux') == 1 then
                vim.g.openbrowser_browser_commands = {
                    { name = "firefox", args = { "{browser}", "{uri}" } },
                    { name = "xdg-open", args = { "{browser}", "{uri}" } },
                    { name = "x-www-browser", args = { "{browser}", "{uri}" } },
                    { name = "w3m", args = { "{browser}", "{uri}" } },
                }
            end
            vim.cmd [[ nmap gx <Plug>(openbrowser-smart-search) ]]
            vim.cmd [[ vmap gx <Plug>(openbrowser-smart-search) ]]
        end,
    },
    {
        'lewis6991/gitsigns.nvim',
        dependencies = 'nvim-lua/plenary.nvim',
        config = function() require('gitsigns').setup({
                -- I dont like the index `Hunk 1 of 2`, maybe I can patch a plugin
                -- https://github.com/wbthomason/packer.nvim/issues/882
                preview_config = {
                    -- Options passed to nvim_open_win
                    border = 'none',
                    style = 'minimal',
                    relative = 'cursor',
                },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navigation
                    map('n', ']c', function()
                        if vim.wo.diff then return ']c' end
                        vim.schedule(gs.next_hunk)
                        return '<Ignore>'
                    end, { expr = true })
                    map('n', '[c', function()
                        if vim.wo.diff then return '[c' end
                        vim.schedule(gs.prev_hunk)
                        return '<Ignore>'
                    end, { expr = true })

                    -- Actions
                    map({ 'n', 'v' }, '<leader>hs', gs.stage_hunk)
                    map({ 'n', 'v' }, '<leader>hr', gs.reset_hunk)
                    map('n', '<leader>hS', gs.stage_buffer)
                    map('n', '<leader>hu', gs.undo_stage_hunk)
                    map('n', '<leader>hR', gs.reset_buffer)
                    map('n', '<leader>hp', gs.preview_hunk)
                    map('n', '<leader>hb', function() gs.blame_line { full = true } end)
                    map('n', '<leader>tb', gs.toggle_current_line_blame)
                    map('n', '<leader>hd', gs.diffthis)
                    map('n', '<leader>hD', function() gs.diffthis('~') end)
                    map('n', '<leader>td', gs.toggle_deleted)

                    -- Text object
                    map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
                end
            });
        end,
        lazy = true,
        event = "BufEnter",
    },
    'wellle/tmux-complete.vim',
    'chiedo/vim-case-convert',
    'gyim/vim-boxdraw',
    { 'fisadev/vim-isort', ft = { 'python' } },
    {
        'tell-k/vim-autopep8',
        ft = "python",
        config = function() vim.g.autopep8_disable_show_diff = 1 end
    },

    {
        'SirVer/ultisnips',
        dependencies = { 'honza/vim-snippets' },
        config = function()
            vim.g.UltiSnipsListSnippets        = "<c-tab>"
            vim.g.UltiSnipsJumpForwardTrigger  = "<tab>"
            vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"
            vim.g.snips_author                 = "Congee"
        end
    },

    { 'neomake/neomake', ft = { 'python', 'cpp', 'typescript', 'rust' } },
    'skywind3000/asyncrun.vim',
    {
        'mattn/emmet-vim',
        ft = { 'html', 'hbs', 'typescript', 'typescriptreact' },
        config = function()
            vim.g.user_emmet_settings = { typescript = { extends = 'jsx' } }
        end
    },

    -- color picker
    { 'KabbAmine/vCoolor.vim', ft = { 'less', 'sass', 'css', 'typescriptreact' } },
    'rhysd/vim-grammarous',
    {
        'norcalli/nvim-colorizer.lua',
        ft = { 'css', 'javascript', 'html', 'less', 'sass', 'typescriptreact' },
        config = function() require 'colorizer'.setup() end,

    },
    {
        'liuchengxu/vista.vim',
        config = function()
            vim.g.vista_default_executive = 'coc'
            vim.g['vista#renderer#enable_icon'] = 1
            -- doesn't hls provide symbols?
            -- vim.g.vista_ctags_cmd = { haskell = 'hasktags -x -o - -c' }
            vim.cmd [[ nnoremap <silent> <leader>vt :Vista!!<CR> ]]
        end
    },
    -- use {'nvim-lua/lsp-status.nvim'}
    'kyazdani42/nvim-web-devicons',
    -- use {
    --     'glepnir/galaxyline.nvim',
    --     config = function() require('eviline') end,
    --     dependencies = {'kyazdani42/nvim-web-devicons', 'liuchengxu/vista.vim'}
    -- }
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'kyazdani42/nvim-web-devicons', lazy = true },
        config = function()
            require('evil_lualine')
            -- lualine.nvim does not respect `set laststatus=0` :/
            -- https://github.com/nvim-lualine/lualine.nvim/issues/776
            vim.cmd [[ autocmd CursorMoved,CursorMovedI,VimResized,FileType,BufEnter * setlocal laststatus=0 ]]
        end,
        pin = true,
        lazy = true,
        event = "BufEnter",
    },

    {
        'vimpostor/vim-tpipeline', -- move vim statusline into tmux statsline
        lazy = true,
        event = "BufEnter",
    },

    { 'towolf/vim-helm', lazy = true, ft = "helm" },
    {
        'williamboman/mason.nvim',
        config = function() require('mason').setup() end,
    },
    {
        'neoclide/coc.nvim',
        build = 'yarn install --frozen-lockfile',
        branch = 'release',
        commit = '040f3a9ae3b71be341040af32ae6593c91c3689e',
        dependencies = { 'ryanoasis/vim-devicons' }, -- coc-explorer dependencies it
        config = function()
            -- vim.env.NVIM_COC_LOG_LEVEL = 'debug'
            vim.g.coc_global_extensions = {
                'coc-sumneko-lua',
                'coc-rust-analyzer',
                'coc-git',
                'coc-yaml',
                'coc-diagnostic',
                'coc-explorer',
                'coc-tsserver',
                'coc-pyright',
                -- 'coc-metals',  -- scalameta/nvim-metals
                'coc-json', -- json-lsp
                'coc-syntax',
                'coc-clangd', -- clangd
                'coc-sh',
                'coc-html',
                'coc-vimlsp', -- hrsh7th/cmp-nvim-lua  dmitmel/cmp-vim-lsp
                'coc-clang-format-style-options',
                'coc-ltex',
                'coc-emmet',
                'coc-markdown-preview-enhanced', 'coc-webview',
                'coc-markmap',
                'coc-markdownlint',
                'coc-prettier',
                'coc-docker',
                'coc-cmake',
                'coc-tailwindcss',
                'coc-xml',
                'coc-go',
            }

            -- switch between .h & .c. The good ol' a.vim
            local thunk = function() vim.api.nvim_create_user_command(
                    'A',
                    function() vim.cmd('CocCommand clangd.switchSourceHeader'); end,
                    { nargs = 0 }
                )
            end;
            vim.api.nvim_create_autocmd(
                'FileType', { pattern = { 'c', 'cpp' }, callback = thunk }
            )

            vim.g.coc_default_semantic_highlight_groups = 1
            -- Apparently, coc-settings.json does not parse $JAVA_HOME, so we
            -- need to dynamically evaluate $JAVA_HOME:
            -- vim.cmd[[ :call coc#config('ltex.java.path', $JAVA_HOME) ]]
            vim.fn["coc#config"]('ltex.java.path', vim.env.JAVA_HOME);
            vim.fn["coc#config"](
                'rust-analyzer.server.path',
                vim.env.HOME .. '/.nix-profile/bin/rust-analyzer'
            );
        end,
        event = "VeryLazy",
    },
    {
        'gelguy/wilder.nvim',
        dependencies = { 'romgrk/fzy-lua-native' },
        build = ":UpdateRemotePlugins",
        config = function()
            -- VimL lambdas cannot be used with Lua calls. Will make a switch
            -- once it's fixed. https://github.com/gelguy/wilder.nvim/issues/52
            vim.cmd [[
                function! s:wilder_init() abort
                    call wilder#setup({'modes': [':', '/', '?']})
                    call wilder#set_option('use_python_remote_plugin', 0)
                    call wilder#set_option('pipeline', [
                      \   wilder#branch(
                      \     wilder#cmdline_pipeline({
                      \       'fuzzy': 1,
                      \       'fuzzy_filter': wilder#lua_fzy_filter(),
                      \     }),
                      \     wilder#vim_search_pipeline(),
                      \   ),
                      \ ])

                    let l:hightlight_accent = wilder#make_hl(
                      \   'WilderAccent',
                      \   'Pmenu',
                      \   [{}, {}, {'foreground': '#f4468f'}]
                      \ )
                    call wilder#set_option('renderer', wilder#renderer_mux({
                      \ ':': wilder#popupmenu_renderer({
                      \   'highlighter': wilder#lua_fzy_highlighter(),
                      \   'highlights': {'accent': l:hightlight_accent},
                      \   'max_height': '25%',
                      \   'left':  [ ' ', wilder#popupmenu_devicons() ],
                      \   'right': [ ' ', wilder#popupmenu_scrollbar() ],
                      \ }),
                      \ '/': wilder#popupmenu_renderer({
                      \   'highlighter': wilder#lua_fzy_highlighter(),
                      \   'highlights': {'accent': l:hightlight_accent},
                      \   'max_height': '25%',
                      \   'right': [ ' ', wilder#popupmenu_scrollbar() ],
                      \ }),
                      \ }))
                endfunction
                " defer startup
                autocmd CmdlineEnter * ++once call s:wilder_init() | call wilder#main#start()
            ]];
        end,
    },

    -- use 'kyazdani42/nvim-tree.lua'
    -- use 'romgrk/barbar.nvim'  -- barbar does not play well with coc-explorer
    {
        'ap/vim-buftabline',
        config = function()
            vim.g.buftabline_show = 1
            vim.g.buftabline_numbers = 2
        end
    },
    { 'voldikss/vim-floaterm' },
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/neotest-python",
            "nvim-neotest/neotest-vim-test",
            "nvim-treesitter/nvim-treesitter",
            "antoinemadec/FixCursorHold.nvim"
        },
        config = function()
            require('neotest').setup({
                adapters = {
                    require('neotest-python')({}),
                    require('neotest-vim-test')({
                        ignore_file_types = { "python", "vim" }
                    }),
                }
            });
        end,
        lazy = true,
        ft = { "vim", "python" },
    },
    -- use 'heavenshell/vim-pydocstring', {'for': 'python'}
    { 'wookayin/semshi', build = ':UpdateRemotePlugins', lazy = true, ft = "python" },
    { 'jackguo380/vim-lsp-cxx-highlight', lazy = true, ft = 'cpp' },

    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            require 'nvim-treesitter.configs'.setup {
                compilers = { "clang++", "zig" },
                ensure_installed = _G.values(_G.treesitter_ft_mod);
                highlight = {
                    enable = true,
                    disable = { "cpp", "bash", "python", "typescript", "go", "yaml" },
                    additional_vim_regex_highlighting = false,
                },
                indent = {
                    enable = false,
                    disable = { "python" },
                },
                incremental_selection = { enable = true },
            }

            local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
            parser_config.kdl = {
                install_info = {
                    url = "https://github.com/spaarmann/tree-sitter-kdl",
                    files = { "src/parser.c", "src/scanner.c" },
                    branch = "main",
                },
            }

            require('nvim-treesitter.parsers').filetype_to_parsername.kdl = "kdl"
        end
    },

    {
        'windwp/nvim-autopairs',
        config = function() require('nvim-autopairs').setup {}; end,
    },

    {
        'yioneko/nvim-yati',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        cond = function() return vim.bo.filetype == 'python'; end,
        config = function()
            require("nvim-treesitter.configs").setup {
                yati = { enable = true },
            };
        end
    },

    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        config = function()
            require 'nvim-treesitter.configs'.setup {
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                            ["ac"] = "@class.outer",
                            ["ic"] = "@class.inner",
                        },
                    },
                    swap = {
                        enable = true,
                        swap_next = { ["<LocalLeader>xp"] = "@parameter.inner" },
                        swap_previous = { ["<LocalLeader>px"] = "@parameter.inner" },
                    },
                },
            }
        end,
    },

    {
        'nvim-treesitter/nvim-treesitter-refactor',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        config = function()
            require 'nvim-treesitter.configs'.setup {
                refactor = {
                    highlight_current_scope = { enable = false },
                    highlight_definitions = { enable = true },
                    smart_rename = {
                        enable = true,
                        keymaps = {
                            smart_rename = "<LocalLeader>rn",
                        },
                    },
                },
            }
        end,
    },

    {
        'andymass/vim-matchup',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        config = function()
            require 'nvim-treesitter.configs'.setup {
                matchup = {
                    enable = true, -- mandatory, false will disable the whole extension
                    disable = {}, -- optional, list of language that will be disabled
                    -- [options]
                },
            }
        end
    },

    -- vim.fn.synstack(...) no longer works under treesitter
    -- use :TSHighlightCapturesUnderCursor instead
    {
        'nvim-treesitter/playground',
        dependencies = 'nvim-treesitter/nvim-treesitter',
    },
}
