#!/usr/bin/env node
// Claude Code status line: model name + context usage progress bar.
let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (c) => (raw += c));
process.stdin.on('end', () => {
  let data = {};
  try {
    data = JSON.parse(raw || '{}');
  } catch {
    data = {};
  }

  const model = (data.model && (data.model.display_name || data.model.id)) || 'Unknown model';
  const cw = data.context_window || {};

  let pct = typeof cw.used_percentage === 'number' ? cw.used_percentage : null;
  if (pct === null) {
    const u = cw.current_usage;
    const size = cw.context_window_size;
    if (u && size) {
      const used =
        (u.input_tokens || 0) +
        (u.cache_creation_input_tokens || 0) +
        (u.cache_read_input_tokens || 0);
      pct = (used / size) * 100;
    }
  }

  const WIDTH = 10;
  let ctx;
  if (pct === null) {
    ctx = `[${'░'.repeat(WIDTH)}] --%`;
  } else {
    pct = Math.max(0, Math.min(100, pct));
    const filled = Math.round((pct / 100) * WIDTH);
    const bar = '█'.repeat(filled) + '░'.repeat(WIDTH - filled);
    const color = pct >= 80 ? '31' : pct >= 50 ? '33' : '32';
    ctx = `\x1b[${color}m[${bar}] ${Math.round(pct)}%\x1b[0m`;
  }

  process.stdout.write(`${model} | Context: ${ctx}\n`);
});
