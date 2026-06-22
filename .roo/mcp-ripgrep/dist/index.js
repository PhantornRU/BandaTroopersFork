"use strict";

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawn } = require("node:child_process");

function pickFirstExisting(paths) {
  for (const candidate of paths) {
    if (candidate && fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

const homeDir = process.env.USERPROFILE || os.homedir();
const repoRoot = path.resolve(__dirname, "..", "..", "..");

const sdkRoot = pickFirstExisting([
  path.join(homeDir, ".roo", "mcp", "zoo-guardrails", "node_modules", "@modelcontextprotocol", "sdk", "dist", "cjs"),
  path.join(repoRoot, "node_modules", "@modelcontextprotocol", "sdk", "dist", "cjs"),
]);

const zodPath = pickFirstExisting([
  path.join(homeDir, ".roo", "mcp", "zoo-guardrails", "node_modules", "zod", "v4", "index.cjs"),
  path.join(repoRoot, "node_modules", "zod", "v4", "index.cjs"),
]);

if (!sdkRoot) {
  throw new Error("Unable to locate @modelcontextprotocol/sdk. Expected zoo-guardrails install or repo node_modules.");
}

if (!zodPath) {
  throw new Error("Unable to locate zod/v4. Expected zoo-guardrails install or repo node_modules.");
}

const { McpServer } = require(path.join(sdkRoot, "server", "mcp.js"));
const { StdioServerTransport } = require(path.join(sdkRoot, "server", "stdio.js"));
const z = require(zodPath);

const DEFAULT_ROOT = repoRoot;
const DEBUG = process.env.MCP_RG_DEBUG === "1";

function debug(message) {
  if (DEBUG) {
    process.stderr.write(`[ripgrep-mcp] ${message}\n`);
  }
}

function resolveRgBinary() {
  const candidateNames = process.platform === "win32" ? ["rg.exe", "rg"] : ["rg"];
  const searchPath = process.env.PATH ? process.env.PATH.split(path.delimiter) : [];

  for (const entry of searchPath) {
    const trimmed = entry.trim().replace(/^"|"$/g, "");
    if (!trimmed) {
      continue;
    }
    for (const name of candidateNames) {
      const candidate = path.join(trimmed, name);
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }
  }

  return candidateNames[0];
}

const RG = resolveRgBinary();

function resolveRoot(root) {
  const resolved = path.resolve(root || DEFAULT_ROOT);
  if (!fs.existsSync(resolved) || !fs.statSync(resolved).isDirectory()) {
    throw new Error(`Root does not exist or is not a directory: ${resolved}`);
  }
  return resolved;
}

function toArray(value) {
  if (value === undefined || value === null) {
    return [];
  }
  return Array.isArray(value) ? value : [value];
}

function commonInputShape(defaults = {}) {
  return {
    root: z.string().optional(),
    glob: z.union([z.string(), z.array(z.string())]).optional(),
    hidden: z.boolean().optional(),
    followSymlinks: z.boolean().optional(),
    ignoreCase: z.boolean().optional(),
    fixedStrings: z.boolean().optional(),
    multiline: z.boolean().optional(),
    wordRegExp: z.boolean().optional(),
    beforeContext: z.number().int().min(0).optional(),
    afterContext: z.number().int().min(0).optional(),
    maxResults: z.number().int().min(1).max(1000).optional(),
    ...defaults,
  };
}

function buildSearchArgs(pattern, options) {
  const args = ["--line-number", "--column", "--no-heading", "--no-messages"];
  if (options.hidden) {
    args.push("--hidden");
  }
  if (options.followSymlinks) {
    args.push("-L");
  }
  if (options.ignoreCase === true) {
    args.push("-i");
  }
  if (options.fixedStrings === true) {
    args.push("-F");
  }
  if (options.multiline === true) {
    args.push("-U");
  }
  if (options.wordRegExp === true) {
    args.push("-w");
  }
  for (const glob of toArray(options.glob)) {
    args.push("-g", glob);
  }
  args.push(pattern);
  return args;
}

function runRg(args, root) {
  return new Promise((resolve, reject) => {
    debug(`spawn ${RG} cwd=${repoRoot} args=${JSON.stringify(args)}`);
    const child = spawn(RG, args, {
      cwd: repoRoot,
      shell: false,
      windowsHide: true,
    });

    let stdout = "";
    let stderr = "";

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");

    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });

    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });

    child.on("error", (error) => {
      debug(`error ${error.message}`);
      reject(error);
    });
    child.on("close", (code) => {
      debug(`close code=${code}`);
      resolve({ code, stdout, stderr });
    });
  });
}

function assertRgSuccess(result, context) {
  if (result.code !== 0 && result.code !== 1) {
    const detail = result.stderr.trim() || `rg exited with code ${result.code}`;
    throw new Error(`${context}: ${detail}`);
  }
}

function parseJsonLines(output) {
  const events = [];
  for (const rawLine of output.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line) {
      continue;
    }
    try {
      events.push(JSON.parse(line));
    } catch {
      // Ignore malformed trailing fragments; ripgrep JSON should normally be line-delimited.
    }
  }
  return events;
}

function formatRelative(root, filePath) {
  const relative = path.relative(root, filePath);
  return relative || path.basename(filePath);
}

async function collectSearchResults(pattern, options, limit = 50) {
  const root = resolveRoot(options.root);
  const args = buildSearchArgs(pattern, options);
  args.push(root);
  debug(`spawn ${RG} cwd=${root} args=${JSON.stringify(args)}`);

  return new Promise((resolve, reject) => {
    const child = spawn(RG, args, {
      cwd: root,
      shell: false,
      windowsHide: true,
    });

    let stderr = "";
    const lines = [];
    const files = new Set();
    let truncated = false;

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");

    const flushLine = (rawLine) => {
      const line = rawLine.replace(/\r$/, "");
      if (!line) {
        return;
      }
      const match = line.match(/^(.+?):(\d+):(\d+):(.*)$/);
      if (!match) {
        return;
      }
      const file = formatRelative(root, match[1]);
      const lineNumber = match[2];
      const column = match[3];
      const text = match[4];
      files.add(file);
      lines.push(`${file}:${lineNumber}:${column} ${text}`);
      if (lines.length >= limit) {
        truncated = true;
        child.kill();
      }
    };

    let buffer = "";
    child.stdout.on("data", (chunk) => {
      buffer += chunk;
      let index = buffer.indexOf("\n");
      while (index !== -1) {
        flushLine(buffer.slice(0, index));
        buffer = buffer.slice(index + 1);
        index = buffer.indexOf("\n");
      }
    });

    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });

    child.on("error", (error) => {
      debug(`error ${error.message}`);
      reject(error);
    });

    child.on("close", (code) => {
      debug(`close code=${code} truncated=${truncated} hits=${lines.length}`);
      if (!truncated && code !== 0 && code !== 1) {
        reject(new Error(`Search failed for ${pattern}: ${stderr.trim() || `rg exited with code ${code}`}`));
        return;
      }
      if (buffer) {
        flushLine(buffer);
      }
      if (!lines.length) {
        resolve({
          root,
          matches: 0,
          files: 0,
          truncated: false,
          text: "No matches found.",
        });
        return;
      }

      resolve({
        root,
        matches: lines.length,
        files: files.size,
        truncated,
        text: [
          `Found ${lines.length} match${lines.length === 1 ? "" : "es"} in ${files.size} file${files.size === 1 ? "" : "s"}.`,
          truncated ? `Showing first ${limit} match${limit === 1 ? "" : "es"}.` : null,
          "",
          ...lines,
        ]
          .filter((entry) => entry !== null)
          .join("\n"),
      });
    });
  });
}

async function collectCountResults(pattern, options) {
  const root = resolveRoot(options.root);
  const args = buildSearchArgs(pattern, { ...options, fixedStrings: options.fixedStrings ?? false });
  args.splice(0, 0, "--count-matches");
  args.push(root);
  const result = await runRg(args, root);
  assertRgSuccess(result, `Count failed for ${pattern}`);

  const counts = [];
  let total = 0;
  for (const rawLine of result.stdout.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line) {
      continue;
    }
    const separator = line.lastIndexOf(":");
    if (separator === -1) {
      continue;
    }
    const file = line.slice(0, separator);
    const count = Number.parseInt(line.slice(separator + 1), 10);
    if (Number.isFinite(count)) {
      total += count;
      counts.push({ file: formatRelative(root, file), count });
    }
  }

  return {
    root,
    total,
    files: counts.length,
    text: counts.length
      ? [
          `Total matches: ${total}`,
          `Files with matches: ${counts.length}`,
          "",
          ...counts.slice(0, 50).map((entry) => `${entry.file}: ${entry.count}`),
        ].join("\n")
      : "Total matches: 0",
  };
}

async function listFiles(options) {
  const root = resolveRoot(options.root);
  const args = ["--files", "--no-messages"];
  if (options.hidden) {
    args.push("--hidden");
  }
  if (options.followSymlinks) {
    args.push("-L");
  }
  for (const glob of toArray(options.glob)) {
    args.push("-g", glob);
  }
  args.push(root);
  const result = await runRg(args, root);
  assertRgSuccess(result, "List files failed");
  const files = result.stdout
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((file) => formatRelative(root, file));

  return {
    root,
    files,
    text: files.length
      ? [`Found ${files.length} file${files.length === 1 ? "" : "s"}.`, "", ...files.slice(0, 500)].join("\n")
      : "No files found.",
  };
}

function listFileTypesFromFiles(files) {
  const counts = new Map();
  for (const file of files) {
    const base = path.basename(file);
    const ext = path.extname(base).toLowerCase();
    const key = ext || "[no extension]";
    counts.set(key, (counts.get(key) || 0) + 1);
  }
  return [...counts.entries()]
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
    .map(([ext, count]) => ({ ext, count }));
}

const server = new McpServer({
  name: "ripgrep",
  version: "1.0.0",
});

server.registerTool("search", {
  description: "Find literal text matches in files under the workspace root.",
  inputSchema: commonInputShape({
    query: z.string().min(1),
  }),
}, async ({ query, ...options }) => {
  const result = await collectSearchResults(query, { ...options, fixedStrings: options.fixedStrings ?? true }, options.maxResults ?? 50);
  return { content: [{ type: "text", text: result.text }] };
});

server.registerTool("advanced_search", {
  description: "Find regex matches in files under the workspace root with filtering and context options.",
  inputSchema: commonInputShape({
    pattern: z.string().min(1),
  }),
}, async ({ pattern, ...options }) => {
  const result = await collectSearchResults(pattern, { ...options, fixedStrings: options.fixedStrings ?? false }, options.maxResults ?? 50);
  return { content: [{ type: "text", text: result.text }] };
});

server.registerTool("count_matches", {
  description: "Count matching occurrences per file under the workspace root.",
  inputSchema: commonInputShape({
    query: z.string().min(1),
  }),
}, async ({ query, ...options }) => {
  const result = await collectCountResults(query, options);
  return { content: [{ type: "text", text: result.text }] };
});

server.registerTool("list_files", {
  description: "List files under the workspace root with optional glob filters.",
  inputSchema: {
    root: z.string().optional(),
    glob: z.union([z.string(), z.array(z.string())]).optional(),
    hidden: z.boolean().optional(),
    followSymlinks: z.boolean().optional(),
  },
}, async (options) => {
  const result = await listFiles(options);
  return { content: [{ type: "text", text: result.text }] };
});

server.registerTool("list_file_types", {
  description: "Summarize file extensions for files under the workspace root.",
  inputSchema: {
    root: z.string().optional(),
    glob: z.union([z.string(), z.array(z.string())]).optional(),
    hidden: z.boolean().optional(),
    followSymlinks: z.boolean().optional(),
  },
}, async (options) => {
  const result = await listFiles(options);
  const counts = listFileTypesFromFiles(result.files);
  const text = counts.length
    ? [`Found ${result.files.length} file${result.files.length === 1 ? "" : "s"}.`, "", ...counts.map((entry) => `${entry.ext}: ${entry.count}`)].join("\n")
    : "No files found.";
  return { content: [{ type: "text", text }] };
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  process.stderr.write(`ripgrep MCP server error: ${error?.stack || error}\n`);
  process.exit(1);
});
