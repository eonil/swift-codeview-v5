

Design Overhaul
---------------------
2019-09-19
- Separate text processing engine from I/O.
- Refit things for REPL structure.
- All text processing of `CodeView5` is done in `CodeSource`.
- No more work is needed.
- How about undo/redo?
    - That is done at timeline level.
- How about IME?
    - That state is currently hidden to public.
    - IME is part of input state. Not really a part of text processing.
    - More specifically, IME is part of `TextTyping` class.
    - Renderer is responsible to composite `CodeSource` and IME state.
    
    
    
Lessons
------------
- It's okay to have many readers, but there must be only one mutator method.
    - Because it's very important to track mutations.
    - It's very easy to track mutations if we have only one central route to mutate state.
    - Otherwise, tracking mutation is simply non-sense.
- Only one text replacement be performed at once to track change correctly.
    - If we perform multiple replacement at once, selection informations will be lost between replacements.
    - That means it's impossible to scan changes without performing diff.
    - But if there's only one change with selection information, it's easy to scan changes.
