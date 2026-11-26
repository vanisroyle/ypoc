// Rele PoC online para Cloudflare Workers + Durable Objects (plan gratuito).
// Una sala = un Durable Object cuyo nombre es el codigo de sala; las salas
// publicas se registran en un DO unico (RoomList, nombre "__list__").
//   host:     wss://<worker>/?op=host            -> luego texto "HOST" o "HOST PUB"
//   invitado: wss://<worker>/?op=join&code=XX    -> luego texto "JOIN XX"
//   explorar: wss://<worker>/?op=list            -> luego texto "LIST" -> "GAMES ..."
// El DO acepta los dos WebSockets (Hibernation API: la sala no cobra duracion
// mientras no hay trafico) y habla el mismo protocolo que relay_server.py:
//   "ROOM <code>" al anfitrion, "GO" a ambos al enlazar, "ERR ..." en errores.
// Las tramas binarias se copian tal cual al otro lado (el protocolo del juego
// es opaco para el rele). Tras "GAMES" el cliente vuelve a conectar con op=join.

const ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
const LIST_ID = "__list__";

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
    } else if (op === "list") {
      const listId = env.LISTS.idFromName(LIST_ID);
      return env.LISTS.get(listId).fetch(request);
    } else {
      return new Response("ERR expected ?op=host, ?op=join&code=X or ?op=list", { status: 400 });
    }
    if (code.length === 0) {
      return new Response("ERR missing code", { status: 400 });
    }
    const id = env.ROOMS.idFromName(code);
    return env.ROOMS.get(id).fetch(request);
  },
};

export class Room {
  constructor(state, env) {
    this.state = state;
    this.env = env;
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

  _att(ws) {
    try {
      return ws.deserializeAttachment() || {};
    } catch (_e) {
      return {};
    }
  }

  _setListed(listed) {
    // Registro del codigo en el DO lista; fire-and-forget bajo waitUntil.
    const url = "https://do/?code=" + (this.state.id.name || "") +
      "&add=" + (listed ? "1" : "0");
    this.state.waitUntil(this.env.LISTS.get(this.env.LISTS.idFromName(LIST_ID)).fetch(url));
  }

  async webSocketMessage(ws, message) {
    if (typeof message === "string") {
      const head = message.split(" ", 1)[0];
      if (head === "HOST") {
        const pub = message.trim().toUpperCase().endsWith("PUB");
        ws.serializeAttachment({ role: "host", pub });
        if (pub) this._setListed(true);
        ws.send("ROOM " + (this.state.id.name || ""));
      } else if (head === "JOIN") {
        const roles = this._peers().map((p) => this._role(p));
        if (!roles.includes("host")) {
          ws.send("ERR no such room");
          ws.close(4000, "no such room");
        } else if (roles.includes("guest")) {
          ws.send("ERR room full");
          ws.close(4000, "room full");
        } else {
          ws.serializeAttachment({ role: "guest" });
          this._setListed(false);
          for (const p of this._peers()) p.send("GO");
        }
      }
      return;
    }
    // Trama binaria del juego: copia al otro lado. Solo entre sockets con rol:
    // un tercero rechazado no puede leer ni inyectar paquetes de la partida.
    if (!this._role(ws)) return;
    for (const p of this._peers()) {
      if (p !== ws && this._role(p)) p.send(message);
    }
  }

  async webSocketClose(ws, _code, _reason, _wasClean) {
    this._dropPartner(ws);
  }

  async webSocketError(ws, _error) {
    this._dropPartner(ws);
  }

  _dropPartner(ws) {
    const att = this._att(ws);
    if (!att.role) return; // socket sin rol: no arrastra a la partida
    if (att.role === "host" && att.pub) this._setListed(false);
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

// RoomList: registro de salas publicas con hueco (binding LISTS, nombre fijo);
// solo atiende LIST por WebSocket y altas/bajas por fetch.
export class RoomList {
  constructor(state) {
    this.state = state;
    this.codes = null;
  }

  async _load() {
    if (this.codes === null) {
      this.codes = new Set(await this.state.storage.get("codes") || []);
    }
  }

  async fetch(request) {
    const url = new URL(request.url);
    const code = url.searchParams.get("code");
    if (request.headers.get("Upgrade") !== "websocket") {
      // Registro interno desde Room: ?code=X&add=1|0
      if (code) {
        await this._load();
        if (url.searchParams.get("add") === "1") this.codes.add(code);
        else this.codes.delete(code);
        await this.state.storage.put("codes", [...this.codes]);
      }
      return new Response("ok", { status: 200 });
    }
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    this.state.acceptWebSocket(server);
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(ws, message) {
    if (typeof message === "string" && message.trim() === "LIST") {
      await this._load();
      const list = [...this.codes];
      ws.send("GAMES" + (list.length ? " " + list.join(" ") : ""));
    }
  }
}
