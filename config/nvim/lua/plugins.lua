local util = require('packer.util')

local plugins = function(use, use_rocks)
    use {
        'glacambre/firenvim',
        config = function()
            vim.g.firenvim_config = {
                localSettings = {
                    ['.*'] = {
                        selector = 'textarea'
                    }
                }
            }
        end,
        run = function() vim.fn['firenvim#install'](0) end
    }
    use {
        'sheerun/vim-polyglot',
        opt = false,
        setup = function()
            -- Please declare this variable before polyglot is loaded (at the top of .vimrc)
            -- vim-polyglot via https://github.com/vim-python/python-syntax improves nothing
            -- not working with vim-markdown
            vim.g.polyglot_disabled = {'python', 'sensible'}
        end
    }
    use {
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            vim.g.indent_blankline_filetype_exclude = {'help', 'coc-explorer'}
            vim.g.indent_blankline_char = '│';
            local guifg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID('Normal')), 'fg', 'gui')
            local ctermfg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID('Normal')), 'fg', 'cterm')
            -- local guifg = vim.api.nvim_eval("synIDattr(synIDtrans(hlID('Normal')), 'fg', 'gui')")

            -- Actually need something like the freground color of the text
            -- vim.cmd('hi IndentBlanklineChar guifg=' .. guifg .. ' ctermfg=' .. ctermfg)
            vim.cmd('hi! link IndentBlanklineSpaceChar Normal')
        end,
    }
    use {
        'joshdick/onedark.vim',
        branch = "main",
        config = function() vim.g.onedark_terminal_italics = 1 end
    }

    use 'junegunn/fzf.vim'  -- depends on pkgs.fzf
    use 'rafcamlet/nvim-luapad'
    use {
        'b3nj5m1n/kommentary',
        config = function()
            vim.g.kommentary_create_default_mappings = false
            vim.cmd([[
                vmap <M-/> <Plug>kommentary_visual_default
                nmap <M-/> <Plug>kommentary_line_default
            ]])
        end
    }
    use 'machakann/vim-sandwich'
    use 'junegunn/vim-easy-align'
    use 'junegunn/vim-peekaboo'
    use 'ojroques/vim-oscyank'
    use {
        'sbdchd/neoformat',
        config = function()
            vim.g.neoformat_enabled_typescript = {'clang-format'};
            -- Enable alignment

            vim.g.neoformat_basic_format_align = 1
            -- Enable tab to spaces conversion
            vim.g.neoformat_basic_format_retab = 1
            -- Enable trimmming of trailing whitespace
            vim.g.neoformat_basic_format_trim = 1
        end
    }

    use 'Olical/conjure'
    use {
        'Olical/aniseed',
        config = function()
            vim.g["aniseed#env"] = true
        end
    }

    use {
        'iamcco/markdown-preview.nvim',
        ft = {'markdown'},
        run = function() vim.fn['mkdp#util#install']() end,
        config = function()
            vim.g.mkdp_open_ip = 'localhost'
            -- wsl2
            -- function! g:OpenBrowser(url)
            --   silent exe '!lemonade open ' a:url
            -- endfunction
            -- let g:mkdp_browserfunc = 'g:OpenBrowser'
        end
    }

    use 'ryvnf/readline.vim'
    use 'kana/vim-fakeclip'
    use 'chrisbra/unicode.vim'
    use 'tpope/vim-liquid'
    use 'tpope/vim-dadbod'  -- for SQL. TODO: help exrc
    use 'kristijanhusak/vim-dadbod-ui'

    use 'cohama/agit.vim'

    use {
        'rhysd/git-messenger.vim',
        keys = {'<leader>gm'},
        cmd = {'GitMessenger'},
        config = function() vim.g.git_messenger_include_diff = "current" end
    }

    -- use 'jbyuki/instant.nvim'  -- coediting

    -- https://github.com/rhysd/conflict-marker.vim
    -- https://github.com/christoomey/vim-conflicted
    use 'tpope/vim-fugitive'
    use 'rbong/vim-flog'
    use 'airblade/vim-gitgutter'
    use {
        'mhinz/vim-signify',
        config = function()
            -- spped up; prevent checking other vcs
            vim.g.signify_vcs_list = {'git'}
            vim.g.signify_realtime = 1
        end
    }
    use 'wellle/tmux-complete.vim'
    use 'chiedo/vim-case-convert'
    use 'gyim/vim-boxdraw'
    use {'monkoose/fzf-hoogle.vim', ft = 'haskell'}
    use {'fisadev/vim-isort', ft = {'python'}}
    use {
        'tell-k/vim-autopep8',
        config = function() vim.g.autopep8_disable_show_diff = 1 end
    }

    use {
        'SirVer/ultisnips',
        requires = { 'honza/vim-snippets' },
        config = function()
            vim.g.UltiSnipsListSnippets        = "<c-tab>"
            vim.g.UltiSnipsJumpForwardTrigger  = "<tab>"
            vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"
            vim.g.snips_author                 = "Congee"
        end
    }

    use {'neomake/neomake', ft = {'python', 'cpp', 'typescript', 'rust'}}
    use 'skywind3000/asyncrun.vim'
    use {
        'mattn/emmet-vim',
        ft = {'html', 'hbs', 'typescript', 'typescriptreact'},
        config = function()
            vim.g.user_emmet_settings = {typescript = {extends = 'jsx'}}
        end
    }

    -- color picker
    use {'Rykka/colorv.vim', ft = {'less', 'sass', 'css', 'typescriptreact'}}
    use 'rhysd/vim-grammarous'
    use {
        'norcalli/nvim-colorizer.lua',
        ft = {'css', 'javascript', 'html', 'less', 'sass', 'typescriptreact'},
        config = function()
            -- if vim.fn.has("mac") then require'colorizer'.setup() end
            require'colorizer'.setup()
        end,

    }
    use {
        'liuchengxu/vista.vim',
        config = function()
            vim.g.vista_default_executive = 'coc'
            vim.g['vista#renderer#enable_icon'] = 1
            -- doesn't hls provide symbols?
            -- vim.g.vista_ctags_cmd = { haskell = 'hasktags -x -o - -c' }
            vim.cmd [[ nnoremap <silent> <leader>vt :Vista!!<CR> ]]
        end
    }
    -- use {'nvim-lua/lsp-status.nvim'}
    use 'kyazdani42/nvim-web-devicons'
    use {
        'glepnir/galaxyline.nvim',
        config = function() require('eviline') end,
        requires = {'kyazdani42/nvim-web-devicons', 'liuchengxu/vista.vim'}
    }

    use {
        'neoclide/coc.nvim',
        branch = 'release',
        requires = { 'ryanoasis/vim-devicons' },  -- coc-explorer requires it
        run = ':CocInstall coc-lua coc-rust-analyzer coc-git coc-yaml coc-explorer coc-tsserver coc-pyright coc-metals coc-json coc-clangd coc-sh coc-html'
    }

    -- use 'kyazdani42/nvim-tree.lua'
    -- use 'romgrk/barbar.nvim'  -- barbar does not play well with coc-explorer
    use {
        'ap/vim-buftabline',
        config = function()
            vim.g.buftabline_show = 1
            vim.g.buftabline_numbers = 2
        end
    }
    use {'voldikss/vim-floaterm'}
    use {
        "rcarriga/vim-ultest",
        requires = {"vim-test/vim-test", 'mfussenegger/nvim-dap'},
        run = ":UpdateRemotePlugins",
        config = function() vim.g['test#strategy'] = 'floaterm' end
    }
    -- use 'heavenshell/vim-pydocstring', {'for': 'python'}
    use {'numirias/semshi', run = ':UpdateRemotePlugins'}
    use {'jackguo380/vim-lsp-cxx-highlight', ft = 'cpp'}
    --[[ use {
        'nvim-treesitter/playground',
        config = function()
            require "nvim-treesitter.configs".setup {
                playground = {
                    enable = true,
                    disable = {},
                    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
                    persist_queries = false, -- Whether the query persists across vim sessions
                    keybindings = {
                        toggle_query_editor = 'o',
                        toggle_hl_groups = 'i',
                        toggle_injected_languages = 't',
                        toggle_anonymous_nodes = 'a',
                        toggle_language_display = 'I',
                        focus_language = 'f',
                        unfocus_language = 'F',
                        update = 'R',
                        goto_node = '<cr>',
                        show_help = '?',
                    },
                },
                query_linter = {
                    enable = true,
                    use_virtual_text = true,
                    lint_events = {"BufWrite", "CursorHold"},
                },
            }
        end
    } ]]
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require'nvim-treesitter.configs'.setup {
                highlight = {
                    enable = true,
                    disable = {"cpp", "bash", "python", "typescript", "go"}
                },
                indent = {
                    enable = true,
                    disable = {"python"},
                },
                incremental_selection = { enable = true },
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
                textobjects = {
                    select = {
                        enable = true,
                        keymaps = {
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                            ["ac"] = "@class.outer",
                            ["ic"] = "@class.inner",
                        },
                    },
                },
            }
        end
    }

    use_rocks {'luaposix', 'lua-cjson', 'inspect', 'stdlib', 'penlight', 'lua-path'}
end

local config = {
    compile_path = util.join_paths(vim.fn.stdpath('data'), 'site', 'plugin', 'packer_compiled.vim'),
}

return require('packer').startup({plugins, config = config})
