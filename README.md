# Plugin.jl
This library provides a mechanism for packages to advertise components (plugins) it provides to be discovered and used by other code.

It is designed to integrate with the standard Julia packaging by introducing a new plugins section into **Project.toml**.

This is primarily required when you have an application or library that wants to automatically *discover* all plugins available, rather than needing an explicit registration.

## Package Advertising

Packages can register expressions for discovery by adding a section into **Project.toml**
with the appropriate details.

Suppose that we have a module **Foo** with a method **dummy_plugin** that we want
to get called to do our registration.

```julia
module Foo

function dummy_plugin()
  println("Dummy plugin registration complete!")
end
```

Then we need to add the following into our **Project.toml** to expose this with the name **dummy**. Note that this is just the expression you would want to be called after *using Foo* had been executed.

```toml
[plugins.myapp]
dummy = "Foo.dummy_plugin()"
```

## Package Discovery

Now in our core library we want to pick up all the packages which are advertising
the **myapp**. This can be done with this package.

```julia
using Plugin

for plugin in plugins("myapp")
  println("loading plugin $(plugin.name)...")
  load(plugin)
end
```

This will search all the package dependencies given the current manifest, but will only load those which have explicitly exposed themselves for the requested plugin.
