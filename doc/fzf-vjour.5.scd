fzf-vjour(5)

# NAME

fzf-vjour - config file.

# DESCRIPTION

This application is configured with a file located at *$HOME/.config/fzf-vjour/config*.

Example:

```
ROOT=~/.journal/
COLLECTION_LABELS="745ae7a0-d723-4cd8-80c4-75f52f5b7d90=shared 👫🏼;12cacb18-d3e1-4ad4-a1d0-e5b209012e85=work 💼;"
SYNC_CMD="vdirsyncer sync journals"
```

Here the files are stored in *~/.journal/12cacb18-d3e1-4ad4-a1d0-e5b209012e85* (work-related entries) and *~/.journal/745ae7a0-d723-4cd8-80c4-75f52f5b7d90* (shared collection).

This configuration will work well with a `vdirsyncer` configuration such as:

```
[pair journals]
a = "local"
b = "remote"
collections = ["from a", "from b"]

[storage local]
type = "filesystem"
fileext = ".ics"
path = "~/.journal"

[storage remote]
type = "caldav"
item_types = ["VJOURNAL", "VTODO"]
...
```

For more information about *vdirsyncer* configuration, see *vdirsyncer(1)*

# CONFIGURATION

The entry *ROOT* specifies the root directory of your journal and note entries. This directory may contain several subfolders, called _collections_.

The entry *COLLECTION_LABELS* is a _;_-delimited list, where each item specifies a subfolder and a label (see example below). In the application, the user sees the collection labels instead of the collection names. This is particularly useful, because some servers use randomly generated names.

Finally, a third entry *SYNC_CMD* specifies the command to be executed for synchronizing. 

You may override any of the following parameters (shown with default values) in the configuration file:

```
FLAG_OPEN=🔲
FLAG_COMPLETED=✅
FLAG_JOURNAL=📘
FLAG_NOTE=🗒️
FLAG_PRIORITY=❗
FLAG_ATTACHMENT=🔗

STYLE_COLLECTION="$FAINT$WHITE"
STYLE_DATE="$CYAN"
STYLE_SUMMARY="$GREEN"
STYLE_EXPIRED="$RED"
STYLE_CATEGORY="$WHITE"
```

By default, *fzf-vjour* sets a descriptive terminal title.

This can be bypassed by specifying *SET_TERMINAL_TITLE*=_"no"_ in the configuration file.

# ENVIRONMENT

You may also specify the location of the configuration file with the environment *CONFIGFILE*.

# AUTHORS

Maintained  by  Ämin Baumeler <amin@indyfac.ch>, who is assisted by other open-source contributors. For more information about mako development, see https://github.com/baumea/fzf-vjour.

# SEE ALSO

fzf-vjour(1)
