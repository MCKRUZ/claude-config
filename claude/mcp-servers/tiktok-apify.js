#!/usr/bin/env node
// Zero-dependency MCP stdio server wrapping the Apify "TikTok Scraper"
// (clockworks/tiktok-scraper). Reads APIFY_TOKEN from env.
// Exposes one tool: tiktok_search. Open keyword/hashtag search, no fixed account list.

const ACTOR = "clockworks~tiktok-scraper";

const TOOL = {
  name: "tiktok_search",
  description:
    "Search TikTok for videos by keyword or hashtag via Apify (no TikTok login/session needed). " +
    "Returns caption, author, url, likes, comments, shares, plays. Use for open trend discovery, " +
    "not scoped to any preset account list.",
  inputSchema: {
    type: "object",
    properties: {
      query: { type: "string", description: "Search query / keyword / hashtag topic." },
      limit: { type: "integer", description: "Max videos to return (default 15)." },
    },
    required: ["query"],
  },
};

function send(msg) { process.stdout.write(JSON.stringify(msg) + "\n"); }

async function runSearch(args) {
  const token = process.env.APIFY_TOKEN;
  if (!token) return { content: [{ type: "text", text: "Error: APIFY_TOKEN not set." }], isError: true };
  const input = {
    searchQueries: [args.query],
    searchSection: "/video",
    resultsPerPage: args.limit || 15,
    shouldDownloadVideos: false,
    shouldDownloadCovers: false,
    shouldDownloadSubtitles: false,
    shouldDownloadSlideshowImages: false,
  };
  const u = "https://api.apify.com/v2/acts/" + ACTOR + "/run-sync-get-dataset-items?token=" + token;
  try {
    const r = await fetch(u, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(input) });
    const t = await r.text();
    let arr; try { arr = JSON.parse(t); } catch (e) { return { content: [{ type: "text", text: "Apify error " + r.status + ": " + t.slice(0, 300) }], isError: true }; }
    if (!Array.isArray(arr)) return { content: [{ type: "text", text: "Apify non-array (status " + r.status + "): " + t.slice(0, 300) }], isError: true };
    const blocks = arr.map((it, i) => {
      const author = (it.authorMeta && it.authorMeta.name) || it.authorMeta?.nickName || "?";
      const text = String(it.text || it.desc || "(no caption)").replace(/\s+/g, " ").slice(0, 300);
      const plays = it.playCount ?? it.videoMeta?.playCount ?? 0;
      const likes = it.diggCount ?? 0;
      const comments = it.commentCount ?? 0;
      const shares = it.shareCount ?? 0;
      const url = it.webVideoUrl || it.url || "";
      return `[${i + 1}] @${author} | ▶${plays} plays | ♥${likes} | ${comments} comments | ${shares} shares\n${text}\n${url}`;
    });
    return { content: [{ type: "text", text: blocks.join("\n\n") || "No results." }] };
  } catch (e) {
    return { content: [{ type: "text", text: "Request failed: " + String(e).slice(0, 200) }], isError: true };
  }
}

async function handle(msg) {
  const { id, method, params } = msg;
  if (method === "initialize") {
    send({ jsonrpc: "2.0", id, result: {
      protocolVersion: (params && params.protocolVersion) || "2024-11-05",
      capabilities: { tools: {} },
      serverInfo: { name: "tiktok-apify", version: "1.0.0" },
    }});
  } else if (method === "tools/list") {
    send({ jsonrpc: "2.0", id, result: { tools: [TOOL] } });
  } else if (method === "tools/call") {
    if (!params || params.name !== TOOL.name) {
      send({ jsonrpc: "2.0", id, error: { code: -32602, message: "Unknown tool" } });
      return;
    }
    const result = await runSearch(params.arguments || {});
    send({ jsonrpc: "2.0", id, result });
  } else if (method === "ping") {
    send({ jsonrpc: "2.0", id, result: {} });
  } else if (method && method.startsWith("notifications/")) {
    // notifications: no response
  } else if (id !== undefined) {
    send({ jsonrpc: "2.0", id, error: { code: -32601, message: "Method not found: " + method } });
  }
}

let buf = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  buf += chunk;
  let i;
  while ((i = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, i).trim();
    buf = buf.slice(i + 1);
    if (line) { try { handle(JSON.parse(line)); } catch (e) {} }
  }
});
process.stdin.on("end", () => process.exit(0));
