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
- REPL based. In other words, *unidirectional I/O loop*. User input simply gets delivered to main loop
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
- Line number rendering.
- Change notifications.



Non-Goals
-------------
- Tracking of nesting structures.
- Asynchronous editing.
- Word wrap.
- Proper right-to-left text layout/rendering support. (such as Arabic/Hebrew)
- Vertical text rendering.



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
At first, `CodeView5` was 10-20x slower than Xcode, 
and 100-200x slower than Xi-Editor. 

Loading of 50,000 lines. Measured manually by counting seconds.
- CodeView5: about 20 seconds.
- Xcode: about 2 seconds.
- Xi-Editor: less than 0.1 second.

Major causes of current slowness. was duplicated b-tree structures
in `CodeStorage`. I removed them and now this is 2x faster.

- CodeView5: about 10 seconds.
- Xcode: about 2 seconds.
- Xi-Editor: less than 0.1 second.

It took 2 seconds to load 10,000 lines of code.
I think this is enough for bootstrapping implementation.

Now bottlenecks are coming from these places.
- Inefficient function call to static linked b-tree libraries.
- Strict instantiation of `String` for each lines. (about 25%)
- Baked-in grapheme-cluster validation behavior in `String`. (about 25%)

Possible solutions.
- Use `Substring` to avoid `String` instantiation. But this doesn't solve validation cost.
- Embed b-tree code directly in module instead of linking.
- Make a new, sharable UTF-8 string container. 
- Use byte offset instead of opaque `String.Index` as character index for O(1) access.

Once I tried using first two solutions, loading of 50,000 line code took
2-3 seconds. That is comparable to Xcode. But I need simpler and easier codebase
for better maintainance, therefore such optimizations has been removed.

The problem is it's very difficult to archive Xi-Editor level performance with Swift
as Swift requires ref-type overhead and lacks low-level memory handling in safe way.
It would be better to have an approach like Xi-Editor or using Xi-Editor when ready.



License & Credit
--------------------
Copyright(C) Eonil & Henry, 2019. All rights reserved.
This code is licensed under "MIT LIcense".
