# Commitment portraits

8 Nov 2026, gameplay baseline `b872a6b`, branch `ideation/commit`.

The three newly live cards previously used their tribe fallback art. They now have separate bespoke portraits, generated with the built-in imagegen tool and exported through `tools/art/portraits.py` to 512×512 JPEG at quality 82:

- [Fairy Monarch](../../../assets/portraits/fairy_monarch.jpg): thorn-crowned woodland fairy king, mushroom sceptre and Ring.
- [Elder Ooze](../../../assets/portraits/elder_ooze.jpg): venerable custard-and-plum pudding welcoming two smaller puddings out.
- [Moss Ooze](../../../assets/portraits/moss_ooze.jpg): moss jelly sharing a spell sparkle with the dollop inside.

[Prompt set](../../../tools/art/prompts/commitment-portraits.txt). The existing Queen of Elfland and Aunt Aspic portraits informed the flat comic-album style. Original generated PNGs remain in `build/art/commit-portraits/` and the tool's generated-image directory; final game assets are in the repository. No gameplay, stats, card text or Nest rule changed.

## Validation

- Inspected the [portrait contact sheet](commit-portraits/contact.jpg) and all three originals: distinct silhouettes, clear faces, no labels/frames/watermarks, consistent outlines and tribe palettes.
- Imported all three through Godot; own-art lookup now resolves `assets/portraits/<card_id>.jpg`. Cleared the pending-art manifest.
- Existing portrait suite: **5/5 tests, 285 assertions passed**. It verifies actual tile/detail/hero texture paths rather than accepting a missing portrait fallback for these cards.
- Rendered all three in the actual card reader at the 1688×780 phone size and inspected the [native-scale reader panels](commit-portraits/phone.jpg): art fits, faces remain visible, card text unchanged, no scrolling or clipping. Logs: `build/art/commit-portraits/{import,portraits-focused,phone}.log`.

This art commit is separate from the pinned spread measurement setup. The detached spread job uses a frozen `b872a6b` snapshot, so these portraits and subsequent commits cannot change its gameplay or provenance.
