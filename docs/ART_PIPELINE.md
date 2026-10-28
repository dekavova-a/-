# Игровая графика

Ассеты созданы встроенным ImageGen и подключены как текстуры к сцене Godot.

| Путь | Содержимое |
| --- | --- |
| `godot/assets/siege_map.png` | Карта осады 1536×1024 |
| `godot/assets/spearmen_walk.png` | Прозрачный атлас 887×1774, сетка 4×8 |
| `godot/assets/crossbow_walk.png` | Прозрачный атлас 887×1774, сетка 4×8 |
| `godot/assets/captain.png` | Портрет капитана в Тайном совете |

## Промпты

### Карта

Production Godot 2.5D RTS background terrain plate, no UI or people. Detailed medieval siege map, 3:2 landscape. Fixed high isometric parallel camera, no sky. Northern European autumn kingdom, realistic painterly prerendered strategy art, weathered stone and timber, olive grass, copper foliage, cool upper-left daylight. Upper-right walled stronghold and courtyard with an empty open gate arch. Broad muddy road leads diagonally to a lower-left camp with four burgundy tents, crates and watchfire. Central foreground is open playable meadow. Upper-left village, granary and stream near the map border. Supply camp and hay wagon near the right edge. No troops, text, interface, logos or borders.

Получившиеся ворота находятся около (1023,275). Навигационные полигоны подогнаны к фактическому изображению. Решётка рисуется отдельным объектом; её состояние изменяет AStarGrid2D. Стены и дома в этой версии входят в фоновый арт.

### Копейщик

Production transparent sprite atlas, exactly 4 columns by 8 rows. Same realistic medieval foot soldier with long spear, wooden shield, kettle helmet, chainmail, burgundy cloth and leather boots. Premium prerendered isometric strategy art, elevated camera 40 degrees, cool upper-left light. Rows: east, southeast, south, southwest, west, northwest, north, northeast. Columns: left leg forward, passing step, right leg forward, opposite passing step. Consistent equipment, proportions and feet anchor at 82 percent cell height. Whole figures within cells, actual leg and arm variation, transparent background, no ground, shadows, text or grid.

### Арбалетчик

Production transparent 4×8 walk atlas. Same medieval crossbowman with steel cap, burgundy padded gambeson, leather bracers and boots, holding a small wooden crossbow in both hands. Fixed elevated isometric camera, cool soft light, detailed realistic materials. Eight clockwise facing directions east through south and north to northeast; four sequential walking phases per row. Actual knee movement, body weight shift and consistent ground anchor. Fully isolated whole figures, transparent background, no spear, shield, floor, labels or border.

Размеры листов не кратны количеству кадров нацело. Sprite2D делит их через hframes/vframes с линейной фильтрацией. Циклы предварительные: между кадрами есть небольшие различия позиций и силуэтов. Атака дополнена кратким смещением бойцов и эффектами попадания; гибель - наклоном и затуханием. Для финальной версии нужны отдельные выверенные атаки и смерти.

### Портрет

Original medieval RTS portrait of Edric Vane: tired middle-aged garrison captain, chest-up three-quarter view, weathered face, greying brown hair and short beard, eyebrow scar, worn chainmail, burgundy wool cloak and brass pin, dim torchlit stone guardroom. Grounded detailed painterly art, warm skin, cool steel, charcoal shadows and subdued gold highlights. No actor reference, crown, text, border or UI.

## Дальнейшая работа

Отдельный атлас стражи, выверенные атаки и гибель, осадная техника, маски перекрытия юнитов архитектурой, отдельные стеновые элементы, звук и дополнительные карты. Текущая графика встроена в игровую сцену; это первая миссия с фиксированной камерой, а не свободная 3D-сцена.
