# REPORT-018 H04 companion independent acceptance

Date: 2026-08-20

Disposition: **ACCEPTED**

## Independent review

The final no-rerender order-43b return is accepted. The owner acceptance is `/private/tmp/H04-order43b-evidence.kRMZmy/report018_h04_order43b_acceptance.md`, SHA-256 `1c52a84a1420de95b42fff35cbd161738be87840f2f9ad6390f89e9d5ab33dbe`. Its non-circular manifest is SHA-256 `acf22ded084aabe480f56ab2edabbe5dabb68c4e4348747a64f8ba57be2b4651` and independently passes 30/30 exact, unique, non-circular rows under R 4.6.1.

The corrected verifier is restricted to the three authorized header-count or status substitutions. Exact reverse reconstruction reproduces accepted order-43a verifier SHA-256 `1280d1f6b0bd2298cf439e71656050c8ce9c2d81b9efda93694899c19ee27256`. The final verifier is `4bd64bbcb3dbefcbf965b789d76865e08224340ef5af548ce41c75311ce7037e` and passed once with 37 native gt tables, four figures, one top-down Mermaid, 1,146 `headers` attributes, 1,968 resolved header-ID tokens, zero unresolved or unsupported ID references, 276 live-exact preparation-manifest rows, 836 build files, four classified build deltas, and no unclassified drift.

Secure loopback QA passed at 1440 by 1000, 708 by 1000, and 720 by 500 as the 200-percent-equivalent view. All 37 tables remain usable. The four wide narrow tables have contained working horizontal scrolling. The four figures pass at displayed and native PNG sizes. The top-down Mermaid, headings, captions, alt text, callouts, code disclosures, reciprocal links, and navigation remain usable. No console warning or error was observed. The optional missing favicon is a nonblocking site cosmetic under REPORT-018.

The loopback server was bound only to `127.0.0.1:58949`, stopped cleanly, and left no listener. The post-QA 836-file build inventory is byte-identical to the post-integration inventory at SHA-256 `63b86f9e629a2096ce43bc3fc259b421c406483d3c756cefa450bc9cce148553`. All 260 post-integration protected identities remain exact.

## Accepted identities

- H04 result QMD: `f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`
- H04 companion QMD: `efdb5be8dc194695f40c50249fab14905ec337bc63079ae589557de860188474`
- H04 result HTML: `da5f7f7195da843e46014d4796d35381f74d223ba79c37bb78fb8ce6dfa67c9f`
- H04 companion HTML: `e5f0861ef1b1e4accf4e6a924155c6ec5ce77a9c9865d6dc7bf5427e3de860ea`
- H04 preparation manifest: `f2d251b50e9fa61caa978d7ce155a6743f09f2667b0f827ffcbfc281b2ac706e`
- H04 preparation test: `8a862e0acece4d77392647a55df4f659410fbc94e2fc6ae40b642c47c2184935`
- Nature Health profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`

H04 result and companion integration is complete. The serial render gate is clear. H05 result may be released as the next sole REPORT-018 target after current accepted source, test, manifest, profile, and stale-output pins are reproduced. The H05 companion and every later target remain held.
