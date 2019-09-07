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
  
Implemented Features
--------------------------
- Basic text editing.
- Breakpoint marker editing.
- Select by mouse.
- Jump to line. (scrolling)
- Undo/redo.
- Text snapshot import & export.
- Copy & paste.
  
Non-Goal Features
----------------------
- Tracking nesting structures.
- Asynchronous editing.
- Line number rendering.

Non-Goals
-----------------
- Word wrap.
- Right-to-left text rendering. (such as Arabic)
- Vertical text rendering.

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



Performance
----------------
Current implementation shows about 10x or more slower than Xcode
text editor. Pasting 50,000 line of code took 20 seconds on my laptop
where Xcode took about 2 second. I think 10x slowness seems to be
quite good enough for quick bootstrapping implementation.

Loading of 50,000 lines.
- CodeView5: about 20 seconds.
- Xcode: about 2 seconds.
- Xi-Editor: less than 0.1 second.

To prevent undesired long waiting, I strongly recommend you to warn
end-user if they are trying to load over 1MiB text files.

Major reason of slowness is unnecessarily duplicated multiple 
Binary/B-Trees. (`CodeStorage`). Once I removed duplication
it loaded 50,000 lines in 6-7 seconds, that is 3-4x faster than base.
There're many room for improvement, but most of them requires
painful algorithm implementations and testing, therefore I do not
do that at this moment. Suggested optimizations would require
these components.

If Xi-Core gets ready, I'd move on to there.


License & Credit
--------------------
Copyright(C) Eonil & Henry, 2019. All rights reserved.
This code is licensed under "MIT LIcense".
