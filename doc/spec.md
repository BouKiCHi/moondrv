# MoonDriver仕様

資料がコードのみのため、コードの解析結果を記載しています。

## コマンド表

| ラベル         | コマンド番号 | 内容                          |
| -------------- | ------------ | ----------------------------- |
| seq_drumnote   | $e0          | Set drum note                 |
| seq_drumbit    | $e1          | Set drum bits                 |
| seq_jump       | $e2          |                               |
| seq_fbs        | $e3          | Set FBS                       |
| seq_tvp        | $e4          | Set TVP                       |
| seq_ld2ops     | $e5          | Load 2OP Instrument           |
| seq_setop      | $e6          | Set opbase                    |
| seq_nop        | $e7          | Pitch shift                   |
| seq_nop        | $e8          |                               |
| seq_slar       | $e9          | Slar switch                   |
| seq_revbsw     | $ea          | Reverb switch / VolumeOP      |
| seq_damp       | $eb          | Damp switch / OPMODE          |
| seq_nop        | $ec          | LFO freq                      |
| seq_nop        | $ed          | LFO mode                      |
| seq_bank       | $ee          | Bank change                   |
| seq_lfosw      | $ef          | Mode change                   |
| seq_pan        | $f0          | Set Pan                       |
| seq_inst       | $f1          | Load Instrument (4OP or OPL4) |
| seq_drum       | $f2          | Set Drum                      |
| seq_nop        | $f3          |                               |
| seq_wait       | $f4          | Wait                          |
| seq_data_write | $f5          | Data Write                    |
| seq_nop        | $f6          |                               |
| seq_nenv       | $f7          | Note  envelope                |
| seq_penv       | $f8          | Pitch envelope                |
| seq_skip_1     | $f9          |                               |
| seq_detune     | $fa          | Detune                        |
| seq_nop        | $fb          | LFO                           |
| seq_rest       | $fc          | Rest                          |
| seq_volume     | $fd          | Volume                        |
| seq_skip_1     | $fe          | Not used                      |
| seq_loop       | $ff          | Loop                          |

## コマンド

### seq_data_write($f5)

入力 : low, high, data

| high | 内容              |
| ---- | ----------------- |
| 0    | write_data_cur_fm |
| 1    | moon_fm1_out      |
| 2    | moon_fm2_out      |
| 3    | moon_wave_out     |


