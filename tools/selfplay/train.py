#!/usr/bin/env python3
"""Destila los JSONL de self-play en ai_policy.json.

Idea AlphaGo-lite: la victoria de una partida se propaga hacia atras sobre las
jugadas del ganador y el perdedor. La carta que sale al campo del lado que gana
gana peso; la del que pierde lo pierde, normalizado por cuantas veces se jugo y
por el rendimiento base de su mazo, para no castigar cartas buenas en mazos
malos.

Uso:
    python tools/selfplay/train.py <selfplay.jsonl> [<otro.jsonl> ...]
        [-o "PoC Data/ai_policy.json"] [--min-plays 3]
"""
import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_OUT = ROOT / "PoC Data" / "ai_policy.json"


def load_matches(paths):
    for path in paths:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if line:
                    yield json.loads(line)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("logs", nargs="+", type=Path)
    parser.add_argument("-o", "--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--min-plays", type=int, default=3,
                        help="jugadas minimas para emitir un peso")
    args = parser.parse_args()

    played_win = defaultdict(int)
    played_loss = defaultdict(int)
    deck_win = defaultdict(int)
    deck_loss = defaultdict(int)
    games = 0

    for match in load_matches(args.logs):
        winner = match.get("winner", 0)
        if winner not in (1, 2):            # 0 en curso, 3 empate: sin senal
            continue
        games += 1
        won = winner - 1                    # ganador: indice de jugador 0/1
        for p in range(2):
            for card_id in match["decks"][p]:
                (deck_win if p == won else deck_loss)[card_id] += 1
        for play in match.get("plays", []):
            (played_win if play["p"] == won else played_loss)[play["card"]] += 1

    weights = {}
    for card in set(played_win) | set(played_loss):
        plays = played_win[card] + played_loss[card]
        if plays < args.min_plays:
            continue
        decks = deck_win[card] + deck_loss[card]
        # Tasa al jugarla menos la esperada por sus mazos: valor de la decision,
        # no solo de la carta. Encogido por jugadas para ruido bajo.
        played_rate = played_win[card] / plays
        deck_rate = (deck_win[card] + 0.5) / (decks + 1) if decks else 0.5
        signal = played_rate - deck_rate
        shrink = plays / (plays + 10.0)
        weights[str(card)] = round(max(-1.0, min(1.0, signal * 2 * shrink)), 4)

    out = {"version": 1, "games": games, "cards": weights}
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(out, indent=1) + "\n", encoding="utf-8")
    top = sorted(weights.items(), key=lambda kv: -kv[1])[:10]
    print(f"{games} partidas -> {args.out}: {len(weights)} cartas con peso")
    for card, w in top:
        print(f"  {card}: {w:+.3f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
