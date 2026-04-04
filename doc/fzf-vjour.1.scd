fzf-vjour(1)

# NAME

fzf-vjour - fzf-based *journaling, notes, and tasks* application

# SYNOPSIS

fzf-vjour [options...]

# DESCRIPTION

fzf-vjour is a fzf-based *journaling, notes, and tasks* application with CalDav support.

This application allows for a keyboard-controlled maneuvering of your notes, journal entries, and tasks. These entries  are  stored  as  *iCalendar* (_https://datatracker.ietf.org/doc/html/rfc5545_), files of the type _VJOURNAL_ and _VTODO_.

For instance, you could use this application as a terminal-based counterpart of *jtx Board* (_https://jtx.techbee.at/_), in a setup with a CalDav server, such as *Radicale* (_https://radicale.org/_), and a synchronization tool like *vdirsyncer* (_http://vdirsyncer.pimutils.org/_).

# OPTIONS

*--help*++
Show this help and exit.

Git integration:

*--git-init*++
Activate git usage and exit.

*--git* <command>++
Start with the specified filter.

Interactive Mode:

*--new [FILTER...]*++
Create new entry interactively and start.

*[FILTER...]*++
Start with the specified filter.

Non-Interactive Mode:

*--list [FILTER...]*++
List entries and exit.

*add-note* <summary> *[<due>]*++
Read task from stdin and add it with the specified summary and optional due date.

*add-jour* <summary> *[<date>]*++
Read journal from stdin and add it with the specified summary and optional due date.

*--collection* <nr>++
Select collection to which the note, task, or journal entry is added non-interactively. The argument _<nr>_ is the ordinal describing the collection. It defaults to the starting value of *1*.

# FILTER

You may specify any of these filters. Filters can be negated using the *--no-...* versions, e.g., *--no-tasks*. Multiple filters are applied in conjuction. By default, the filter *--no-completed* is used. Note that *--no-completed* is not the same as *--open*, and similarly, *--no-open* is not the same as *--completed*.

*--tasks*++
Show tasks only.

*--notes*++
Show notes only.

*--journal*++
Show journal only.

*--completed*++
Show completed tasks only.

*--open*++
Show open tasks only.

*--filter* <query>++
Specify custom query.

# KEYBOARD SHORTCUTS

[[ *Key*
:- *Action*
|  _Enter_
:[ Open note/journal/task in you *$EDITOR*
|  _Ctrl+Alt+d_
:[ Delete the selected entry
|  _Ctrl+n_
:[ Make a new entry
|  _Ctrl+r_
:[ Refresh the view
|  _Ctrl+s_
:[ Run the synchronization command
|  _Ctrl+x_
:[ Toggle task completion
|  _Alt+Up_
:[ Increase task priority
|  _Alt+Down_
:[ Decrease task priority
|  _Ctrl+a_
:[ Open attachments view
|  _Ctrl+t_
:[ Filter by category
|  _Alt+v_
:[ View base iCalendar file
|  _Alt+0_
:[ Default view: Journal, notes, and *open* tasks
|  _Alt+j_
:[ Display journal entries
|  _Alt+n_
:[ Display notes
|  _Alt+t_
:[ Display all tasks
|  _Alt+[1-9]_
:[ Display first, second, ... collection
|  _Alt+w_
:[ Toggle line-wrap in preview
|  _Ctrl+d_
:[ Scroll down in preview
|  _Ctrl+u_
:[ Scroll up in preview

In the attachment view, you may use the following keys:

[[ *Key*
:- *Action*
|  _Enter_
:[ Open attachment
|  _w_
:[ Toggle line wrap
|  _Ctrl+a_
:[ Add attachment
|  _Ctrl+Alt+d_
:[ Delete attachment

# ENTRY TYPES

This applications, as well as *jtx Board* (_https://jtx.techbee.at/_), distinguishes among three entry types.

*Notes* are _VJOURNAL_ entries without dates. Here is an example of a note:

```
# Related research
> research

Lorem ipsum
```

*Journal* entries are notes associated to a date (typically to today). An example of a journal entry is:

```
::: |> today <!-- specify the date for journal entries -->
# Alignment for Bell experiment
> lab

Lorem ipsum
```

*Tasks* are _VTODO_ entries with an optional due date. An example of a task with a due date is:

```
::: <| next Sunday
# Finish manuscript
> research
```

Another example of a task without due date is

```
::: <|
# Acquire Epist. Lett
> research
```

# EXAMPLE

```
fzf-vjour --git log
fzf-vjour --new
fzf-vjour --journal
fzf-vjour --no-tasks --filter "Beauregard"
fzf-vjour --list --open
fzf-vjour --add-task "Improve code to respect timezone information" "next month"
cat proof.tex | fzf-vjour --add-journal "Proof of Fixed-point Theorem" --collection 2
```

# AUTHORS

Maintained  by  Ämin Baumeler <amin@indyfac.ch>, who is assisted by other open-source contributors. For more information about mako development, see https://github.com/baumea/fzf-vjour.

# SEE ALSO

fzf-vjour(5)
