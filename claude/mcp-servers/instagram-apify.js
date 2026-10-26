#!/usr/bin/env node
// Zero-dependency MCP stdio server wrapping the Apify "Instagram Scraper"
// (apify/instagram-scraper). Reads APIFY_TOKEN from env.
// Exposes one tool: instagram_search. Open hashtag search, no fixed account list.
// Instagram has no free-text search API on this actor, so a topic query is turned
// into a hashtag URL (https://www.instagram.com/explore/tags/<tag>/) — the natural
// open-discovery surface Instagram itself exposes.

const ACTOR = "apify~instagram-scraper";

const TOOL = {
  name: "instagram_search",
  description:
    "Search Instagram by hashtag/topic via Apify (query is converted to a hashtag, no login needed). " +
    "Returns caption, author, url, likes, comments, and view count for video content. Use for open " +
    "trend discovery, not scoped to any preset account list.",
  inputSchema: {
    type: "object",
    properties: {
      query: { type: "string", description: "Topic to search — converted to a hashtag (spaces/punctuation stripped)." },
      limit: { type: "integer", description: "Max posts to return (default 15)." },
    },
    required: ["query"],
  },
};

function send(msg) { process.stdout.write(JSON.stringify(msg) + "\n"); }

function toHashtag(q) {
  return String(q).toLowerCase().replace(/[^a-z0-9]+/g, "");
}

async function runSearch(args) {
  const token = process.env.APIFY_TOKEN;
  if (!token) return { content: [{ type: "text", text: "Error: APIFY_TOKEN not set." }], isError: true };
  const tag = toHashtag(args.query);
  if (!tag) return { content: [{ type: "text", text: "Error: query produced an empty hashtag." }], isError: true };
  const input = {
    directUrls: ["https://www.instagram.com/explore/tags/" + tag + "/"],
    resultsType: "posts",
    resultsLimit: args.limit || 15,
    addParentData: false,
  };
  const u = "https://api.apify.com/v2/acts/" + ACTOR + "/run-sync-get-dataset-items?token=" + token;
  try {
    const r = await fetch(u, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(input) });
    const t = await r.text();
    let arr; try { arr = JSON.parse(t); } catch (e) { return { content: [{ type: "text", text: "Apify error " + r.status + ": " + t.slice(0, 300) }], isError: true }; }
    if (!Array.isArray(arr)) return { content: [{ type: "text", text: "Apify non-array (status " + r.status + "): " + t.slice(0, 300) }], isError: true };
    const blocks = arr.map((it, i) => {
      const author = it.ownerUsername || it.ownerFullName || "?";
      const caption = String(it.caption || "(no caption)").replace(/\s+/g, " ").slice(0, 300);
      const likes = it.likesCount ?? 0;
      const comments = it.commentsCount ?? 0;
      const views = it.videoViewCount ?? it.videoPlayCount ?? null;
      const viewsPart = views != null ? ` | ▶${views} views` : "";
      const url = it.url || "";
      return `[${i + 1}] @${author} | ♥${likes} | ${comments} comments${viewsPart}\n${caption}\n${url}`;
    });
    return { content: [{ type: "text", text: blocks.join("\n\n") || "No results (hashtag #" + tag + " may not exist or has no recent posts)." }] };
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
      serverInfo: { name: "instagram-apify", version: "1.0.0" },
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
