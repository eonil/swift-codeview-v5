
Rough description of overall architecture.
This is outdated, but still makes sense.





`CodeView` is buildt in simple REPL.
- Read: `typing` manages end-user's typing input with IME support.
- Eval: `state` is a full value-semantic state and modifier around it.
- Print: Drawing method renders current `state`.

Typing
------
- This is pure input.
- Scans end-user intentions.
- Scanned result will be sent to `state` as messages.
- Typing is an independent actor.

State
-----
- This is fully value semantic. No shared mutable reference.
- This is referentially transparent. Same input produces same output. No global state.
- State is not an independent actor. Processing is done by simple function call.
- State is pure value & functions. There's no concept of event.

Rendering
---------
- This is a pure output. Renders `source` to screen.
- You can consider rendering as a transformation of `state` to an opaque result value.
- That result you cannot access.
- In this case, `state` itself is the value to render.
- Renderering does not involve any an independent actor.
- Rendering is done by simple function call.

Design Choicese
---------------
- Prefer value-semantic and pure-functions over independent actor.
- Prefer function call over message passing.
- Prefer forward message passing over backward message passing (event emission).

Synchronization
---------------
Most control commands does not need synchronization
as they are designed as oneway streaming write commands
and ultimately can be performed on any state.
But some commands require bi-directional read/write,
therefore they need synchronization.
- Copy
- Cut
- Paste
- Undo
- Redo
Performing these commands with unsynchronized state can produce wrong result.
To support synchronization, we use "process-key"s. As each control command
This is especially important for your app's menu handling.
You also manage your app's menu to be called while this view is synchronized.
Use `isSynchronized` property to check whether this view is synchronized.
To prevent accidental such situation, this view crashes if you pass any control message
when unsynchronized.
