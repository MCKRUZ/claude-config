#!/usr/bin/env node
// Zero-dependency MCP stdio server wrapping the Apify "Fast Reddit Scraper"
// (practicaltools/apify-reddit-api). Reads APIFY_TOKEN from env.
// Exposes one tool: reddit_search.

const ACTOR = "practicaltools~apify-reddit-api";

const TOOL = {
  name: "reddit_search",
  description:
    "Search Reddit for posts via Apify (no Reddit API credentials needed; bypasses Reddit's bot block). " +
    "Returns title, subreddit, url, a 500-character body excerpt, upvotes, and comment count (never comments). " +
    "Use for finding threads and community sentiment; call reddit_thread to read a thread in full.",
  inputSchema: {
    type: "object",
    properties: {
      query: { type: "string", description: "Search query / topic." },
      subreddits: {
        type: "array", items: { type: "string" },
        description: "Optional subreddit names (without r/) to seed the crawl.",
      },
      limit: { type: "integer", description: "Max posts to return (default 15)." },
      sort: { type: "string", enum: ["relevance", "hot", "top", "new", "comments"], description: "Default relevance." },
      time: { type: "string", enum: ["hour", "day", "week", "month", "year", "all"], description: "Default all." },
    },
    required: ["query"],
  },
};

const THREAD_TOOL = {
  name: "reddit_thread",
  description:
    "Fetch the FULL text of one or more Reddit threads (1-8 URLs): the complete post body plus the nested comment tree " +
    "with replies indented, each level sorted by upvotes. Use after reddit_search when the 500-character excerpt is not enough. " +
    "Reddit blocks direct page fetches (WebFetch, Firecrawl, browser tools); this goes through Apify.",
  inputSchema: {
    type: "object",
    properties: {
      urls: { type: "array", items: { type: "string" }, description: "Full reddit.com thread URLs (as returned by reddit_search)." },
      max_comments: { type: "integer", description: "Max comments rendered per thread, replies included (default 80)." },
      max_depth: { type: "integer", description: "Max reply nesting depth rendered (default 5)." },
    },
    required: ["urls"],
  },
};

function send(msg) { process.stdout.write(JSON.stringify(msg) + "\n"); }

function asList(v) {
  if (Array.isArray(v)) return v;
  if (typeof v === "string") { try { const p = JSON.parse(v); return Array.isArray(p) ? p : []; } catch (e) { return []; } }
  return [];
}

function countAll(list) {
  let n = 0;
  for (const c of list) n += 1 + countAll(asList(c.replies));
  return n;
}

function renderComments(list, depth, state, maxDepth, out) {
  const sorted = [...list].sort((a, b) => (Number(b.upVotes) || 0) - (Number(a.upVotes) || 0));
  for (const c of sorted) {
    if (state.left <= 0) { state.truncated = true; return; }
    const pad = "  ".repeat(depth);
    const body = String(c.body || "").replace(/\n/g, "\n" + pad + "  ");
    out.push(`${pad}- [${Number(c.upVotes) || 0}] ${c.username || "?"}: ${body}`);
    state.left -= 1;
    const kids = asList(c.replies);
    if (kids.length) {
      if (depth + 1 >= maxDepth) state.truncated = true;
      else renderComments(kids, depth + 1, state, maxDepth, out);
    }
  }
}

// The actor rejects maxItems > 100, and maxItems caps posts + comments + replies combined,
// so each thread is fetched in its own run (in parallel) rather than batching URLs.
const ACTOR_MAX_ITEMS = 100;

async function fetchThread(url, token, maxComments, maxDepth, signal) {
  const input = {
    startUrls: [{ url }],
    skipComments: false, searchComments: false, searchPosts: false, searchCommunities: false, searchUsers: false,
    skipUserPosts: true, skipCommunity: true,
    maxItems: Math.min(ACTOR_MAX_ITEMS, maxComments + 20),
  };
  const u = "https://api.apify.com/v2/acts/" + ACTOR + "/run-sync-get-dataset-items?token=" + token;
  const r = await fetch(u, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(input), signal });
  const t = await r.text();
  let arr; try { arr = JSON.parse(t); } catch (e) { return `# ${url}\nApify error ${r.status}: ${t.slice(0, 300)}`; }
  if (!Array.isArray(arr)) return `# ${url}\nApify non-array (status ${r.status}): ${t.slice(0, 300)}`;
  if (!arr.length) return `# ${url}\nNo data returned.`;
  const it = arr[0];
  const p = it.post || {};
  const comments = asList(it.comments);
  const total = countAll(comments);
  const out = [];
  const state = { left: maxComments, truncated: false };
  renderComments(comments, 0, state, maxDepth, out);
  const note = (total >= ACTOR_MAX_ITEMS - 25 || state.truncated) ? " (partial: scraper item cap or max_comments/max_depth reached)" : "";
  const head = `# ${p.title || "(no title)"}\nr/${p.parsedCommunityName || "?"} | ▲${p.upVotes || 0} | ${p.numberOfComments || 0} comments reported, ${total} returned${note}\n${p.url || url}\n\n${p.body || ""}\n\n## Comments`;
  return head + "\n" + (out.join("\n") || "(none returned)");
}

async function runThread(args) {
  const token = process.env.APIFY_TOKEN;
  if (!token) return { content: [{ type: "text", text: "Error: APIFY_TOKEN not set." }], isError: true };
  const urls = (Array.isArray(args.urls) ? args.urls : []).map(String).filter((u) => /reddit\.com\/r\/[^/]+\/comments\//.test(u)).slice(0, 8);
  if (!urls.length) return { content: [{ type: "text", text: "Error: give 1-8 full Reddit thread URLs (reddit.com/r/<sub>/comments/...)." }], isError: true };
  const maxComments = args.max_comments || 80;
  const maxDepth = args.max_depth || 5;
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 280000);
  try {
    const threads = await Promise.all(urls.map((url) =>
      fetchThread(url, token, maxComments, maxDepth, ctl.signal).catch((e) => `# ${url}\nRequest failed: ${String(e).slice(0, 200)}`)));
    return { content: [{ type: "text", text: threads.join("\n\n=====\n\n") }] };
  } finally {
    clearTimeout(timer);
  }
}

async function runSearch(args) {
  const token = process.env.APIFY_TOKEN;
  if (!token) return { content: [{ type: "text", text: "Error: APIFY_TOKEN not set." }], isError: true };
  const input = {
    searches: [args.query],
    searchPosts: true, searchComments: false, searchCommunities: false, searchUsers: false,
    skipComments: true, skipUserPosts: true, skipCommunity: true,
    sort: args.sort || "relevance", time: args.time || "all",
    maxItems: args.limit || 15,
  };
  if (Array.isArray(args.subreddits) && args.subreddits.length) {
    input.startUrls = args.subreddits.map((s) => ({
      url: "https://www.reddit.com/r/" + String(s).replace(/^r\//, "").trim() + "/",
    }));
  }
  const u = "https://api.apify.com/v2/acts/" + ACTOR + "/run-sync-get-dataset-items?token=" + token;
  try {
    const r = await fetch(u, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(input) });
    const t = await r.text();
    let arr; try { arr = JSON.parse(t); } catch (e) { return { content: [{ type: "text", text: "Apify error " + r.status + ": " + t.slice(0, 300) }], isError: true }; }
    if (!Array.isArray(arr)) return { content: [{ type: "text", text: "Apify non-array (status " + r.status + "): " + t.slice(0, 300) }], isError: true };
    const blocks = arr.map((it, i) => {
      const sub = it.parsedCommunityName || it.communityName || "?";
      const title = it.title || "(no title)";
      const body = String(it.body || "").replace(/\s+/g, " ").slice(0, 500);
      return `[${i + 1}] r/${sub} | ▲${it.upVotes || 0} | ${it.numberOfComments || 0} comments\n${title}\n${it.url || ""}\n${body}`;
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
      serverInfo: { name: "reddit-apify", version: "1.0.0" },
    }});
  } else if (method === "tools/list") {
    send({ jsonrpc: "2.0", id, result: { tools: [TOOL, THREAD_TOOL] } });
  } else if (method === "tools/call") {
    const name = params && params.name;
    if (name !== TOOL.name && name !== THREAD_TOOL.name) {
      send({ jsonrpc: "2.0", id, error: { code: -32602, message: "Unknown tool" } });
      return;
    }
    const result = name === THREAD_TOOL.name ? await runThread(params.arguments || {}) : await runSearch(params.arguments || {});
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
