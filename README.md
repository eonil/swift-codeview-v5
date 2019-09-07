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
