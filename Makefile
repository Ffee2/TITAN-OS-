CC = clang
CFLAGS = -std=c11 -O2 -Wall -Wextra -Wpedantic
CPPFLAGS = -Icore/c/include

TARGET = build/titan-native

SOURCE = \
    src/main.c \
    src/battery.c \
    core/c/core.c \
    core/c/system/platform.c \
    core/c/system/info.c \
    core/c/cpu/cpu.c \
    core/c/memory/memory.c \
    core/c/storage/storage.c \
    core/c/network/network.c \
    core/c/process/process.c

all: $(TARGET)

$(TARGET): $(SOURCE)
	mkdir -p build
	$(CC) $(CPPFLAGS) $(CFLAGS) $(SOURCE) -o $(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all clean
