CC := gcc
CFLAGS := -std=gnu99 -Wall -Werror -Wpedantic -Wextra -Wfloat-equal -Wfloat-conversion -Iinc
LDFLAGS :=
LDLIBS := -lm
SRCS := $(wildcard ./src/*.c)
UNIT_SRCS := $(wildcard ./unit_tests/*.c)
OBJS := $(patsubst ./src/%.c, ./out/%.o, $(filter-out ./src/main.c, $(SRCS)))
MAIN_OBJ := ./out/main.o
UNIT_OBJS := $(patsubst ./unit_tests/%.c, ./out/%.o, $(UNIT_SRCS))
CHECK_LIBS := -lcheck -lm -lpthread -lrt

vpath %.c src unit_tests

.PHONY : clean debug release debug_asan debug_msan func func_valgrind all my_unit
.PHONY : debug_ubsan check build_coverage collect_coverage unit

my_unit : CHECK_LIBS += -lsubunit
my_unit : CFLAGS += -g3
my_unit : unit_tests.exe

release : app.exe

debug : CFLAGS += -g3
debug : app.exe

build_coverage : CFLAGS += -g3 --coverage
build_coverage : LDFLAGS += --coverage
build_coverage: app.exe

debug_asan : CC := clang
debug_asan : CFLAGS += -g3 -fsanitize=address -fno-omit-frame-pointer
debug_asan : LDFLAGS += -fsanitize=address
debug_asan : app.exe

debug_msan : CC := clang
debug_msan : CFLAGS += -g3 -fsanitize=memory -fno-omit-frame-pointer
debug_msan : LDFLAGS += -fsanitize=memory
debug_msan : app.exe

debug_ubsan : CC := clang
debug_ubsan : CFLAGS += -g3 -fsanitize=undefined -fno-omit-frame-pointer -fno-sanitize-recover=undefined
debug_ubsan : LDFLAGS += -fsanitize=undefined
debug_ubsan : app.exe

unit : unit_tests.exe
	./$<

check :
	./scripts/code_checker.sh

collect_coverage :
	./scripts/collect_coverage.sh

func :
	./func_tests/scripts/func_tests.sh

func_valgrind :
	./func_tests/scripts/func_tests.sh --valgrind

all :
	@$(MAKE) clean
	@$(MAKE) build_coverage
	@$(MAKE) func
	@$(MAKE) collect_coverage
	rm -rf func_tests/data/file_out.txt

unit_tests.exe : $(OBJS) $(UNIT_OBJS)
	$(CC) $(LDFLAGS) $^ -o unit_tests.exe $(CHECK_LIBS)

app.exe : $(OBJS) $(MAIN_OBJ)
	$(CC) $(LDFLAGS) $^ -o app.exe $(LDLIBS)

./out/%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

./out/%.d : %.c
	$(CC) $(CFLAGS) -MM -MT $(@:.d=.o) $< > $@

clean:
	rm -f *.exe ./out/*.gcda ./out/*.gcno ./out/*.gcov ./out/*.o ./out/*.d ./func_tests/data/file_out.txt

-include $(patsubst ./src/%.c, ./out/%.d, $(SRCS))
-include $(patsubst ./unit_tests/%.c, ./out/%.d, $(UNIT_SRCS))