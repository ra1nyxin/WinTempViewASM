ASFLAGS := -x assembler-with-cpp -Wa,-adhln
LDFLAGS := -mwindows
LDLIBS := -luser32 -lgdi32 -lkernel32

TARGET := winTempView.exe
SRC := src/main.S
RES := src/app.res.o

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC) $(RES)
	gcc $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(RES): src/app.rc src/app.manifest
	cd src && windres app.rc -O coff -o app.res.o

clean:
	-del /q $(TARGET) 2>nul
	-del /q $(RES) 2>nul
