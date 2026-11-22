// Relay PoC online: dos jugadores conectan de salida, el anfitrion abre una
// sala y el invitado entra por codigo o desde la lista publica. El rele copia
// las tramas binarias del juego entre ambos (nunca mira su contenido).
//
// Protocolo de texto antes de enlazar (los ?op=... de la URL solo los usa el
// backend de Cloudflare Workers; aqui bastan las tramas):
//
//	cliente -> "HOST"        sala privada   servidor -> "ROOM ABCDEF"
//	cliente -> "HOST PUB"    sala publica   servidor -> "ROOM ABCDEF"
//	cliente -> "LIST"                       servidor -> "GAMES ABCDEF XYZ123"
//	cliente -> "JOIN ABCDEF"                servidor -> "GO" a ambos | "ERR ..."
//
// Endurecimiento: tope global y por IP de conexiones, expiracion de salas sin
// enlazar y, opcional, una clave compartida por ?key= en la URL.
package main

import (
	"context"
	"crypto/rand"
	"flag"
	"log"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/coder/websocket"
)

const alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"

func newCode() string {
	var b [6]byte
	rand.Read(b[:])
	var code [6]byte
	for i, v := range b {
		code[i] = alphabet[int(v)%len(alphabet)]
	}
	return string(code[:])
}

type conn struct {
	ws    *websocket.Conn
	ip    string
	mu    sync.Mutex // serializa ws.Write y los campos de abajo
	peer  *conn
	room  *room
	role  string // "host" | "guest"
	alive bool
}

func (c *conn) send(mt websocket.MessageType, data []byte) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if !c.alive {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	c.ws.Write(ctx, mt, data) //nolint: si falla, la conexion muere en su read
}

type room struct {
	code    string
	host    *conn
	guest   *conn
	public  bool
	created time.Time
}

var (
	roomsMu    sync.Mutex
	rooms      = map[string]*room{}
	connsMu    sync.Mutex
	ipConns    = map[string]int{}
	totalConns int

	maxConns = flag.Int("maxconn", 1024, "conexiones simultaneas totales")
	maxPerIP = flag.Int("maxip", 16, "conexiones simultaneas por IP (las dos instancias de una prueba local cuentan)")
	roomTTL  = flag.Duration("roomttl", 10*time.Minute, "vida de una sala sin enlazar")
	secret   = flag.String("key", "", "clave compartida; si se pone, los clientes deben mandar ?key=")
	trustFwd = flag.Bool("trustproxy", false, "confiar en Fly-Client-IP/X-Forwarded-For (solo detras de un proxy que los reescriba)")
)

func main() {
	addr := flag.String("addr", ":8765", "direccion de escucha")
	flag.Parse()
	go sweep()
	mux := http.NewServeMux()
	mux.HandleFunc("/", handle)
	log.Printf("[relay] escuchando en %s (maxconn=%d maxip=%d roomttl=%s key=%v)",
		*addr, *maxConns, *maxPerIP, *roomTTL, *secret != "")
	log.Fatal(http.ListenAndServe(*addr, mux))
}

// clientIP usa la direccion remota salvo que -trustproxy lo permita: solo un
// proxy que reescribe las cabeceras (Fly.io fija Fly-Client-IP) debe habilitar
// esto; en un despliegue directo un cliente podria rotar las cabeceras y
// saltarse -maxip.
func clientIP(r *http.Request) string {
	if *trustFwd {
		if ip := r.Header.Get("Fly-Client-IP"); ip != "" {
			return ip
		}
		if fwd := r.Header.Get("X-Forwarded-For"); fwd != "" {
			return strings.TrimSpace(strings.SplitN(fwd, ",", 2)[0])
		}
	}
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

func handle(w http.ResponseWriter, r *http.Request) {
	if !strings.EqualFold(r.Header.Get("Upgrade"), "websocket") {
		w.Write([]byte("poc online relay up"))
		return
	}
	if *secret != "" && r.URL.Query().Get("key") != *secret {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	ip := clientIP(r)
	connsMu.Lock()
	if totalConns >= *maxConns || ipConns[ip] >= *maxPerIP {
		connsMu.Unlock()
		http.Error(w, "too many connections", http.StatusTooManyRequests)
		return
	}
	totalConns++
	ipConns[ip]++
	connsMu.Unlock()

	ws, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		InsecureSkipVerify: true, // el relay no restringe origenes
	})
	if err != nil {
		release(ip)
		return
	}
	ws.SetReadLimit(1 << 20)
	go serve(ws, ip)
}

func release(ip string) {
	connsMu.Lock()
	totalConns--
	if ipConns[ip] <= 1 {
		delete(ipConns, ip)
	} else {
		ipConns[ip]--
	}
	connsMu.Unlock()
}

// sweep tumba las salas que no consiguen invitado en roomTTL.
func sweep() {
	tick := time.NewTicker(30 * time.Second)
	defer tick.Stop()
	for range tick.C {
		roomsMu.Lock()
		var stale []*room
		for _, r := range rooms {
			if r.guest == nil && time.Since(r.created) > *roomTTL {
				stale = append(stale, r)
				delete(rooms, r.code)
			}
		}
		roomsMu.Unlock()
		for _, r := range stale {
			log.Printf("[relay] sala %s expirada", r.code)
			r.host.mu.Lock()
			r.host.room = nil
			r.host.ws.Close(websocket.StatusNormalClosure, "room expired")
			r.host.mu.Unlock()
		}
	}
}

func serve(ws *websocket.Conn, ip string) {
	c := &conn{ws: ws, ip: ip, alive: true}
	defer func() { drop(c); release(ip) }()
	for {
		mt, data, err := ws.Read(context.Background())
		if err != nil {
			return
		}
		if mt == websocket.MessageText {
			if !control(c, string(data)) {
				return
			}
			continue
		}
		// Trama binaria del juego: copia tal cual al otro lado.
		if c.peer != nil {
			c.peer.send(websocket.MessageBinary, data)
		}
	}
}

// control procesa HOST/LIST/JOIN; devuelve false si la conexion debe morir.
// Una conexion solo registra una vez: no puede abrir mas salas ni ser host e
// invitado a la vez (salvo LIST, que es de solo lectura).
func control(c *conn, text string) bool {
	head := strings.SplitN(text, " ", 2)[0]
	switch head {
	case "LIST":
		var names []string
		roomsMu.Lock()
		for _, r := range rooms {
			if r.public && r.guest == nil {
				names = append(names, r.code)
			}
		}
		roomsMu.Unlock()
		c.send(websocket.MessageText, []byte("GAMES "+strings.Join(names, " ")))
		return true
	}
	if c.room != nil {
		c.send(websocket.MessageText, []byte("ERR already registered"))
		return false
	}
	switch head {
	case "HOST":
		public := len(strings.Fields(text)) > 1 && strings.Fields(text)[1] == "PUB"
		r := &room{code: newCode(), host: c, public: public, created: time.Now()}
		roomsMu.Lock()
		rooms[r.code] = r
		roomsMu.Unlock()
		c.room = r
		c.role = "host"
		c.send(websocket.MessageText, []byte("ROOM "+r.code))
		log.Printf("[relay] sala %s abierta (public=%v)", r.code, public)
	case "JOIN":
		code := ""
		if parts := strings.SplitN(text, " ", 2); len(parts) == 2 {
			code = strings.ToUpper(strings.TrimSpace(parts[1]))
		}
		roomsMu.Lock()
		r, ok := rooms[code]
		full := ok && r.guest != nil
		dead := false
		if ok && !full {
			// El anfitrion pudo morir justo antes de este JOIN: comprobar su
			// estado bajo su propio mutex para no enlazar a un cadaver.
			r.host.mu.Lock()
			dead = !r.host.alive
			if !dead {
				r.guest = c
				r.host.peer = c
			}
			r.host.mu.Unlock()
			if !dead {
				c.peer = r.host
			}
		}
		roomsMu.Unlock()
		switch {
		case !ok || dead:
			c.send(websocket.MessageText, []byte("ERR no such room"))
			return false
		case full:
			c.send(websocket.MessageText, []byte("ERR room full"))
			return false
		}
		c.room = r
		c.role = "guest"
		c.send(websocket.MessageText, []byte("GO"))
		r.host.send(websocket.MessageText, []byte("GO"))
		log.Printf("[relay] sala %s enlazada", code)
	default:
		c.send(websocket.MessageText, []byte("ERR expected HOST [PUB], LIST or JOIN <code>"))
		return false
	}
	return true
}

// drop cierra la conexion, tumba la sala y avisa al otro lado cerrandolo.
func drop(c *conn) {
	c.mu.Lock()
	if !c.alive {
		c.mu.Unlock()
		return
	}
	c.alive = false
	c.ws.Close(websocket.StatusNormalClosure, "bye")
	r, peer := c.room, c.peer
	c.mu.Unlock()
	if r != nil {
		roomsMu.Lock()
		if rooms[r.code] == r {
			delete(rooms, r.code)
		}
		roomsMu.Unlock()
		log.Printf("[relay] sala %s cerrada", r.code)
	}
	if peer != nil {
		peer.mu.Lock()
		peer.ws.Close(websocket.StatusNormalClosure, "peer left")
		peer.mu.Unlock()
	}
}
