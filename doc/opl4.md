
# OPL4 FM part

## Slot No in 4OP

| チャンネル | OP1 | OP2 | OP3 | OP4 |
| ---------- | --- | --- | --- | --- |
| 1          | 1   | 4   | 7   | 10  |
| 2          | 2   | 5   | 8   | 11  |
| 3          | 3   | 6   | 9   | 12  |
| 4          | 19  | 22  | 25  | 28  |
| 5          | 20  | 23  | 26  | 29  |
| 6          | 21  | 24  | 27  | 30  |


## WS

| WS | 0                      | 1                      | 2                      | 3                      |
| -- | ---------------------- | ---------------------- | ---------------------- | ---------------------- |
|    | ![ws0](img/ws/ws0.svg) | ![ws1](img/ws/ws1.svg) | ![ws2](img/ws/ws2.svg) | ![ws3](img/ws/ws3.svg) |


| WS | 4                      | 5                      | 6                      | 7                      |
| -- | ---------------------- | ---------------------- | ---------------------- | ---------------------- |
|    | ![ws4](img/ws/ws4.svg) | ![ws5](img/ws/ws5.svg) | ![ws6](img/ws/ws6.svg) | ![ws7](img/ws/ws7.svg) |

## CNT 2OP

| CNT | 0                         | 1                         |
| --- | ------------------------- | ------------------------- |
|     | ![cnt0](img/cnt/cnt0.png) | ![cnt1](img/cnt/cnt1.png) |

## CNT 4OP

| CNT |                                  |
| --- | -------------------------------- |
| 00  | ![cnt00](img/cnt/cnt_4op_00.png) |
| 01  | ![cnt01](img/cnt/cnt_4op_01.png) |
| 10  | ![cnt10](img/cnt/cnt_4op_10.png) |
| 11  | ![cnt11](img/cnt/cnt_4op_11.png) |

## キャリア 4OP

CNT = CNT(C0)<<1 + CNT(C3)

| CNT | キャリア    |
| --- | ----------- |
| 00  | OP4         |
| 01  | OP2 OP4     |
| 10  | OP1 OP4     |
| 11  | OP1 OP3 OP4 |

# OPL4 WaveTable Part

## PAN

| PAN | 0 | 1  | 2  | 3  | 4   | 5   | 6   | 7  |
| --- | - | -- | -- | -- | --- | --- | --- | -- |
| L   | 0 | -3 | -6 | -9 | -12 | -15 | -18 | -∞ |
| R   | 0 | 0  | 0  | 0  | 0   | 0   | 0   | 0  |


| PAN | 8  | 9  | 10  | 11  | 12  | 13 | 14 | 15 |
| --- | -- | -- | --- | --- | --- | -- | -- | -- |
| L   | -∞ | 0  | 0   | 0   | 0   | 0  | 0  | 0  |
| R   | -∞ | -∞ | -18 | -15 | -12 | -9 | -6 | -3 |

## TL

| bit | D7  | D6  | D5 | D4 | D3   | D2    | D1     | - |
| --- | --- | --- | -- | -- | ---- | ----- | ------ | - |
| db  | -24 | -12 | -6 | -3 | -1.5 | -0.75 | -0.375 |   |

Total Level(db) = (-24xD7) + (-12xD6) + (-6xD5) + (-3xD4) + (-1.5xD3) + (-0.75xD2) + (-0.375xD1)

## DL

| bit | D7  | D6  | D5 | D4 | - | - | - | - |
| --- | --- | --- | -- | -- | - | - | - | - |
| db  | -24 | -12 | -6 | -3 |   |   |   |   |

Decay Level(db) = (-24xD7) + (12xD6) + (-6xD5) + (-3xD4) 

補足: すべてが1の場合は-93db


## MIX

| Value      | 0 | 1  | 2  | 3  | 4   | 5   | 6   | 7  |
| ---------- | - | -- | -- | -- | --- | --- | --- | -- |
| MIX LV(db) | 0 | -3 | -6 | -9 | -12 | -15 | -18 | -∞ |

