#!/usr/bin/env node
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { createHash, randomBytes } from "node:crypto";
import { dirname, resolve } from "node:path";
import { connect as tlsConnect } from "node:tls";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_SCENE_ID = "01-illiterate";
const DEFAULT_MANIFEST = "data/audio_generation_manifest.json";
const TTS_ENDPOINT = "wss://api.minimaxi.com/ws/v1/t2a_v2";
const MUSIC_ENDPOINT = "https://api.minimaxi.com/v1/music_generation";

function usage() {
  return `Usage:
  node tools/minimax_audio_generate.mjs --scene-id 01-illiterate --dry-run --limit-samples
  node tools/minimax_audio_generate.mjs --type music --scene-id 01-illiterate --cue-id MUS-01-001
  node tools/minimax_audio_generate.mjs --type voice --scene-id 01-illiterate --cue-id DLG-01-SAMPLE-JZX

Options:
  --type music|voice|all      Defaults to all.
  --scene-id <id>             Defaults to 01-illiterate.
  --cue-id <id>               Select one music cue or voice line.
  --dry-run                   Print sanitized jobs without calling MiniMax.
  --limit-samples [n]         Only sample_generation items; optional max count.
  --manifest <path>           Defaults to data/audio_generation_manifest.json.
`;
}

function parseArgs(argv) {
  const args = {
    type: "all",
    sceneId: DEFAULT_SCENE_ID,
    cueId: null,
    dryRun: false,
    limitSamples: false,
    sampleLimit: null,
    manifest: DEFAULT_MANIFEST,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--help" || arg === "-h") {
      console.log(usage());
      process.exit(0);
    }
    if (arg === "--type") {
      args.type = argv[++index];
    } else if (arg === "--scene-id") {
      args.sceneId = argv[++index];
    } else if (arg === "--cue-id") {
      args.cueId = argv[++index];
    } else if (arg === "--dry-run") {
      args.dryRun = true;
    } else if (arg === "--limit-samples") {
      args.limitSamples = true;
      const maybeLimit = argv[index + 1];
      if (maybeLimit && !maybeLimit.startsWith("--")) {
        args.sampleLimit = Number.parseInt(maybeLimit, 10);
        index += 1;
      }
    } else if (arg === "--manifest") {
      args.manifest = argv[++index];
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  if (!["music", "voice", "all"].includes(args.type)) {
    throw new Error("--type must be music, voice, or all");
  }
  if (args.sampleLimit !== null && (!Number.isInteger(args.sampleLimit) || args.sampleLimit < 1)) {
    throw new Error("--limit-samples value must be a positive integer");
  }
  return args;
}

async function readJson(repoPath) {
  return JSON.parse(await readFile(resolve(ROOT, repoPath), "utf8"));
}

async function writeJson(repoPath, data) {
  const absolutePath = resolve(ROOT, repoPath);
  await mkdir(dirname(absolutePath), { recursive: true });
  await writeFile(absolutePath, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}

async function readEnvFile() {
  const env = {};
  try {
    const text = await readFile(resolve(ROOT, ".env"), "utf8");
    for (const rawLine of text.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith("#")) {
        continue;
      }
      const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
      if (!match) {
        continue;
      }
      let value = match[2].trim();
      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }
      env[match[1]] = value;
    }
  } catch (error) {
    if (error.code !== "ENOENT") {
      throw error;
    }
  }
  return { ...env, ...process.env };
}

function truncate(text, limit = 180) {
  if (text.length <= limit) {
    return text;
  }
  return `${text.slice(0, limit - 1)}...`;
}

function selectItems(items, args, idField) {
  let selected = items;
  if (args.cueId) {
    selected = selected.filter((item) => item[idField] === args.cueId);
  }
  if (args.limitSamples) {
    selected = selected.filter((item) => item.sample_generation === true);
    if (args.sampleLimit !== null) {
      selected = selected.slice(0, args.sampleLimit);
    }
  }
  return selected;
}

async function buildJobs(args) {
  const cueData = await readJson(`data/audio_cues/${args.sceneId}.json`);
  const jobs = [];
  if (args.type === "music" || args.type === "all") {
    for (const cue of selectItems(cueData.cues || [], args, "cue_id")) {
      jobs.push({
        jobType: "music",
        id: cue.cue_id,
        sceneId: cue.scene_id,
        cue,
      });
    }
  }
  if (args.type === "voice" || args.type === "all") {
    for (const line of selectItems(cueData.voice_samples || [], args, "line_id")) {
      jobs.push({
        jobType: "voice",
        id: line.line_id,
        sceneId: line.scene_id,
        line,
      });
    }
  }
  if (args.cueId && jobs.length === 0) {
    throw new Error(`No cue or voice sample matched --cue-id ${args.cueId}`);
  }
  return jobs;
}

function printDryRun(jobs, env) {
  const ttsModel = env.MINIMAX_TTS_MODEL || "speech-2.8-hd";
  const musicModel = env.MINIMAX_MUSIC_MODEL || "music-2.6-free";
  const sanitized = jobs.map((job) => {
    if (job.jobType === "music") {
      return {
        type: "music",
        cue_id: job.cue.cue_id,
        model: musicModel,
        endpoint: MUSIC_ENDPOINT,
        prompt: truncate(job.cue.instrumentation_prompt),
        target_path: job.cue.target_path,
      };
    }
    return {
      type: "voice",
      line_id: job.line.line_id,
      character_id: job.line.character_id,
      voice_id: job.line.voice_id,
      model: ttsModel,
      endpoint: TTS_ENDPOINT,
      text: job.line.text,
      delivery: job.line.delivery,
      target_path: job.line.target_path,
    };
  });
  console.log(JSON.stringify({ dry_run: true, jobs: sanitized }, null, 2));
}

async function generateMusic(job, env) {
  const model = env.MINIMAX_MUSIC_MODEL || "music-2.6-free";
  const payload = {
    model,
    prompt: job.cue.instrumentation_prompt,
    stream: false,
    output_format: "hex",
    is_instrumental: true,
    aigc_watermark: false,
    audio_setting: {
      sample_rate: 44100,
      bitrate: 256000,
      format: "mp3",
    },
  };
  const response = await fetch(MUSIC_ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${env.MINIMAX_API_KEY}`,
    },
    body: JSON.stringify(payload),
  });
  const result = await response.json();
  if (!response.ok || result?.base_resp?.status_code !== 0) {
    throw new Error(`MiniMax music failed for ${job.id}: ${JSON.stringify(result?.base_resp || result)}`);
  }
  const audioHex = result?.data?.audio;
  if (!audioHex) {
    throw new Error(`MiniMax music returned no audio for ${job.id}`);
  }
  const outputPath = resolve(ROOT, job.cue.target_path);
  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, Buffer.from(audioHex, "hex"));
  return {
    asset_id: job.id,
    type: "music",
    provider: "minimax",
    scene_id: job.sceneId,
    cue_id: job.cue.cue_id,
    model,
    output_path: job.cue.target_path,
    prompt_summary: truncate(job.cue.instrumentation_prompt),
    status: "generated",
    generated_at: new Date().toISOString(),
    trace_id: result.trace_id || null,
    extra_info: result.extra_info || null,
  };
}

class MinimalWssClient {
  constructor(socket, initialBuffer = Buffer.alloc(0)) {
    this.socket = socket;
    this.buffer = initialBuffer;
    this.waiter = null;
    this.closed = false;
    socket.on("data", (chunk) => {
      this.buffer = Buffer.concat([this.buffer, chunk]);
      this.resolveWaiter();
    });
    socket.on("error", (error) => {
      this.rejectWaiter(error);
    });
    socket.on("close", () => {
      this.closed = true;
      this.rejectWaiter(new Error("WebSocket closed"));
    });
  }

  static async connect(endpoint, headers = {}) {
    const url = new URL(endpoint);
    if (url.protocol !== "wss:") {
      throw new Error(`Only wss:// endpoints are supported: ${endpoint}`);
    }
    const socket = tlsConnect({
      host: url.hostname,
      port: Number(url.port || 443),
      servername: url.hostname,
    });
    await new Promise((resolveConnect, rejectConnect) => {
      const timer = setTimeout(() => rejectConnect(new Error("TLS connect timed out")), 20000);
      socket.once("secureConnect", () => {
        clearTimeout(timer);
        resolveConnect();
      });
      socket.once("error", (error) => {
        clearTimeout(timer);
        rejectConnect(error);
      });
    });

    const key = randomBytes(16).toString("base64");
    const path = `${url.pathname}${url.search}`;
    const headerLines = [
      `GET ${path} HTTP/1.1`,
      `Host: ${url.host}`,
      "Upgrade: websocket",
      "Connection: Upgrade",
      `Sec-WebSocket-Key: ${key}`,
      "Sec-WebSocket-Version: 13",
      ...Object.entries(headers).map(([name, value]) => `${name}: ${value}`),
      "",
      "",
    ];
    socket.write(headerLines.join("\r\n"));

    const { statusLine, headerBlock, remaining } = await readHandshake(socket);
    if (!statusLine.includes(" 101 ")) {
      throw new Error(`WebSocket upgrade failed: ${statusLine} ${headerBlock}`.trim());
    }
    const accept = headerBlock.match(/^sec-websocket-accept:\s*(.+)$/im)?.[1]?.trim();
    const expectedAccept = createHash("sha1")
      .update(`${key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11`)
      .digest("base64");
    if (accept !== expectedAccept) {
      throw new Error("WebSocket upgrade failed: invalid Sec-WebSocket-Accept");
    }
    return new MinimalWssClient(socket, remaining);
  }

  resolveWaiter() {
    if (this.waiter) {
      const waiter = this.waiter;
      this.waiter = null;
      waiter.resolve();
    }
  }

  rejectWaiter(error) {
    if (this.waiter) {
      const waiter = this.waiter;
      this.waiter = null;
      waiter.reject(error);
    }
  }

  async waitForData(timeoutMs) {
    if (this.closed) {
      throw new Error("WebSocket closed");
    }
    if (this.waiter) {
      throw new Error("Concurrent WebSocket reads are not supported");
    }
    await new Promise((resolveWait, rejectWait) => {
      const timer = setTimeout(() => {
        this.waiter = null;
        rejectWait(new Error("WebSocket receive timed out"));
      }, timeoutMs);
      this.waiter = {
        resolve: () => {
          clearTimeout(timer);
          resolveWait();
        },
        reject: (error) => {
          clearTimeout(timer);
          rejectWait(error);
        },
      };
    });
  }

  async ensureBytes(count, timeoutMs) {
    while (this.buffer.length < count) {
      await this.waitForData(timeoutMs);
    }
  }

  async receiveJson(timeoutMs = 120000) {
    while (true) {
      const text = await this.receiveText(timeoutMs);
      try {
        return JSON.parse(text);
      } catch (error) {
        throw new Error(`Invalid WebSocket JSON: ${error.message}`);
      }
    }
  }

  async receiveText(timeoutMs) {
    const chunks = [];
    let messageOpcode = null;
    while (true) {
      const frame = await this.receiveFrame(timeoutMs);
      if (frame.opcode === 0x8) {
        this.closed = true;
        throw new Error("WebSocket closed by server");
      }
      if (frame.opcode === 0x9) {
        this.sendFrame(0xA, frame.payload);
        continue;
      }
      if (frame.opcode === 0xA) {
        continue;
      }
      if (frame.opcode === 0x1 || frame.opcode === 0x2) {
        messageOpcode = frame.opcode;
        chunks.push(frame.payload);
      } else if (frame.opcode === 0x0) {
        if (messageOpcode === null) {
          throw new Error("Unexpected WebSocket continuation frame");
        }
        chunks.push(frame.payload);
      } else {
        continue;
      }
      if (frame.fin) {
        return Buffer.concat(chunks).toString("utf8");
      }
    }
  }

  async receiveFrame(timeoutMs) {
    await this.ensureBytes(2, timeoutMs);
    const first = this.buffer[0];
    const second = this.buffer[1];
    const fin = (first & 0x80) !== 0;
    const opcode = first & 0x0f;
    const masked = (second & 0x80) !== 0;
    let length = second & 0x7f;
    let offset = 2;
    if (length === 126) {
      await this.ensureBytes(offset + 2, timeoutMs);
      length = this.buffer.readUInt16BE(offset);
      offset += 2;
    } else if (length === 127) {
      await this.ensureBytes(offset + 8, timeoutMs);
      const bigLength = this.buffer.readBigUInt64BE(offset);
      if (bigLength > BigInt(Number.MAX_SAFE_INTEGER)) {
        throw new Error("WebSocket frame is too large");
      }
      length = Number(bigLength);
      offset += 8;
    }
    const maskOffset = masked ? 4 : 0;
    await this.ensureBytes(offset + maskOffset + length, timeoutMs);
    let payload = this.buffer.subarray(offset + maskOffset, offset + maskOffset + length);
    if (masked) {
      const mask = this.buffer.subarray(offset, offset + 4);
      payload = Buffer.from(payload);
      for (let index = 0; index < payload.length; index += 1) {
        payload[index] ^= mask[index % 4];
      }
    }
    this.buffer = this.buffer.subarray(offset + maskOffset + length);
    return { fin, opcode, payload };
  }

  sendJson(data) {
    this.sendFrame(0x1, Buffer.from(JSON.stringify(data), "utf8"));
  }

  sendFrame(opcode, payload) {
    const mask = randomBytes(4);
    let header;
    if (payload.length < 126) {
      header = Buffer.alloc(2);
      header[0] = 0x80 | opcode;
      header[1] = 0x80 | payload.length;
    } else if (payload.length <= 0xffff) {
      header = Buffer.alloc(4);
      header[0] = 0x80 | opcode;
      header[1] = 0x80 | 126;
      header.writeUInt16BE(payload.length, 2);
    } else {
      header = Buffer.alloc(10);
      header[0] = 0x80 | opcode;
      header[1] = 0x80 | 127;
      header.writeBigUInt64BE(BigInt(payload.length), 2);
    }
    const maskedPayload = Buffer.from(payload);
    for (let index = 0; index < maskedPayload.length; index += 1) {
      maskedPayload[index] ^= mask[index % 4];
    }
    this.socket.write(Buffer.concat([header, mask, maskedPayload]));
  }

  close() {
    if (!this.closed) {
      this.sendFrame(0x8, Buffer.alloc(0));
      this.socket.end();
      this.closed = true;
    }
  }
}

function readHandshake(socket) {
  return new Promise((resolveHandshake, rejectHandshake) => {
    let buffer = Buffer.alloc(0);
    const timer = setTimeout(() => cleanup(new Error("WebSocket upgrade timed out")), 20000);
    const cleanup = (error, result) => {
      clearTimeout(timer);
      socket.off("data", onData);
      socket.off("error", onError);
      if (error) {
        rejectHandshake(error);
      } else {
        resolveHandshake(result);
      }
    };
    const onError = (error) => cleanup(error);
    const onData = (chunk) => {
      buffer = Buffer.concat([buffer, chunk]);
      const end = buffer.indexOf("\r\n\r\n");
      if (end < 0) {
        return;
      }
      const headerText = buffer.subarray(0, end).toString("utf8");
      const [statusLine, ...headerLines] = headerText.split("\r\n");
      cleanup(null, {
        statusLine,
        headerBlock: headerLines.join("\n"),
        remaining: buffer.subarray(end + 4),
      });
    };
    socket.on("data", onData);
    socket.once("error", onError);
  });
}

async function generateVoice(job, env) {
  const model = env.MINIMAX_TTS_MODEL || "speech-2.8-hd";
  const socket = await MinimalWssClient.connect(TTS_ENDPOINT, {
    Authorization: `Bearer ${env.MINIMAX_API_KEY}`,
  });
  const audioChunks = [];
  let traceId = null;
  try {
    const connected = await socket.receiveJson(30000);
    if (connected.event !== "connected_success") {
      throw new Error(`MiniMax TTS connection failed for ${job.id}: ${JSON.stringify(connected.base_resp || connected)}`);
    }
    traceId = connected.trace_id || null;
    socket.sendJson({
      event: "task_start",
      model,
      language_boost: "Chinese",
      voice_setting: {
        voice_id: job.line.voice_id,
        speed: job.line.speed,
        vol: job.line.vol,
        pitch: job.line.pitch,
        english_normalization: false,
      },
      audio_setting: {
        sample_rate: 32000,
        bitrate: 128000,
        format: "mp3",
        channel: 1,
      },
    });
    const started = await socket.receiveJson(30000);
    if (started.event !== "task_started") {
      throw new Error(`MiniMax TTS task failed to start for ${job.id}: ${JSON.stringify(started.base_resp || started)}`);
    }
    traceId = started.trace_id || traceId;
    socket.sendJson({ event: "task_continue", text: job.line.text });

    while (true) {
      const message = await socket.receiveJson();
      if (message.event === "task_failed") {
        throw new Error(`MiniMax TTS failed for ${job.id}: ${JSON.stringify(message.base_resp || message)}`);
      }
      traceId = message.trace_id || traceId;
      const audio = message?.data?.audio;
      if (audio) {
        audioChunks.push(Buffer.from(audio, "hex"));
      }
      if (message.is_final) {
        break;
      }
    }
    socket.sendJson({ event: "task_finish" });
    const outputPath = resolve(ROOT, job.line.target_path);
    await mkdir(dirname(outputPath), { recursive: true });
    await writeFile(outputPath, Buffer.concat(audioChunks));
    return {
      asset_id: job.id,
      type: "voice",
      provider: "minimax",
      scene_id: job.sceneId,
      line_id: job.line.line_id,
      character_id: job.line.character_id,
      voice_id: job.line.voice_id,
      model,
      output_path: job.line.target_path,
      source_text: job.line.text,
      delivery: job.line.delivery,
      status: "generated",
      generated_at: new Date().toISOString(),
      trace_id: traceId,
      extra_info: {
        byte_length: audioChunks.reduce((total, chunk) => total + chunk.length, 0),
        sample_rate: 32000,
        bitrate: 128000,
        channel: 1,
      },
    };
  } finally {
    socket.close();
  }
}

async function loadManifest(repoPath) {
  try {
    const manifest = await readJson(repoPath);
    if (!Array.isArray(manifest.assets)) {
      manifest.assets = [];
    }
    return manifest;
  } catch (error) {
    if (error.code !== "ENOENT") {
      throw error;
    }
    return { schema_version: 1, provider: "minimax", generated_at: null, assets: [] };
  }
}

function upsertAsset(manifest, asset) {
  const index = manifest.assets.findIndex((existing) => existing.asset_id === asset.asset_id);
  if (index >= 0) {
    manifest.assets[index] = asset;
  } else {
    manifest.assets.push(asset);
  }
  manifest.generated_at = new Date().toISOString();
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const env = await readEnvFile();
  const jobs = await buildJobs(args);
  if (args.dryRun) {
    printDryRun(jobs, env);
    return;
  }
  if (!env.MINIMAX_API_KEY) {
    throw new Error("MINIMAX_API_KEY is not configured. Add it to .env or export it in the shell.");
  }
  const manifest = await loadManifest(args.manifest);
  for (const job of jobs) {
    console.log(`Generating ${job.jobType} ${job.id}`);
    const asset = job.jobType === "music"
      ? await generateMusic(job, env)
      : await generateVoice(job, env);
    upsertAsset(manifest, asset);
    await writeJson(args.manifest, manifest);
    console.log(`Wrote ${asset.output_path}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
