Work Log
===========
- Ordered descendingly.
- Newer one at up.
- Older one at bottom.





Abandon Server/Client Structure
----------------------------------------
I just realized that I don't have to implement server/client structure here.
It could be implemented in a wrapper view of `CodeView`.
Though the server would be nothing more than just a message routing channel...



Conflict, Priority & Synchronization
------------------------------------
I didn't expect this situation. I realized that I need serious synchronization
after I converted this into asynchronous server/client structure.

The best known way to solve this is CRDT, but I don't want it now.
Just I don't want to put too much energy on bootstraping implementation.
Therefore, I choose the simplest solution.

- Run whole server soley in main thread.
- User-interaction client `CodeView` runs in main thread only.
- Therefore, synchronization issue won't happen.
- Messages from other client (e.g. RLS) will be transferred to main thread.
- Changes made by RLS will be sent to `CodeView` client synchronosuly.
- Therefore, no issue.

I know this is suboptimal, or inferior solution.
But this is the most time-saving solution IMO.




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

It seems bottleneck has been moved to another place.
- Inefficient function call to static linked b-tree libraries.
  
  > This has been proven as non-critical.
  
- Strict instantiation of `String` for each lines.

  > This was a big deal. 

- Baked-in grapheme-cluster validation behavior in `String`.

> This has been proven not a problem. It was my misunderstanding.


I applied these solutions.

- Use `Substring` instead of `String`. This provided huge performance gain.
  But at same time, whole source base storage string will survive if any fragment is referenced.
  It seems reinstantiation of base storage String regular basis is required.

Now loading of 50,000 line of text take 1 second.
Though still far slower than Xi-Editor, now it's comparable to Xcode 11 (GM). 
It's very difficult to archive Xi-Editor level base performance. It's mysterious to me.
