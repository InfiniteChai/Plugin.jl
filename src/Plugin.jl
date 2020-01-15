module Plugin

import Pkg
import UUIDs
import Pkg.TOML
using Suppressor: @suppress_err

export plugins, load

struct PluginIterator
    name::String
    ctx::Pkg.Types.Context
    deps::Vector{UUIDs.UUID}
end

struct PluginEntry
    package::Symbol
    name::String
    expr::Expr
end

function load(plugin::PluginEntry)
    importexpr = Expr(:using, Expr(:., plugin.package))
    suppressed = Expr(:macrocall, Symbol("@suppress_err"), " ", importexpr)
    code = :($suppressed; $(plugin.expr))
    eval(code)
end

Base.IteratorSize(::Type{PluginIterator}) = Base.SizeUnknown()

function plugins(name::String)
    ctx = Pkg.Types.Context()
    deps = collect(keys(ctx.env.manifest))
    PluginIterator(name, ctx, deps)
end

function plugins(entry::Pkg.Types.PackageEntry, uuid::UUIDs.UUID)
    entry.tree_hash !== nothing || return nothing
    pkg_dir = Pkg.Operations.find_installed(entry.name, uuid, entry.tree_hash)
    toml_path = joinpath(pkg_dir, "Project.toml")
    isfile(toml_path) || return nothing
    get(TOML.parsefile(toml_path), "plugins", nothing)
end

function Base.iterate(iter::PluginIterator, state = (1, []))
    (count, cases) = state
    if length(cases) > 0
        return cases[1], (count, cases[2:end])
    end

    (entry, target_plugins) = (nothing, nothing)

    while target_plugins === nothing || length(target_plugins) == 0
        if length(iter.deps) < count
            return nothing
        end

        uuid = iter.deps[count]
        entry = iter.ctx.env.manifest[uuid]
        results = plugins(entry, uuid)

        if results !== nothing
            target_plugins = get(results, iter.name, nothing)
        end
        count = count + 1
    end

    cases = [PluginEntry(Symbol(entry.name), k, Meta.parse(v)) for (k,v) in target_plugins]

    return cases[1], (count, cases[2:end])
end

end # module
