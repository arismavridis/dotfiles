return {
    'saghen/blink.cmp',
    -- use a release tag to download pre-built binaries
    version = '1.*',
    -- AND/OR build from source
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    dependencies = { 'L3MON4D3/LuaSnip', version = 'v2.*' },
    opts = {
        -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
        -- 'super-tab' for mappings similar to vscode (tab to accept)
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- All presets have the following mappings:
        -- C-space: Open menu or open docs if already open
        -- C-n/C-p or Up/Down: Select next/previous item
        -- C-e: Hide menu
        -- C-k: Toggle signature help (if signature.enabled = true)
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        keymap = {
            preset = 'enter',
            ['<Tab>'] = {
                function(cmp)
                    -- If there's a bracket in front of cursor, skip past it
                    local col = vim.fn.col(".")
                    local line = vim.fn.getline(".")
                    local rest = line:sub(col)
                    local spaces, closer = rest:match("^(%s*)([%]%}\"'`)])")

                    if closer then
                        vim.api.nvim_feedkeys(
                            vim.api.nvim_replace_termcodes(
                                string.rep("<Right>", #spaces + 1),
                                true, true, true
                            ),
                            "n",
                            true
                        )
                        return true
                    end
                    -- no bracket to skip: fall through to the rest of the chain
                end,
                'snippet_forward',
                'select_next',
                'fallback',
            },
        },

        appearance = {
            -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
            -- Adjusts spacing to ensure icons are aligned
            nerd_font_variant = 'mono',
            kind_icons = {
                NtSource = '󱉟',
                NtTag = '󰓻',
            },
        },

        completion = {
            documentation = { auto_show = true },
            ghost_text = { enabled = false },
            list = { selection = { preselect = true, }, },
        },

        snippets = { preset = 'luasnip' },
        -- Default list of enabled providers defined so that you can extend it
        -- elsewhere in your config, without redefining it, due to `opts_extend`
        sources = {
            -- Keep your default sources enabled
            default = { "lsp", "path", "snippets", "buffer", "sources" },
            providers = {
                path = { score_offset = 3 },
                lsp = { score_offset = 2 },
                snippets = { score_offset = 1 },
                buffer = {
                    score_offset = -100,
                    min_keyword_length = 3,
                },
                sources = {
                    name = 'nt',
                    module = 'misc.nt_cmp',
                },
            },
        },
        cmdline = {
            keymap = {
                preset = 'inherit',
                ['<CR>'] = { 'accept_and_enter', 'fallback' },
            },
            completion = {
                menu = { auto_show = true },
                list = {
                    selection = {
                        preselect = false,
                        auto_insert = true,
                    },
                },
            },
        },

        -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
        -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
        -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
        fuzzy = { implementation = "prefer_rust_with_warning" }
    },
    opts_extend = { "sources.default" }
}
