#!/usr/bin/env python3
"""Writes the data files of Bajie's food stall: scenes/diner/data/*/*.tres and the translation keys.

Edit the tables below and run:  python3 tools/gen_diner_data.py
Keys that are missing in localization/translations.csv are appended (existing ones are never changed).
"""
import csv
import os
import shutil

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "scenes", "diner", "data")
SCRIPTS = "res://scripts/diner/"

# id, icon, price at the market, (en, de, zh)
INGREDIENTS = [
    ("peach", "🍑", 4, ("Peach", "Pfirsich", "桃子")),
    ("rice", "🍚", 2, ("Rice", "Reis", "大米")),
    ("tofu", "⬜", 4, ("Tofu", "Tofu", "豆腐")),
    ("bamboo", "🎋", 3, ("Bamboo shoots", "Bambussprossen", "竹笋")),
    ("mushroom", "🍄", 4, ("Mushrooms", "Pilze", "蘑菇")),
    ("ginger", "🫚", 3, ("Ginger", "Ingwer", "生姜")),
    ("honey", "🍯", 6, ("Honey", "Honig", "蜂蜜")),
    ("chili", "🌶", 4, ("Chili", "Chili", "辣椒")),
]

# id, icon, {ingredient: count}, tags, price, cook seconds, unlocked by guest, (en, de, zh)
DISHES = [
    ("rice_bowl", "🍚", {"rice": 2}, ["hearty", "hot"], 5, 6.0, "", ("Rice bowl", "Reisschüssel", "米饭碗")),
    ("peach_bun", "🥟", {"peach": 2, "rice": 1}, ["sweet", "soft"], 9, 8.0, "", ("Peach bun", "Pfirsichbrötchen", "桃子包")),
    ("tofu_soup", "🍲", {"tofu": 2, "ginger": 1}, ["hot", "light"], 10, 9.0, "", ("Tofu soup", "Tofusuppe", "豆腐汤")),
    ("mushroom_dumplings", "🥟", {"mushroom": 2, "rice": 1}, ["savory", "soft"], 12, 10.0, "villager", ("Mushroom dumplings", "Pilzteigtaschen", "蘑菇饺子")),
    ("bamboo_stirfry", "🥢", {"bamboo": 2, "mushroom": 1}, ["savory", "crunchy"], 13, 10.0, "crane", ("Bamboo stir-fry", "Bambus-Pfanne", "炒竹笋")),
    ("cold_peach_dessert", "🍧", {"peach": 2, "honey": 1}, ["sweet", "cold"], 15, 9.0, "hungry_ghost", ("Cold peach dessert", "Kaltes Pfirsichdessert", "冰桃甜品")),
    ("honey_cake", "🍰", {"honey": 1, "peach": 1, "rice": 1}, ["sweet", "hot", "soft"], 16, 11.0, "fox_spirit", ("Honey cake", "Honigkuchen", "蜂蜜糕")),
    ("spicy_pot", "🍛", {"chili": 2, "tofu": 1, "mushroom": 1}, ["spicy", "hot", "hearty"], 19, 13.0, "ogre", ("Spicy pot", "Scharfer Topf", "麻辣锅")),
]

# id, icon, likes, dislikes, patience, friendship needed, appears after served, gift (ingredient, amount, every N visits), weight, names
GUESTS = [
    ("villager", "🧑‍🌾", ["hearty", "hot"], ["spicy"], 55.0, 4, 0, ("rice", 3, 3), 3.0, ("Villager", "Dorfbewohner", "村民")),
    ("hungry_ghost", "👻", ["cold", "sweet"], ["hot"], 45.0, 5, 4, ("peach", 2, 4), 2.0, ("Hungry ghost", "Hungriger Geist", "饿鬼")),
    ("fox_spirit", "🦊", ["sweet", "soft"], ["spicy"], 40.0, 5, 10, ("honey", 1, 4), 2.0, ("Fox spirit", "Fuchsgeist", "狐仙")),
    ("crane", "🕊", ["light", "crunchy"], ["hearty"], 45.0, 6, 18, ("bamboo", 3, 4), 1.5, ("Crane spirit", "Kranichgeist", "仙鹤")),
    ("ogre", "👹", ["spicy", "hearty"], ["light"], 35.0, 6, 28, ("chili", 3, 4), 1.5, ("Ogre", "Oger", "山妖")),
    ("turtle", "🐢", ["savory", "hot"], ["cold"], 70.0, 7, 40, ("mushroom", 3, 4), 1.0, ("Old turtle", "Alte Schildkröte", "老龟")),
]

# id, icon, seconds, {ingredient: (min, max)}, appears after served, names
EXPEDITIONS = [
    ("rice_terraces", "🌾", 60.0, {"rice": (6, 9)}, 0, ("Rice terraces", "Reisterrassen", "梯田")),
    ("peach_grove", "🌳", 75.0, {"peach": (4, 6), "honey": (0, 1)}, 0, ("Peach grove", "Pfirsichhain", "桃林")),
    ("bamboo_forest", "🎍", 90.0, {"bamboo": (4, 6), "mushroom": (1, 3)}, 6, ("Bamboo forest", "Bambuswald", "竹林")),
    ("spice_slope", "⛰", 120.0, {"ginger": (2, 3), "chili": (2, 4), "honey": (1, 2)}, 15, ("Spice slope", "Gewürzhang", "香料坡")),
]

# id, icon, effect, base cost, growth, max level, amount per level, names
UPGRADES = [
    ("seats", "🪑", "SEATS", 40, 2.2, 4, 1.0, ("More seats", "Mehr Sitzplätze", "更多座位")),
    ("cook_speed", "🔥", "COOK_SPEED", 30, 1.8, 8, 0.10, ("Faster stove", "Schnellerer Herd", "更快的灶")),
    ("arrival_speed", "🏮", "ARRIVAL_SPEED", 35, 1.7, 8, 0.08, ("Bigger lantern", "Größere Laterne", "更大的灯笼")),
    ("snack_guard", "🥢", "SNACK_GUARD", 50, 2.0, 5, 0.20, ("Hands off!", "Finger weg!", "不许偷吃")),
]

UI = {
    "DINER_TITLE": ("Bajie's Food Stall", "Bajies Imbiss", "八戒小吃摊"),
    "DINER_COINS": ("Coins: %d", "Münzen: %d", "铜钱：%d"),
    "DINER_STOCK": ("Pantry", "Vorrat", "库存"),
    "DINER_QUEUE": ("Guests", "Gäste", "客人"),
    "DINER_NOBODY": ("Nobody here yet …", "Noch niemand da …", "还没有客人……"),
    "DINER_COOKING": ("Bajie is cooking: %s (%d s)", "Bajie kocht: %s (%d s)", "八戒正在做：%s（%d 秒）"),
    "DINER_IDLE_COOK": ("Bajie is waiting for orders.", "Bajie wartet auf Bestellungen.", "八戒在等订单。"),
    "DINER_MARKET": ("Market", "Markt", "集市"),
    "DINER_BUY": ("Buy %s (%d coins)", "%s kaufen (%d Münzen)", "购买%s（%d铜钱）"),
    "DINER_TRIPS": ("Wukong's day trips", "Wukongs Tagesausflüge", "悟空的远行"),
    "DINER_TRIP_START": ("%s (%d s)", "%s (%d s)", "%s（%d秒）"),
    "DINER_TRIP_RUNNING": ("%s: back in %d s", "%s: zurück in %d s", "%s：%d秒后回来"),
    "DINER_UPGRADES": ("Upgrades", "Verbesserungen", "升级"),
    "DINER_UPGRADE_BUY": ("%s – level %d/%d (%d coins)", "%s – Stufe %d/%d (%d Münzen)", "%s – %d/%d级（%d铜钱）"),
    "DINER_UPGRADE_MAX": ("%s – maxed", "%s – am Maximum", "%s – 已满级"),
    "DINER_REGULARS": ("Regulars: %s", "Stammgäste: %s", "常客：%s"),
    "DINER_NO_REGULARS": ("none yet", "noch keine", "暂无"),
    "DINER_SERVED": ("Served: %d", "Bedient: %d", "已招待：%d"),
    "DINER_FASTER": ("Test: speed x%d", "Test: Tempo x%d", "测试：速度x%d"),
    "DINER_EVENT_REGULAR": ("%s is a regular now!", "%s ist jetzt Stammgast!", "%s成了常客！"),
    "DINER_EVENT_RECIPE": ("New recipe: %s", "Neues Rezept: %s", "新菜谱：%s"),
    "DINER_EVENT_LEFT": ("%s left hungry.", "%s ging hungrig davon.", "%s饿着肚子走了。"),
    "DINER_EVENT_SNACK": ("Bajie nibbled some of the %s!", "Bajie hat vom %s genascht!", "八戒偷吃了一口%s！"),
    "DINER_EVENT_GIFT": ("%s brought %d x %s.", "%s brachte %d x %s mit.", "%s带来了%d个%s。"),
    "DINER_EVENT_TRIP_HOME": ("Wukong is back from the %s!", "Wukong ist zurück von: %s!", "悟空从%s回来了！"),
    "DINER_EVENT_OFFLINE": ("While you were away: %d guests, +%d coins.", "Während du weg warst: %d Gäste, +%d Münzen.", "你不在时：%d位客人，+%d铜钱。"),
    "DINER_SERVE": ("Serve:", "Servieren:", "上菜："),
    "TAG_SWEET": ("sweet", "süß", "甜"),
    "TAG_SAVORY": ("savory", "herzhaft-würzig", "咸香"),
    "TAG_HOT": ("hot", "heiß", "热"),
    "TAG_COLD": ("cold", "kalt", "冷"),
    "TAG_SPICY": ("spicy", "scharf", "辣"),
    "TAG_HEARTY": ("hearty", "deftig", "实在"),
    "TAG_LIGHT": ("light", "leicht", "清淡"),
    "TAG_SOFT": ("soft", "weich", "软"),
    "TAG_CRUNCHY": ("crunchy", "knusprig", "脆"),
    "DINER_LIKES": ("likes", "mag", "喜欢"),
    "DINER_DISLIKES": ("dislikes", "mag nicht", "讨厌"),
    "DINER_HAPPY": ("Happy!", "Glücklich!", "满意！"),
    "DINER_OKAY": ("Okay.", "Geht so.", "还行。"),
    "DINER_NOT_HAPPY": ("Not what I wanted …", "Nicht, was ich wollte …", "不是我想要的……"),
}


def q(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def packed(items):
    return "PackedStringArray(" + ", ".join(q(i) for i in items) + ")" if items else "PackedStringArray()"


def write_tres(folder, name, script_file, class_name, lines):
    path = os.path.join(OUT, folder)
    os.makedirs(path, exist_ok=True)
    text = (f'[gd_resource type="Resource" script_class="{class_name}" format=3]\n\n'
            f'[ext_resource type="Script" path="{SCRIPTS}{script_file}" id="1_def"]\n\n'
            f'[resource]\nscript = ExtResource("1_def")\n' + "\n".join(lines) + "\n")
    with open(os.path.join(path, name + ".tres"), "w", encoding="utf-8") as f:
        f.write(text)


def dict_text(d):
    return "{\n" + ",\n".join(f'{q(k)}: {v}' for k, v in d.items()) + "\n}" if d else "{}"


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    keys = dict(UI)
    for i, (id_, icon, price, names) in enumerate(INGREDIENTS):
        key = "ING_" + id_.upper()
        keys[key] = names
        write_tres("ingredients", id_, "ingredient_def.gd", "IngredientDef",
                   [f'id = {q(id_)}', f'name_key = {q(key)}', f'icon = {q(icon)}', f'buy_price = {price}'])
    for id_, icon, ings, tags, price, secs, unlock, names in DISHES:
        key = "DISH_" + id_.upper()
        keys[key] = names
        write_tres("dishes", id_, "dish_def.gd", "DishDef",
                   [f'id = {q(id_)}', f'name_key = {q(key)}', f'icon = {q(icon)}', f'ingredients = {dict_text(ings)}',
                    f'tags = {packed(tags)}', f'base_price = {price}', f'cook_seconds = {secs}',
                    f'unlocked_by_guest = {q(unlock)}'])
    for id_, icon, likes, dislikes, patience, friends, after, gift, weight, names in GUESTS:
        key = "GUEST_" + id_.upper()
        keys[key] = names
        write_tres("guests", id_, "guest_def.gd", "GuestDef",
                   [f'id = {q(id_)}', f'name_key = {q(key)}', f'icon = {q(icon)}', f'likes = {packed(likes)}',
                    f'dislikes = {packed(dislikes)}', f'patience_seconds = {patience}', f'friendship_needed = {friends}',
                    f'appears_after_served = {after}', f'gift_ingredient = {q(gift[0])}', f'gift_amount = {gift[1]}',
                    f'gift_every_visits = {gift[2]}', f'weight = {weight}'])
    for id_, icon, secs, yields, after, names in EXPEDITIONS:
        key = "TRIP_" + id_.upper()
        keys[key] = names
        ytext = "{\n" + ",\n".join(f'{q(k)}: [{lo}, {hi}]' for k, (lo, hi) in yields.items()) + "\n}"
        write_tres("expeditions", id_, "expedition_def.gd", "ExpeditionDef",
                   [f'id = {q(id_)}', f'name_key = {q(key)}', f'icon = {q(icon)}', f'duration_seconds = {secs}',
                    f'yields = {ytext}', f'appears_after_served = {after}'])
    effect_index = {"SEATS": 0, "COOK_SPEED": 1, "ARRIVAL_SPEED": 2, "SNACK_GUARD": 3}
    for id_, icon, effect, cost, growth, max_level, amount, names in UPGRADES:
        key = "UPG_" + id_.upper()
        keys[key] = names
        write_tres("upgrades", id_, "upgrade_def.gd", "UpgradeDef",
                   [f'id = {q(id_)}', f'name_key = {q(key)}', f'icon = {q(icon)}', f'effect = {effect_index[effect]}',
                    f'base_cost = {cost}', f'cost_growth = {growth}', f'max_level = {max_level}',
                    f'amount_per_level = {amount}'])
    # Translations: append missing keys only.
    csv_path = os.path.join(ROOT, "localization", "translations.csv")
    os.makedirs(os.path.dirname(csv_path), exist_ok=True)
    if not os.path.exists(csv_path):
        with open(csv_path, "w", encoding="utf-8", newline="") as f:
            f.write("keys,en,de,zh_CN\n")
    with open(csv_path, encoding="utf-8", newline="") as f:
        rows = list(csv.reader(f))
    have = {r[0] for r in rows if r}
    added = 0
    with open(csv_path, "a", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        for key, (en, de, zh) in keys.items():
            if key not in have:
                writer.writerow([key, en, de, zh])
                added += 1
    print(f"wrote data to {OUT}, {added} new translation keys")


if __name__ == "__main__":
    main()
