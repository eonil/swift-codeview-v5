CodeView5
=========
Eonil, 2019.

An alternative option of Cocoa view to edit code-like text. 



Design Choices
-------------------
- Aims for best maintainanceability. Simplicity over performance.
- Aims "good enough" performance. Not best performance.
- No word-wrap. 
- No "complete" level of IME support. I implemented IME support, but do not invest much time on it.
- This is a quick bootstrapping implementation. Do not try to be perfect.

- Unidirectional I/O. User input simply gets delivered to main loop
  and makes change in data source, and changed source will be delivered
  to renderer. macOS IME requires immediate
  
Supported Features
-----------------------
- Basic text editing.
- Breakpoint marker editing.
- Select by mouse.

Planned Features
----------------------
- Jump to line. (scrolling)
- Undo/redo.
- Text snapshot import & export.
- Copy & paste.
  
Desired but Avoided Goals
-------------------------------
- Tracking nesting structures.
- Asynchronous editing.
- Line number rendering.

Non-Goals
-----------------
- Word wrap.

Designed Limits
-------------------
- Maximum line count: `CodeLineKey.max`. (a.k.a. `Int32` at this point)


Unidirectional I/O & IME
----------------------------
- macOS IME requires synchronous access to whole source text at any time.
- Asynchronous I/O requires flawless conflict resolution and it's complicated.
  I avoid it. Just wait for *Xi-Editor* for this. 
- `CodeView` retains and modifies base source state according to user input.
- `CodeView` emits modified source state.
- External owner can modify the source and push to `CodeView` back.
- `CodeView` can reject external push.

Independent Actor
----------------------
- `CodeView` is an independent actor rather than a passive control surface or renderer.
- `CodeView` keeps base source state. This source is the origin.
- `CodeView` modifies base source state according to user input.
- `CodeView` emits source state to external observer.
- `CodeView` accepts source state push from external controller.
- `CodeView` can reject external push. Internal base source takes priority.






`CodeSource` vs `CodeStorage`
-------------------------------------
`CodeSource` contains all data to build a state of a `CodeView`.
It contains configuration, storage and selection.
`CodeStorage` contains only textual data. 
You can think of relationship like this.

    source = configuration + storage + selection
    
`CodeSource` also processes editing command.
It converts editing commands into modifications 
on line collections in storage.

`CodeSource` is always a snapshot state of a moment.
As `CodeSource` is value-semantic, you can freely copy,
replace and update them independently without worrying
about unexpected mutations.

`CodeView` supports modification command from external 
world by exchanging I/O messages, and you are supposed
to pass `CodeSource` value as a new state.



Undo/Redo and `CodeTimeline`
--------------------------------------
Undo/redo support is implemented using `CodeTimeline`.
`CodeTimeline` simply stores copy of all `CodeSource`s 
for each editing moments, and just swaps according to 
undo/redo command.
`CodeTimeline` is also pre value-semantic. There's no
reference attached. You can copy, update and replace
them as much as you want.

`CodeView` keeps one timline and does not expose it to
public.
