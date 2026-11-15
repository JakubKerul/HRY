# Echo Run

Mobilná hra na jeden prst. Za 8 sekúnd zober 3 energie. Každé prežité kolo sa potom
prehráva ako ozvena, ktorej sa nesmieš dotknúť.

- **Kampaň**: výprava cez 5 lokalít, bossovia, dimenzionálny obchodník, strom schopností
- **Endless** a **denná výzva** s náhodnými bossmi
- **Rebríček** pre všetkých hráčov (účty, Google tabuľka, správy na Discord)
- Slovenčina aj angličtina

## Spustenie

1. Otvor Godot 4.7.2
2. Import → `project.godot`
3. F5

Ovládanie: dotyk (vždy), na PC myš alebo WASD (Settings → PC controls).

## Súbory

- `main.gd` – celá hra
- `data.gd` – vylepšenia, bossovia, obchod, misie, texty SK/EN
- `ads.gd` – miesta pre reklamy (zatiaľ prázdne)
- `server/apps_script.js` – server rebríčka (Google Apps Script), viac v `TABULKA_SKORE.txt`
- `ZMENY.txt` – zoznam zmien

Autor: shadyyk · hudba: shadyyk, loop by Prodambien · font: Chakra Petch (OFL)
