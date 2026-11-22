// Rele PoC online para Cloudflare Workers + Durable Objects (plan gratuito).
// Una sala = un Durable Object cuyo nombre es el codigo de sala.
//   host:   wss://<worker>/?op=host            -> luego envia texto "HOST"
//   invitado: wss://<worker>/?op=join&code=XX  -> luego envia texto "JOIN XX"
// El DO acepta los dos WebSockets (Hibernation API: la sala no cobra duracion
// mientras no hay trafico) y habla el mismo protocolo que relay_server.py:
//   "ROOM <code>" al anfitrion, "GO" a ambos al enlazar, "ERR ..." en errores.
// Las tramas binarias se copian tal cual al otro lado (el protocolo del juego
// es opaco para el rele).

const ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

function makeCode() {
  const bytes = crypto.getRandomValues(new Uint8Array(6));
  return [...bytes].map((b) => ALPHABET[b % ALPHABET.length]).join("");
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("poc online relay up", { status: 200 });
    }
    const op = url.searchParams.get("op");
    let code;
    if (op === "host") {
      code = makeCode();
    } else if (op === "join") {
      code = (url.searchParams.get("code") || "").trim().toUpperCase();
    } else {
      return new Response("ERR expected ?op=host or ?op=join&code=X", { status: 400 });
    }
    if (code.length === 0) {
      return new Response("ERR missing code", { status: 400 });
    }
    const id = env.ROOMS.idFromName(code);
    return env.ROOMS.get(id).fetch(request);
  },
};

export class Room {
  constructor(state) {
    this.state = state;
  }

  async fetch(_request) {
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    // Hibernation: el DO puede dormir entre mensajes; las tramas lo despiertan.
    this.state.acceptWebSocket(server);
    return new Response(null, { status: 101, webSocket: client });
  }

  _peers() {
    return this.state.getWebSockets();
  }

  _role(ws) {
    try {
      return (ws.deserializeAttachment() || {}).role || null;
    } catch (_e) {
      return null;
    }
  }

  async webSocketMessage(ws, message) {
    if (typeof message === "string") {
      const head = message.split(" ", 1)[0];
      if (head === "HOST") {
        ws.serializeAttachment({ role: "host" });
        ws.send("ROOM " + (this.state.id.name || ""));
      } else if (head === "JOIN") {
        const roles = this._peers().map((p) => this._role(p));
        if (!roles.includes("host")) {
          ws.send("ERR no such room");
        } else if (roles.includes("guest")) {
          ws.send("ERR room full");
        } else {
          ws.serializeAttachment({ role: "guest" });
          for (const p of this._peers()) p.send("GO");
        }
      }
      return;
    }
    // Trama binaria del juego: copia al otro lado.
    for (const p of this._peers()) {
      if (p !== ws) p.send(message);
    }
  }

  async webSocketClose(ws, _code, _reason, _wasClean) {
    this._dropPartner(ws);
  }

  async webSocketError(ws, _error) {
    this._dropPartner(ws);
  }

  _dropPartner(ws) {
    for (const p of this._peers()) {
      if (p !== ws) {
        try {
          p.close(1000, "peer left");
        } catch (_e) {
          // ya cerrado
        }
      }
    }
  }
}
