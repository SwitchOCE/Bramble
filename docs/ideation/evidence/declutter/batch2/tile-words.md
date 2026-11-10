# Tile words at rest: text-node audit

Revision: `9d649868 + frozen finish working tree (HandFan, Ring travel and tile-word audit)`. Capture stage: batch2 finish text-node audit; fan10 authorized edge case.

| Scenario | Pixels | Shop | Hand | Own board | Scout board | All words | Legacy names | Unexpected words | Raw labels | Words check |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| overview | 1688x780 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 40 | PASS |
| overview | 1920x1080 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 40 | PASS |
| natural-birds | 1688x780 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 30 | PASS |
| natural-birds | 1920x1080 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 30 | PASS |
| lobby | 1688x780 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 39 | PASS |
| lobby | 1920x1080 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 39 | PASS |
| scout | 1688x780 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 30 | PASS |
| scout | 1920x1080 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 30 | PASS |
| reader-reel_mistress-golden | 1688x780 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 51 | PASS |
| reader-reel_mistress-golden | 1920x1080 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 51 | PASS |
| fan10 | 1688x780 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 61 | PASS |
| fan10 | 1920x1080 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 61 | PASS |
| legacy-slice-recruit | 1688x780 | 6 | 0 | 0 | 0 | 6 | 6 | 0 | 30 | PASS |
| legacy-slice-scout | 1688x780 | 0 | 0 | 0 | 8 | 8 | 8 | 0 | 28 | PASS |
| legacy-slice-recruit | 1920x1080 | 6 | 0 | 0 | 0 | 6 | 6 | 0 | 30 | PASS |
| legacy-slice-scout | 1920x1080 | 0 | 0 | 0 | 8 | 8 | 8 | 0 | 28 | PASS |

Live visible Label, RichTextLabel and rendered Button text. Scope follows actual CardView zones, HandFan ownership and BoardView ancestry, including slot/name strips. HUD and CardDetail reader text are outside tile scope. Letter-containing tokens count as words, including F1; signed/fractional numbers and compact k/m/b stat numbers do not. Every word retains its node, full path, zone, tile path, source text and unit identity.

The unchanged legacy slice uses unit IDs without individual art. Their fallback name words are explicitly listed and counted; only those missing-art names are allowed. No shipped portrait exceptions remain.

The <=40 gate applies to its defined recruit/scout budget states and is unchanged. The user authorized fan10 as an edge case: it keeps every hand stat, reports all 61 raw text nodes, and passes the separate zero-tile-words check. Its 61 is not a failure of the defined budget-state test. No occlusion or focus-only exclusion is applied.

**Native visual audit still required.** Raster lettering and text drawn directly by custom drawing are not discoverable from TextNodes. This automated count is not a claim of zero words in pixels: a native-size visual audit of tile art, stamps and custom drawing remains required.

Packet and fan10 coverage: 12/12 state/size rows. Shipped roster: 120 units across 4 tile zones and 2 normal/golden variants, 0 text-node words.

User-authorized full-hand edge case, outside the defined budget states:

- fan10 at 1688x780: 61 labels.
- fan10 at 1920x1080: 61 labels.

## Raw label categories

Per-node raw category metadata will be supplied by the final live captures.

## Every counted word

| Scenario | Pixels | Zone | Word | Node | Path | Allowed missing-art name |
| --- | --- | --- | --- | --- | --- | --- |
| legacy-slice-recruit | 1688x780 | shop | Drumming | @Label@10908 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@GridContainer@10457/@Control@10925/@Label@10908 | True |
| legacy-slice-recruit | 1688x780 | shop | Woodpecker | @Label@10908 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@GridContainer@10457/@Control@10925/@Label@10908 | True |
| legacy-slice-recruit | 1688x780 | shop | Hedge | @Label@10928 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@GridContainer@10457/@Control@10945/@Label@10928 | True |
| legacy-slice-recruit | 1688x780 | shop | Doctor | @Label@10928 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@GridContainer@10457/@Control@10945/@Label@10928 | True |
| legacy-slice-recruit | 1688x780 | shop | Garden | @Label@10948 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@GridContainer@10457/@Control@10965/@Label@10948 | True |
| legacy-slice-recruit | 1688x780 | shop | Snail | @Label@10948 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@GridContainer@10457/@Control@10965/@Label@10948 | True |
| legacy-slice-scout | 1688x780 | scout_board | Bramble | @Label@11402 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@Control@10812/@Control@10807/@Control@11419/@Label@11402 | True |
| legacy-slice-scout | 1688x780 | scout_board | Ooze | @Label@11402 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@Control@10812/@Control@10807/@Control@11419/@Label@11402 | True |
| legacy-slice-scout | 1688x780 | scout_board | Hedgehog | @Label@11422 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@Control@10812/@Control@10807/@Control@11439/@Label@11422 | True |
| legacy-slice-scout | 1688x780 | scout_board | Twin | @Label@11422 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@Control@10812/@Control@10807/@Control@11439/@Label@11422 | True |
| legacy-slice-scout | 1688x780 | scout_board | Fox | @Label@11442 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@Control@10812/@Control@10807/@Control@11459/@Label@11442 | True |
| legacy-slice-scout | 1688x780 | scout_board | Notary | @Label@11442 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@Control@10812/@Control@10807/@Control@11459/@Label@11442 | True |
| legacy-slice-scout | 1688x780 | scout_board | Pixie | @Label@11462 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@Control@10812/@Control@10807/@Control@11479/@Label@11462 | True |
| legacy-slice-scout | 1688x780 | scout_board | Scout | @Label@11462 | /root/GutRunner/@Node@11/@SubViewport@10445/@Control@10851/@Control@10448/@Control@10812/@Control@10807/@Control@11479/@Label@11462 | True |
| legacy-slice-recruit | 1920x1080 | shop | Drumming | @Label@11943 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@GridContainer@11492/@Control@11960/@Label@11943 | True |
| legacy-slice-recruit | 1920x1080 | shop | Woodpecker | @Label@11943 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@GridContainer@11492/@Control@11960/@Label@11943 | True |
| legacy-slice-recruit | 1920x1080 | shop | Hedge | @Label@11963 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@GridContainer@11492/@Control@11980/@Label@11963 | True |
| legacy-slice-recruit | 1920x1080 | shop | Doctor | @Label@11963 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@GridContainer@11492/@Control@11980/@Label@11963 | True |
| legacy-slice-recruit | 1920x1080 | shop | Garden | @Label@11983 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@GridContainer@11492/@Control@12000/@Label@11983 | True |
| legacy-slice-recruit | 1920x1080 | shop | Snail | @Label@11983 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@GridContainer@11492/@Control@12000/@Label@11983 | True |
| legacy-slice-scout | 1920x1080 | scout_board | Bramble | @Label@12437 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@Control@11847/@Control@11842/@Control@12454/@Label@12437 | True |
| legacy-slice-scout | 1920x1080 | scout_board | Ooze | @Label@12437 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@Control@11847/@Control@11842/@Control@12454/@Label@12437 | True |
| legacy-slice-scout | 1920x1080 | scout_board | Hedgehog | @Label@12457 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@Control@11847/@Control@11842/@Control@12474/@Label@12457 | True |
| legacy-slice-scout | 1920x1080 | scout_board | Twin | @Label@12457 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@Control@11847/@Control@11842/@Control@12474/@Label@12457 | True |
| legacy-slice-scout | 1920x1080 | scout_board | Fox | @Label@12477 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@Control@11847/@Control@11842/@Control@12494/@Label@12477 | True |
| legacy-slice-scout | 1920x1080 | scout_board | Notary | @Label@12477 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@Control@11847/@Control@11842/@Control@12494/@Label@12477 | True |
| legacy-slice-scout | 1920x1080 | scout_board | Pixie | @Label@12497 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@Control@11847/@Control@11842/@Control@12514/@Label@12497 | True |
| legacy-slice-scout | 1920x1080 | scout_board | Scout | @Label@12497 | /root/GutRunner/@Node@11/@SubViewport@11480/@Control@11886/@Control@11483/@Control@11847/@Control@11842/@Control@12514/@Label@12497 | True |
