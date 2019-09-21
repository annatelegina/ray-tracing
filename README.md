Курс "Компьютерная графика".
Задание №1: "Трассировка лучей".
Выполнено Телегиной Анной Дмитриевной, 324 группа.

Запуск задания:

1) mkdir build
2) cd build
3) cmake ..
4) make
5) ./main

В проекте реализовано:

---------------------------
| № | Название            |
---------------------------
| 1 | Базовая часть       |
---------------------------
| 2 | Резкие тени         |
---------------------------
| 3 | Отражение           |
---------------------------
| 4 | Туман               |
---------------------------
| 5 | Перемещение по сцене|
---------------------------
| 6 | Фракталы            |
---------------------------

Замечания:
1) При нажатии клавиши "1" включается/отключается туман.
2) При нажатии клавиши "2" включается/отключается отражение у плоскости.
3) Клавиша 0 возвращает "дефолтный" вид.
4) Резкие тени стоят по дефолту.
5) В сцене реализовано 3 типа фрактала; фигуры стоят в сцене по дефолту.
6) Реализованное перемещение по сцене включает в себя:
    а) WSAD - движение вперед, влево, назад, вправо;
    б) R/F - движение вверх/вниз;
    в) SHIFT - ускорение движения;
    г) вращение мышкой - как в шаблоне;
    д) Q/E - движение влево/вправо относительно осей её направления.
7) ESCAPE - закрытие окна.
