# deep-research-plus — Backlog

Future enhancements to this skill. Not scheduled; capture-only.

---

## 1. YouTube channel-feed enumeration (the "whole YouTube thing")

**Filed:** 2026-07-18 (during an ai-video-producer technique-harvest planning session).

**The gap.** deep-research-plus delegates to the built-in `deep-research` workflow, whose
discovery surface is **WebSearch → WebFetch** (+ Jina Reader / firecrawl). Its `YouTube`
(Bifrost) tool is scoped in the tool-map to "conference talks" — one-off lookups. The skill
has **no way to enumerate a channel's recent upload feed and transcribe the in-window
videos**. For any research task where the best/freshest signal lives in creator video
uploads (fast-moving tool ecosystems — AI image/video/audio, gamedev, framework releases),
this is the single highest-yield source and the skill misses it entirely.

**Evidence it matters.** In the ai-video-producer repo, a 2026-06-27 "technique harvest"
found ~80% of its yield by enumerating ~12 YouTube channels' upload feeds and transcribing
the in-range videos — a method deep-research-plus cannot perform. That repo solves it with a
local helper, `scripts/yt_transcript.py`:
- `--list <channel>` enumerates a channel's full upload feed (the view-sorted
  `getChannelTopVideos` endpoint cannot page the chronological feed).
- default mode pulls yt-dlp auto-captions → cleaned text.
It exists because the Bifrost `getTranscripts` MCP tool returns empty for every video.

**Enhancement to investigate.** Add an optional **"video-discovery" mode** to
deep-research-plus (or a shared helper it can call) that, when the topic is video-centric:
1. Seeds from known channels AND discovers new ones via `getRelatedVideos` off high-signal
   hits + `searchVideos` on the topic terms, filtered to a date window, ranked by
   relevance × view-velocity (cap the count so it stays bounded).
2. Enumerates each selected channel's recent uploads (chronological feed, not view-sorted).
3. Transcribes in-window videos (yt-dlp auto-captions; do NOT rely on Bifrost
   `getTranscripts` — verified broken).
4. Feeds the transcripts into the existing fetch→extract→verify pipeline as first-class
   sources, cited like any web source.

**Open questions.**
- Where should the yt-dlp dependency live so the skill is portable (not every repo has
  `scripts/yt_transcript.py`)? Bundle a copy in the skill folder, or document a required
  helper?
- How to keep it bounded — a video sweep can balloon; needs a hard source cap like the
  built-in workflow's ~15.
- Auto-captions are lossy/absent on some videos; needs a graceful "no transcript → skip +
  log" path (tie into a source-reachability log so gaps are surfaced, never silently
  dropped).

**Cross-ref.** The ai-video-producer `comfyui-research` skill was upgraded 2026-07-18 with a
"Delta Harvest" mode implementing exactly this pattern for that repo's domain; it is the
working reference for what a generalized version here would do.
