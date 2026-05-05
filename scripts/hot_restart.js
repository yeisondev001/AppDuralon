/**
 * Envía hot restart al proceso flutter run activo vía Dart VM Service.
 * Requiere que flutter corra con:
 *   flutter run -d chrome --vmservice-port 9100 --disable-service-auth-codes
 */
const net = require('net');
const crypto = require('crypto');

const HOST = '127.0.0.1';
const PORT = 9100;
let msgId = 1;

function wsHandshake(socket) {
  const key = crypto.randomBytes(16).toString('base64');
  const req =
    'GET /ws HTTP/1.1\r\n' +
    `Host: ${HOST}:${PORT}\r\n` +
    'Upgrade: websocket\r\n' +
    'Connection: Upgrade\r\n' +
    `Sec-WebSocket-Key: ${key}\r\n` +
    'Sec-WebSocket-Version: 13\r\n\r\n';
  socket.write(req);
}

function wsSend(socket, obj) {
  const payload = Buffer.from(JSON.stringify(obj));
  const len = payload.length;
  const header = len < 126
    ? Buffer.from([0x81, 0x80 | len, 0, 0, 0, 0])
    : Buffer.from([0x81, 0xfe, (len >> 8) & 0xff, len & 0xff, 0, 0, 0, 0]);
  socket.write(Buffer.concat([header, payload]));
}

function wsFrame(buf) {
  if (buf.length < 2) return null;
  const len = buf[1] & 0x7f;
  const start = len === 126 ? 4 : 2;
  if (buf.length < start + len) return null;
  return buf.slice(start, start + len).toString();
}

function rpc(socket, method, params = {}) {
  const id = String(msgId++);
  wsSend(socket, { jsonrpc: '2.0', id, method, params });
  return id;
}

const socket = new net.Socket();
let buf = Buffer.alloc(0);
let handshakeDone = false;
let isolateId = null;

socket.connect(PORT, HOST, () => wsHandshake(socket));

socket.on('data', (chunk) => {
  buf = Buffer.concat([buf, chunk]);

  if (!handshakeDone) {
    const str = buf.toString();
    if (!str.includes('\r\n\r\n')) return;
    handshakeDone = true;
    buf = buf.slice(buf.indexOf('\r\n\r\n') + 4);
    rpc(socket, 'getVM');
    return;
  }

  const text = wsFrame(buf);
  if (!text) return;
  buf = Buffer.alloc(0);

  let msg;
  try { msg = JSON.parse(text); } catch { return; }

  const result = msg.result;
  if (!result) return;

  if (result.isolates) {
    isolateId = result.isolates[0]?.id;
    if (!isolateId) { console.error('No isolate found'); socket.destroy(); return; }
    rpc(socket, 'reloadSources', { isolateId, pause: false });
    return;
  }

  if (result.type === 'ReloadReport') {
    if (!result.success) {
      console.error('Hot reload failed:', result.notices?.map(n => n.message).join(', '));
      socket.destroy();
      return;
    }
    rpc(socket, 'callServiceExtension', {
      isolateId,
      method: 'ext.flutter.reassemble',
    });
    return;
  }

  if (result.type === '@Instance' || result.type === 'ServiceExtensionResponse') {
    console.log('✓ Hot restart OK');
    socket.destroy();
  }
});

socket.on('error', (e) => {
  console.error('VM service no disponible:', e.message);
  console.error('Asegúrate de que flutter corre con --vmservice-port 9100 --disable-service-auth-codes');
  process.exit(1);
});
