-- To debug :lua print(vim.inspect(vim.lsp.get_client_by_id(1).config))

local lspconfig = require('lspconfig');
local cmp = require("cmp")
local navic = require("nvim-navic")
local navbuddy = require("nvim-navbuddy")
local inlayhints = require('lsp-inlayhints')
local telescope = require('telescope.builtin')

local servers = {
    'pyright',
    'tsserver',
    'rust_analyzer',
    'nil_ls',
    'bashls',
    'dockerls',
    'docker_compose_language_service',
    'jsonls',
    'yamlls',
    'volar',
    'rome',
    'gopls',
};

inlayhints.setup()
require('mason').setup();
require('mason-lspconfig').setup({
    ensure_installed = servers,
    automatic_installation = true,
})

require('lint').linters_by_ft = {
    -- javascript = {'eslint_d'},
    python = {'ruff'},
}
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function() require("lint").try_lint() end,
})

local on_attach = function(client, bufnr)
    local opts = { silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gD', telescope.lsp_type_definitions, opts)
    vim.keymap.set('n', 'gd', telescope.lsp_definitions, opts)
    vim.keymap.set('n', 'gI', telescope.lsp_implementations, opts)
    vim.keymap.set('n', 'gr', telescope.lsp_references, opts)
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
        navbuddy.attach(client, bufnr)
    end

    -- lsp client somehow does not send textDocument/rangeFormatting
    if client.server_capabilities.documentRangeFormattingProvider then
        local fn = function() vim.lsp.buf.format({ async = true }) end
        vim.keymap.set('v', 'gq', fn, opts)
    end

    inlayhints.on_attach(client, bufnr)
end


-- Recently lsp client of neovim watch files by polling. This is embarrassing :/
-- https://github.com/neovim/neovim/issues/23291
-- https://github.com/neovim/neovim/issues/23725#issuecomment-1561364086
-- :lua =vim.lsp.get_active_clients()[1].server_capabilities
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


local rt = require("rust-tools")
rt.setup({
  server = {
    on_attach = function(client, bufnr)
      client.server_capabilities.documentRangeFormattingProvider = true;

      -- Hover actions
      vim.keymap.set("n", "<space>", rt.hover_actions.hover_actions, { buffer = bufnr })
      -- Code action groups
      vim.keymap.set("n", "<Leader>ac", rt.code_action_group.code_action_group, { buffer = bufnr })
      on_attach(client, bufnr)
    end,
    cmd = { vim.env.HOME .. '/.nix-profile/bin/rust-analyzer' },
    settings = {
      ['rust-analyzer'] = {
        rustfmt = {
          -- require `rustfmt` binary
          overrideCommand = { "rustfmt", "--" },
          rangeFormatting = { enable = true },
          extraArgs = { "+nightly" },
        },
        cargo = { buildScripts = { enable = true } }
      },
    },
  },
  dap = {
    adapter = (function()
      local exe = vim.fn.resolve(vim.fn.exepath('codelldb'))
      local dir = vim.fn.fnamemodify(exe, ':h')
      local lib = vim.fn.resolve(dir .. '/../lldb/lib/liblldb.so')
      return require('rust-tools.dap').get_codelldb_adapter(exe, lib)
    end)()
  },
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
