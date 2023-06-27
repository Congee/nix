-- To debug :lua print(vim.inspect(vim.lsp.get_client_by_id(1).config))

local lspconfig = require('lspconfig');
local cmp = require("cmp")
local navic = require("nvim-navic")
local navbuddy = require("nvim-navbuddy")
local rust_tools = require('rust-tools')
local inlayhints = require('lsp-inlayhints')

local servers = { 'pyright', 'tsserver', 'rust_analyzer', 'jsonls', 'nil_ls' };

require('mason').setup();
require('mason-lspconfig').setup({
    ensure_installed = servers,
    automatic_installation = true,
})

require('mason-null-ls').setup({
    ensure_installed = { 'stylua', 'ruff', 'eslint_d' },
})

local on_attach = function(client, bufnr)
    local opts = { silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>ac', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>ft', function() vim.lsp.buf.format({ async = true }) end, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '[h', function()
        vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.HINT })
    end, opts)
    vim.keymap.set('n', ']h', function()
        vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.HINT })
    end, opts)
    vim.keymap.set('n', '[w', function()
        vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
    end, opts)
    vim.keymap.set('n', ']w', function()
        vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
    end, opts)
    vim.keymap.set('n', '[e', function()
        vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
    end, opts)
    vim.keymap.set('n', ']e', function()
        vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
    end, opts)
    vim.keymap.set('n', '<leader>fx', function()
        vim.lsp.buf.code_action({
            filter = function(x) return x.isPreferred end,
            apply = true,
        })
    end, opts)

    vim.b.navic_lazy_update_context = true
    if client.server_capabilities.documentSymbolProvider then
        navic.attach(client, bufnr)
    end

    navbuddy.attach(client, bufnr)
    inlayhints.on_attach(client, bufnr)
end


-- Recently lsp client of neovim watch files by polling. This is embarrassing :/
-- https://github.com/neovim/neovim/issues/23291
-- https://github.com/neovim/neovim/issues/23725#issuecomment-1561364086
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
local setup = { on_attach = on_attach, capabilities = capabilities }
for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup(setup) -- call :LspStart on startup
end

lspconfig['lua_ls'].setup(vim.tbl_extend('error', setup, {
    cmd = { vim.env.HOME .. '/.nix-profile/bin/lua-language-server' },
}))
lspconfig['bufls'].setup(vim.tbl_extend('error', setup, {
    cmd = { vim.env.HOME .. '/.nix-profile/bin/bufls' },
}))

lspconfig['sourcekit'].setup(vim.tbl_extend('error', setup, {
    cmd = { 'sourcekit-lsp' },
    filetypes = {'swift', 'objective-c', 'objective-cpp'},
    root_dir = lspconfig.util.root_pattern('Package.swift', '.git'),
    single_file_support = true,
}))

rust_tools.setup({
    tools = { inlay_hints = { auto = false } },
    server = vim.tbl_extend('force', setup, {
        on_attach = function(client, bufnr)
            vim.api.nvim_buf_set_option(
                bufnr,
                'formatexpr',
                'v:lua.vim.lsp.formatexpr(#{timeout_ms:250})'
            )
            return on_attach(client, bufnr)
        end,
        cmd = { vim.env.HOME .. '/.nix-profile/bin/rust-analyzer' },
        settings = {
            ['rust-analyzer'] = {
                rustfmt = {
                    rangeFormatting = true,
                    extraArgs = { "+nightly" },
                },
                cargo = { buildScripts = { enable = true } }
            },
        },
    }),
})

cmp.setup({
    snippet = {
        expand = function(args)
            vim.fn["UltiSnips#Anon"](args.body)
        end,
    },
    sources = {
        { name = 'nvim_lsp_signature_help' },
        { name = 'nvim_lsp' },
        { name = 'buffer', max_item_count = 10 },
        { name = 'path' },
        {
            name = 'tmux',
            max_item_count = 5,
            -- not working yet: https://github.com/andersevenrud/cmp-tmux/issues/27
            option = { trigger_characters = {}, keyword_pattern = [[\w{4,}]] },
            priority = 0,
        },
        { name = 'ultisnips' },
    },
    window = { documentation = { max_width = 79 } },
    completion = { autocomplete = {} },
    preselect = cmp.PreselectMode.None,
    mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.mapping.scroll_docs(4)
            else
                fallback()
            end
        end),
        ['<C-X><C-O>'] = cmp.mapping.complete(),
        ['<C-Tab>'] = cmp.mapping.complete({config = { sources = { name = 'vsnip'}}}),
        ['<Tab>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
        }),
    }),
})


cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = { { name = 'buffer' } }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = vim.tbl_extend('force', cmp.mapping.preset.cmdline(), {
        ['<Tab>'] = cmp.mapping({
            c = function()
                if cmp.visible() then
                    cmp.select_next_item()
                else
                    cmp.complete()
                    cmp.select_next_item()
                end
            end,
        })
    }),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        {
            name = 'cmdline',
            option = { ignore_cmds = { "Man", "!" }, },
        }

    })
})

require('neodev').setup({})
require("fidget").setup({}) -- nvim-lsp progress
