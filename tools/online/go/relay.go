// Relay PoC online: dos jugadores conectan de salida, el anfitrion abre una
// sala con codigo de 6 letras y el invitado entra por codigo. El rele copia las
// tramas binarias del juego entre ambos (nunca mira su contenido).
//
// Protocolo de texto antes de enlazar (igual que relay_server.py / worker.js):
//
//	cliente -> "HOST"           servidor -> "ROOM ABCDEF"
//	cliente -> "JOIN ABCDEF"    servidor -> "GO" a ambos | "ERR ..."
//
// Los parametros ?op=host|join&code=... de la URL se ignoran (los usa el
// backend de Cloudflare Workers); aqui basta la trama de texto.
package main

import (
	"context"
	"crypto/rand"
	"flag"
	"log"
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
	mu    sync.Mutex // serializa ws.Write
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
	c.ws.Write(ctx, mt, data) //nolint: el peer muere igualmente
}

type room struct {
	code  string
	host  *conn
	guest *conn
}

var (
	roomsMu sync.Mutex
	rooms   = map[string]*room{}
)

func main() {
	addr := flag.String("addr", ":8765", "direccion de escucha")
	flag.Parse()
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if !strings.EqualFold(r.Header.Get("Upgrade"), "websocket") {
			w.Write([]byte("poc online relay up"))
			return
		}
		ws, err := websocket.Accept(w, r, &websocket.AcceptOptions{
			InsecureSkipVerify: true, // el relay no restringe origenes
		})
		if err != nil {
			return
		}
		ws.SetReadLimit(1 << 20)
		go serve(ws)
	})
	log.Printf("[relay] escuchando en %s", *addr)
	log.Fatal(http.ListenAndServe(*addr, mux))
}

func serve(ws *websocket.Conn) {
	c := &conn{ws: ws, alive: true}
	defer func() { drop(c) }()
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

// control procesa HOST/JOIN; devuelve false si la conexion debe morir.
func control(c *conn, text string) bool {
	head := strings.SplitN(text, " ", 2)[0]
	switch head {
	case "HOST":
		r := &room{code: newCode(), host: c}
		roomsMu.Lock()
		rooms[r.code] = r
		roomsMu.Unlock()
		c.room = r
		c.role = "host"
		c.send(websocket.MessageText, []byte("ROOM "+r.code))
		log.Printf("[relay] sala %s abierta", r.code)
	case "JOIN":
		code := ""
		if parts := strings.SplitN(text, " ", 2); len(parts) == 2 {
			code = strings.ToUpper(strings.TrimSpace(parts[1]))
		}
		roomsMu.Lock()
		r, ok := rooms[code]
		full := ok && r.guest != nil
		if ok && !full {
			r.guest = c
			c.peer, r.host.peer = r.host, c
		}
		roomsMu.Unlock()
		switch {
		case !ok:
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
		c.send(websocket.MessageText, []byte("ERR expected HOST or JOIN <code>"))
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
