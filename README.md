CodeView5
=========
Eonil, 2019.

An alternative option of Cocoa view to edit code-like text. 



Change Tracking
---------------------
There are two change trackings .

- In `CodeEditing.timeline`.
- In `CodeStorage.timeline`. You can access this through `CodeEditing.storage.timeline`.

At `CodeEditing` level, timeline tracks undo/redo history with unique version number.
For any changes, it makes a new point in timeline with new version number.
Therefore, if you have same version number, it means same text content. 
Otherwise, text content has been changed.
`CodeEditing` level timeline stores `CodeStorage` snapshots.
You cannot track each changes here.

At `CodeStorage` level, timeline tracks each changes in content. 
It tracks all changes in text content individually.
You can correctly track changes.

For both cases, timeline DO NOT track changes in selection. 
It tracks only changes in text content. Selections won't be regarded as content.
Selection is stored in `CodeTextStorage` to keep latest selection information
when we make snapshot.

Anyway, `CodeEditing` removes such changes when they take snapshot
of `CodeStorage`. This is because that can provide wrong information 
as `CodeEditing` can swap snapshots for undo/redo.
Therefore, you need to take care on *version number* of each snapshot.

- If version number is same, there's no change.
- If version number is different,
    - and `CodeStorage.timeline` is empty, iI's whole content replacement.
    - If `CodeStorage.timeline` is not empty, it tells you the individual changes.











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
- **Server/client structure to be a part of bigger REPL structure.**

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






`CodeStorage` vs `CodeTextStorage`
-------------------------------------
`CodeStorage` contains all data to build a state of a `CodeView`.
It contains configuration, storage and selection.
`CodeTextStorage` contains only textual data. 
You can think of relationship like this.

    source = configuration + storage + selection
    
`CodeStorage` also processes editing command.
It converts editing commands into modifications 
on line collections in storage.

`CodeStorage` is always a snapshot state of a moment.
As `CodeStorage` is value-semantic, you can freely copy,
replace and update them independently without worrying
about unexpected mutations.

`CodeView` supports modification command from external 
world by exchanging I/O messages, and you are supposed
to pass `CodeStorage` value as a new state.



Undo/Redo and `CodeTimeline`
--------------------------------------
Undo/redo support is implemented using `CodeTimeline`.
`CodeTimeline` simply stores copy of all `CodeStorage`s 
for each editing moments, and just swaps according to 
undo/redo command.
`CodeTimeline` is also pre value-semantic. There's no
reference attached. You can copy, update and replace
them as much as you want.

`CodeView` keeps one timline and does not expose it to
public.






License & Credit
--------------------
Copyright(C) Eonil & Henry, 2019. All rights reserved.
This code is licensed under "MIT LIcense".
