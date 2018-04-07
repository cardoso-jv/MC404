%.mksd: %.exe #Generate SD card image.
	mksd.sh --so /home/specg12-1/mc404/simulador/dummyos.elf --user $*

%.exe: %.o #Linking S*.o
	arm-eabi-ld $< -g -o $* -Ttext=0x77802000 -Tdata=0x77802050

%.o : %.s #Assembling $*.s
	arm-eabi-as -g $< -o $*.o

%.dump: %.exe
	arm-eabi-objdump -S $*

%.readelf: %.exe
	arm-eabi-readelf -a $*

direct_output: disk.img
	arm-sim --rom=/home/specg12-1/mc404/simulador/dumboot.bin --sd=disk.img 2>&1 > ra176277.out 


simulate_only: disk.img
	arm-sim --rom=/home/specg12-1/mc404/simulador/dumboot.bin --sd=disk.img

gdbtarget: disk.img
	arm-sim --rom=/home/specg12-1/mc404/simulador/dumboot.bin --sd=disk.img -g

%.gdbhost: %.exe
	arm-eabi-gdb $*
	target remote localhost:5000

%.clean:
	rm -f $* $*.o disk.img