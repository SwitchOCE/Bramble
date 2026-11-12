# Owner direction: large files are rare

Said by the owner in chat on 12 November 2026, reviewing the Cloudflare R2 storage for large files.

On 7, I just want to get an understanding for object lifecycle and how likely we are to push past the free tier limit. What are the risks there? Are there many?

And can we set up some sort of rule that large files shouldn't be going there unless they're very relevant, and then they should probably be cleaned up. 300 megabytes for a file is crazy to me. If we need it for something because it's really important, absolutely. But they should be used sparingly. When they're going to significantly improve the result, we should absolutely use them. Otherwise, find a way of keeping it small.

*[Editor notes:*
- *"7" is the review finding that the storage docs didn't say how close the account is to the free tier.*
- *The agent drafted the `CLAUDE.md` rule "Large files are rare" from this, and the owner approved it ("Yes, all of it"), along with a `prune` command for the cleanup and size reminders in `push`.]*
