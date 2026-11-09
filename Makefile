VERILATOR = verilator

TOP = tb_riscvi32

SRC = $(wildcard srcs/*.v)
SRC = tb/tb_riscvi32.v

all: run

run: build
		./obj_dir/V$(TOP)

build:
		$(VERILATOR) --binary --timing --trace-fst -Wall -Wno-fatal \
					 -Wno-TIMESCALEMOD -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL \
					 -Isrcs \
					 --top-module $(TOP) $(SRC)

waves:
		gtkwave tb_riscvi32.fst &


clean:
		rm -rf obj_dir *.fst