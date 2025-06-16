A [fzf](https://github.com/junegunn/fzf)-based **journaling, notes, and tasks** application with CalDav support.
If you are interested in this, then you may also be interested in the
corresponding calendar application
[fzf-vcal](https://github.com/baumea/fzf-vcal).

Description and Use Case
------------------------
This application allows for a keyboard-controlled maneuvering of your notes, journal entries, and tasks.
These entries are stored as [iCalendar](https://datatracker.ietf.org/doc/html/rfc5545) files of the type `VJOURNAL` and `VTODO`.

For instance, you could use this application as a terminal-based counterpart of [jtx Board](https://jtx.techbee.at/) in a setup
with a CalDav server, such as [Radicale](https://radicale.org/), and a synchronization tool like [vdirsyncer](http://vdirsyncer.pimutils.org/).

Installation
------------

### Manual

Run `./scripts/build.sh`, then copy `fzf-vjour` to your preferred location, e.g., `~/.local/bin`, and make it executable.

### Requirements
This is a POSIX script with inline `awk` elements.
Make sure you have [fzf](https://github.com/junegunn/fzf) installed.
I also suggest to install [batcat](https://github.com/sharkdp/bat) for colorful previews.

### Arch Linux

```bash
yay -S fzf-vjour-git
```

Configuration
--------------
This application is configured with a file located at `$HOME/.config/fzf-vjour/config`.
The entry `ROOT` specifies the root directory of your journal and note entries.
This directory may contain several subfolders, called _collections_.
The entry `COLLECTION_LABELS` is a `;`-delimited list, where each item specifies a subfolder and a label (see example below).
In the application, the user sees the collection labels instead of the collection names.
This is particularly useful, because some servers use randomly generated names.
Finally, a third entry `SYNC_CMD` specifies the command to be executed for synchronizing. 

Consider the following example:
```sh
ROOT=~/.journal/
COLLECTION_LABELS="745ae7a0-d723-4cd8-80c4-75f52f5b7d90=shared 👫🏼;12cacb18-d3e1-4ad4-a1d0-e5b209012e85=work   💼;"
SYNC_CMD="vdirsyncer sync journals"
```


Here the files are stored in
`~/.journal/12cacb18-d3e1-4ad4-a1d0-e5b209012e85` (work-related entries)
and
`~/.journal/745ae7a0-d723-4cd8-80c4-75f52f5b7d90` (shared collection).

This configuration will work well with a `vdirsyncer` configuration such as 
```confini
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

Usage
-----
Use the default `fzf` keys to navigate your notes, e.g., `ctrl-j` and `ctrl-k` for going down/up in the list.
In addition, there are the following keybindings:
| Key | Action |
| --- | ------ |
| `enter` | Open note/journal/task in your `$EDITOR` |
| `ctrl-alt-d` | Delete the seleted entry |
| `ctrl-n` | Make a new entry |
| `ctrl-r` | Refresh the view |
| `ctrl-s` | Run the synchronization command |
| `ctrl-x` | Toggle task completion |
| `alt-up` | Increase task priority |
| `alt-down` | Decrease task priority |
| `alt-0` | Default view: Journal, notes, and _open_ tasks |
| `alt-1` | Display journal entries |
| `alt-2` | Display notes |
| `alt-3` | Display all tasks |

You may also invoke the script with `--help` to see further command-line options. 

License
-------
This project is licensed under the [MIT License](./LICENSE).
