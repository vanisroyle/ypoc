#!/usr/bin/env python3
"""Genera game/ai_decks/<juego>/<nombre>.json desde listas de la comunidad.
Uso: python3 tools/gen_ai_decks.py  (lee PoC Data/resources/common/db/cards.json)"""
import json, os, re, sys

ROOT = os.path.join(os.path.dirname(__file__), "..")
CARDS = json.load(open(os.path.join(ROOT, "PoC Data/resources/common/db/cards.json")))
PACK = {"yugi": 1, "kaiba": 2, "joey": 4}
USABLE = {"yugi": 1 | 2, "kaiba": 1 | 2, "joey": 1 | 2 | 4}

def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())

BY_NAME = {}
for c in CARDS:
    BY_NAME.setdefault(norm(c["names"].get("eng", "")), []).append(c)

def resolve(count, name, pool):
    cs = BY_NAME.get(norm(name), [])
    ok = [c for c in cs if c["pack"] & pool]
    if not ok:
        print(f"  !! fuera del pool o nombre mal: {count}x {name}")
        return []
    return [ok[0]["internal_id"]] * count

DECKS = {
    "joey/community_mill": [
        (3,"Nimble Momonga"),(3,"Spear Cretin"),(3,"Needle Worm"),(2,"Morphing Jar"),
        (1,"Morphing Jar 2"),(2,"Magician of Faith"),(1,"Cyber Jar"),(1,"Banisher of the Light"),
        (1,"Sangan"),(1,"Witch of the Black Forest"),(1,"Penguin Soldier"),
        (3,"Gravekeeper's Servant"),(2,"The Dark Door"),(1,"Swords of Revealing Light"),
        (1,"Raigeki"),(1,"Dark Hole"),(1,"Pot of Greed"),(1,"Graceful Charity"),
        (2,"Mystical Space Typhoon"),(1,"Card Destruction"),(1,"Monster Reborn"),
        (1,"Mirror Force"),(2,"Gravity Bind"),(1,"Magic Jammer"),(1,"Imperial Order"),
    ],
    "joey/community_beatdown": [
        (3,"Gemini Elf"),(3,"La Jinn the Mystical Genie of the Lamp"),(3,"Mechanicalchaser"),
        (3,"7 Colored Fish"),(2,"Summoned Skull"),(1,"Jinzo"),(2,"Vorse Raider"),
        (1,"Zombyra the Dark"),(1,"Sangan"),(1,"Witch of the Black Forest"),
        (1,"Raigeki"),(1,"Dark Hole"),(1,"Monster Reborn"),(1,"Pot of Greed"),
        (1,"Graceful Charity"),(1,"Change of Heart"),(1,"Snatch Steal"),
        (2,"Mystical Space Typhoon"),(1,"Harpie's Feather Duster"),(1,"Premature Burial"),
        (1,"Scapegoat"),(1,"United We Stand"),(1,"Mirror Force"),(1,"Call of the Haunted"),
        (1,"Imperial Order"),(2,"Magic Jammer"),(1,"Torrential Tribute"),
    ],
    "joey/community_exodia": [
        (1,"Exodia the Forbidden One"),(1,"Right Arm of the Forbidden One"),
        (1,"Left Arm of the Forbidden One"),(1,"Right Leg of the Forbidden One"),
        (1,"Left Leg of the Forbidden One"),(3,"Thunder Dragon"),(3,"Spear Cretin"),
        (2,"Magician of Faith"),(3,"Nimble Momonga"),(1,"Sangan"),
        (1,"Witch of the Black Forest"),(1,"Morphing Jar"),(1,"Copycat"),
        (1,"Pot of Greed"),(1,"Graceful Charity"),(1,"Upstart Goblin"),(1,"Painful Choice"),
        (1,"Dark Hole"),(1,"Raigeki"),(1,"Monster Reborn"),(1,"Premature Burial"),
        (2,"The Shallow Grave"),(2,"Card of Safe Return"),(1,"Last Will"),
        (2,"Backup Soldier"),(1,"Magical Hats"),(2,"Time Machine"),(1,"Call of the Haunted"),
        (1,"Torrential Tribute"),
    ],
    "joey/community_hand_control": [
        (2,"Goblin Attack Force"),(2,"The Fiend Megacyber"),(1,"Zombyra the Dark"),
        (1,"Summoned Skull"),(1,"Big Shield Gardna"),(2,"Slate Warrior"),(1,"Barrel Dragon"),
        (2,"Penguin Soldier"),(2,"White Magical Hat"),(1,"Sangan"),(1,"Witch of the Black Forest"),
        (1,"Confiscation"),(1,"Delinquent Duo"),(1,"The Forceful Sentry"),(1,"Graceful Charity"),
        (1,"Pot of Greed"),(1,"Monster Reborn"),(1,"Mystical Space Typhoon"),(1,"Raigeki"),
        (1,"Dark Hole"),(1,"Change of Heart"),(1,"Swords of Revealing Light"),(1,"Scapegoat"),
        (3,"Robbin' Goblin"),(2,"Magic Drain"),(3,"Time Seal"),(1,"Fairy Box"),
        (1,"Mirror Force"),(1,"Call of the Haunted"),
    ],
    "kaiba/community_dragon": [
        (3,"Blue-Eyes White Dragon"),(2,"Kaiser Dragon"),(3,"La Jinn the Mystical Genie of the Lamp"),
        (3,"Battle Ox"),(2,"Swordstalker"),(1,"Sangan"),(1,"Witch of the Black Forest"),
        (1,"Raigeki"),(1,"Dark Hole"),(1,"Monster Reborn"),(1,"Pot of Greed"),
        (1,"Change of Heart"),(1,"Snatch Steal"),(2,"Mystical Space Typhoon"),
        (1,"Megamorph"),(1,"Mirror Force"),(2,"Magic Jammer"),
    ],
    "kaiba/community_beatdown": [
        (3,"La Jinn the Mystical Genie of the Lamp"),(3,"Battle Ox"),(3,"Swordstalker"),
        (2,"Judge Man"),(2,"Aqua Madoor"),(1,"Sangan"),
        (1,"Witch of the Black Forest"),(1,"Raigeki"),(1,"Dark Hole"),(1,"Monster Reborn"),
        (1,"Pot of Greed"),(1,"Change of Heart"),(1,"Snatch Steal"),
        (2,"Mystical Space Typhoon"),(1,"Megamorph"),(1,"Fissure"),(1,"Mirror Force"),
        (2,"Magic Jammer"),(1,"Trap Hole"),
    ],
    "yugi/community_spellcaster": [
        (2,"Dark Magician"),(2,"Summoned Skull"),(3,"Battle Ox"),(3,"Silver Fang"),
        (2,"Mystical Elf"),(1,"Sangan"),(1,"Witch of the Black Forest"),(2,"Man-Eater Bug"),
        (1,"Raigeki"),(1,"Dark Hole"),(1,"Monster Reborn"),(1,"Pot of Greed"),
        (1,"Change of Heart"),(1,"Snatch Steal"),(2,"Mystical Space Typhoon"),
        (1,"Fissure"),(1,"Swords of Revealing Light"),(1,"Mirror Force"),
        (2,"Magic Jammer"),(3,"Trap Hole"),(2,"Waboku"),
    ],
    "yugi/community_stall": [
        (3,"Mystical Elf"),(3,"Giant Soldier of Stone"),(2,"Winged Dragon, Guardian of the Fortress #1"),
        (2,"Battle Ox"),(2,"Man-Eater Bug"),(1,"Sangan"),(1,"Witch of the Black Forest"),
        (2,"Hane-Hane"),(1,"Raigeki"),(1,"Dark Hole"),(1,"Monster Reborn"),(1,"Pot of Greed"),
        (1,"Fissure"),(1,"Swords of Revealing Light"),(1,"Change of Heart"),
        (1,"Mirror Force"),(2,"Magic Jammer"),(3,"Trap Hole"),
        (3,"Waboku"),(2,"Reinforcements"),
    ],
}

def pad(main, game, target=40):
    """Rellena con los atacantes de <=4* mas fuertes del pool (max 3 copias)."""
    pool = USABLE[game]
    mons = [c for c in CARDS if c["pack"] & pool and c["category"] == "monster"
            and c.get("level", 99) <= 4]
    mons.sort(key=lambda c: -c.get("atk", 0))
    for c in mons:
        while len(main) < target and main.count(c["internal_id"]) < 3:
            main.append(c["internal_id"])
        if len(main) >= target:
            break
    return main

for key, lst in DECKS.items():
    game, name = key.split("/")
    pool = USABLE[game]
    main = []
    for count, card_name in lst:
        main += resolve(count, card_name, pool)
    main = pad(main, game)
    out = os.path.join(ROOT, "game/ai_decks", game, name + ".json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump({"main": main, "side": [], "fusion": []}, open(out, "w"))
    print(f"{key}: {len(main)} cartas ({len(set(main))} unicas)")
