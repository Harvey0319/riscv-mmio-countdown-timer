# 基於 RISC-V Memory-Mapped I/O 之雙位數倒數計時系統

## 1. 專題名稱

基於 RISC-V Memory-Mapped I/O 之雙位數倒數計時系統
Two-Digit Countdown Timer System Based on RISC-V Memory-Mapped I/O

## 2. 使用開發板

本專題使用 Digilent Basys 3 FPGA 開發板實作。使用到的 I/O 包含：

* SW[5:0]：設定倒數秒數，範圍為 0～63 秒
* BTN C (U18)：開始 / 暫停 / 繼續
* BTN U (T18)：重設
* LED[3:0]：顯示 WAIT、RUN、PAUSE、DONE 狀態
* 七段顯示器：顯示目前倒數值 00～63

## 3. 使用工具版本

* FPGA 開發工具：Xilinx Vivado 2024.1
* RISC-V toolchain：riscv64-unknown-elf-gcc / objdump / objcopy
* 作業系統環境：Windows + Ubuntu
* 轉換工具：Python 3

## 4. 專案資料夾結構

```text
riscv-mmio-countdown-timer/
├── README.md
├── src/
│   ├── top.v
│   ├── riscv_cpu.v
│   └── program_init.vh
├── asm/
│   └── countdown.s
├── constraints/
    └── Basys3.xdc


```

## 5. 如何產生 bitstream

1. 開啟 Vivado 2025.2。
2. 建立 RTL Project。
3. 選擇 Basys 3 對應 FPGA：`xc7a35tcpg236-1`。
4. 加入以下 Verilog 檔案：

   * `src/top.v`
   * `src/riscv_cpu.v`
   * `src/program_init.vh`
5. 加入 constraints 檔案：

   * `constraints/Basys3.xdc`
6. 確認 `top.v` 為 top module。
7. 依序執行：

   * Run Synthesis
   * Run Implementation
   * Generate Bitstream

## 6. 如何載入或修改 RISC-V 程式

RISC-V 控制程式位於：

```text
asm/countdown.s
```

修改 `countdown.s` 後，可使用 RISC-V GNU toolchain 組譯：

```bash
riscv64-unknown-elf-gcc \
  -march=rv32i \
  -mabi=ilp32 \
  -nostdlib \
  -nostartfiles \
  -Wl,-Ttext=0x0 \
  -Wl,--no-relax \
  -o countdown.elf \
  countdown.s
```

檢查反組譯結果：

```bash
riscv64-unknown-elf-objdump -d -M no-aliases,numeric countdown.elf
```

轉成 binary：

```bash
riscv64-unknown-elf-objcopy -O binary -j .text countdown.elf countdown.bin
```

再使用 Python 將 binary 轉成 `program_init.vh` 格式：

```bash
python3 - << 'PY' > program_init.vh
data = open("countdown.bin", "rb").read()

for i in range(0, len(data), 4):
    word_bytes = data[i:i+4].ljust(4, b"\x00")
    word = int.from_bytes(word_bytes, "little")
    print(f"    instr_mem[{i//4}] = 32'h{word:08X};")
PY
```

產生後將新的 `program_init.vh` 放入 `src/` 資料夾，重新產生 bitstream。

## 7. 如何燒錄到 FPGA 開發板

1. 使用 USB cable 連接 Basys 3 與電腦。
2. 在 Vivado 中開啟 Hardware Manager。
3. 選擇 Open Target → Auto Connect。
4. 選擇 Program Device。
5. 載入產生的 `.bit` 檔並按 Program。
6. 燒錄完成後即可在 Basys 3 上操作系統。

## 8. 如何操作與測試

操作方式如下：

1. 使用 SW[5:0] 設定倒數秒數。

   * `001001` 代表 9 秒
   * `001111` 代表 15 秒
   * `101101` 代表 45 秒
   * `111111` 代表 63 秒
2. 七段顯示器會顯示目前設定值。
3. 按 BTN C 開始倒數。
4. 倒數中再按 BTN C 可暫停。
5. 暫停時再按 BTN C 可繼續倒數。
6. 按 BTN U 可重設回 switch 設定值。
7. 倒數到 00 時，LED3 亮表示 DONE 狀態。

狀態 LED 說明：

* LED0：WAIT
* LED1：RUN
* LED2：PAUSE
* LED3：DONE

## 9. 已知問題

* 目前採用 polling 方式讀取 button 與 timer flag，尚未實作 interrupt。
* 七段顯示器目前顯示 00～63，未擴充到三位數以上。
* RISC-V CPU core 為專題需求設計之簡化版本，只支援本系統用到的部分 RV32I 指令，例如 `lui`、`lw`、`sw`、`addi`、`andi`、`beq`、`bne`、`jal`。
* 若修改 `countdown.s` 使用其他 RISC-V 指令，需要同步確認 `riscv_cpu.v` 是否支援該指令。

## 10. 外部來源與授權說明

本專題未直接套用外部開源 RISC-V CPU core 或完整 SoC 專案。主要 Verilog 模組與 memory-mapped I/O 架構依照本專題功能需求整理與實作。

使用工具如下：

* Xilinx Vivado 2025.2：用於 Verilog synthesis、implementation、bitstream 產生與 FPGA 燒錄。
* RISC-V GNU toolchain：用於將 `countdown.s` 組譯為 RV32I machine code。
* Python 3：用於將 binary 轉換為 `program_init.vh`。
* Basys 3 腳位資料：用於 `Basys3.xdc` 腳位設定。
