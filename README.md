# pangea

## Configuration

### Configuration Locations

Configuration behavior is merge behavior of directories in top/down order listed.

- /opt/share/pangea.<ext>
- /etc/pangea/pangea.<ext>
- /etc/pangea/conf.d/\*.<ext>
- $XDG_CONFIG_HOME/pangea/pangea.<ext>
- $XDG_CONFIG_HOME/pangea/conf.d/\*.<ext>
- pangea.<ext>
- pangea/config.d/\*.<ext>
- .pangea.<ext>
- .pangea/config.d/\*.<ext>
- StitchFile

obs.

<ext> is enum rb|json|yml|yaml|toml|nix

### Configuration Notes

Top level structure is a namespace

namespaces can receive terraform commands
namespaces have multiple projects within them
projects represent a single instance of state
projects can have multiple modules.
modules pack ruby code together to be run on a single projects
a module may be used in multiple projects but a project has a direct association to a namespace
a project cannot be present in multiple namespaces.

modules can be nested indefinitely.
its modules all the way down.

you can have modules provide only ruby functions.
you can have modules provide resources.
you can have modules call other modules.

if something is runnable then it can receive terraform commands
the smallest runnable item is a project
namespaces are also runnable

flows are groups of runnable terraform commands in a DAG
whose nodes are either namespace or namespace.project

#### Namespace

namespace is a DAG with fixed nodes

```
namespace -> site -> project
```

a project is the smallest component which can receive tf commands
called like namespace.site.project
