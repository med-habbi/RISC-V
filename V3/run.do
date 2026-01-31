transcript on
vsim -voptargs=+acc work.RvCpuTopTb

;# --- Clk/Rst ---
add wave -r /RvCpuTopTb/clk
add wave -r /RvCpuTopTb/rst

;# --- PC + Fetch ---
add wave -r /RvCpuTopTb/dut/pcQ
add wave -r /RvCpuTopTb/dut/pcPlus4
add wave -r /RvCpuTopTb/dut/pcWordIdx
add wave -r /RvCpuTopTb/dut/instrFromRom
add wave -r /RvCpuTopTb/dut/instrQ

;# --- Controller/FSM outputs (what cycle is doing) ---
add wave -r /RvCpuTopTb/dut/irEn
add wave -r /RvCpuTopTb/dut/pcEn
add wave -r /RvCpuTopTb/dut/pcLoad
add wave -r /RvCpuTopTb/dut/regWriteEn
add wave -r /RvCpuTopTb/dut/memWriteEn
add wave -r /RvCpuTopTb/dut/wbSel
add wave -r /RvCpuTopTb/dut/aluASel
add wave -r /RvCpuTopTb/dut/useImmB
add wave -r /RvCpuTopTb/dut/aluOp
add wave -r /RvCpuTopTb/dut/instType

;# --- Register file interface ---
add wave -r /RvCpuTopTb/dut/rs1
add wave -r /RvCpuTopTb/dut/rs2
add wave -r /RvCpuTopTb/dut/rd
add wave -r /RvCpuTopTb/dut/rs1Data
add wave -r /RvCpuTopTb/dut/rs2Data
add wave -r /RvCpuTopTb/dut/wbData

;# --- Immediate + ALU datapath ---
add wave -r /RvCpuTopTb/dut/immVal
add wave -r /RvCpuTopTb/dut/aluA
add wave -r /RvCpuTopTb/dut/aluB
add wave -r /RvCpuTopTb/dut/aluY

;# --- (Optionnel) Branch comparator (devrait rester à 0 ici) ---
add wave -r /RvCpuTopTb/dut/branchTake
add wave -r /RvCpuTopTb/dut/brFunct3

;# --- (Optionnel) Data memory path (devrait rester inactif ici) ---
add wave -r /RvCpuTopTb/dut/dmemWordIdx
add wave -r /RvCpuTopTb/dut/dmemRdWord
add wave -r /RvCpuTopTb/dut/dmemWrWord
add wave -r /RvCpuTopTb/dut/addrLo

;# Display in hex where it makes sense (you can also do it from GUI: Format > Radix > Hex) [web:154]
radix hex

run -all

