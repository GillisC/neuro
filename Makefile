BUILD_DIR := build

CMAKE := $(shell which cmake)
OS := $(shell uname -s)

BACKEND := default

# ========== Build cores ============
NUM_CORES := 1

ifeq ($(OS), Linux)
	NUM_CORES := $(shell expr `nproc` - 1)
endif

ifeq ($(OS), Darwin) # MacOS
	NUM_CORES := $(shell sysctl -n hw.ncpu)
endif

# Detect which os the user has and set the package manager and dependencies accordingly
# There are slight variations in the dependencies between operating systems.
ifeq ($(OS), Linux)
	PKG_MANAGER := sudo apt-get install -y
	DEPENDENCIES := cmake g++ make python3-pip graphviz gcovr doxygen
endif

ifeq ($(OS), Darwin) # MacOS
	PKG_MANAGER := brew install
	DEPENDENCIES := cmake g++ make graphviz gcovr doxygen include-what-you-use
endif

# =========== Build Targets ================
.PHONY: all build default blocked avx2 avx512 cuda openblas

all: $(BACKEND)


default:
	@$(MAKE) BACKEND=default build

blocked:
	@$(MAKE) BACKEND=blocked build

avx2:
	@$(MAKE) BACKEND=avx2 build

avx512:
	@$(MAKE) BACKEND=avx512 build

cuda: 
	@$(MAKE) BACKEND=cuda build

openblas:
	@$(MAKE) BACKEND=openblas build

build:
	@mkdir -p $(BUILD_DIR)
	@cmake -S . -B $(BUILD_DIR) -DBACKEND=$(BACKEND) && cmake --build $(BUILD_DIR) -- -j$(NUM_CORES)

install:
	@echo "Detected OS: $(OS)"
	@echo "Installing dependencies..."
	@$(PKG_MANAGER) $(DEPENDENCIES)
	@pip install -r requirements.txt
	@echo "Installation complete!"


# Leaving this here to not break github actions
test:
	@echo "Running tests...\n"
	@if [ -n "$(TEST_NAME)" ]; then \
		echo "Running test: $(TEST_NAME)"; \
		cd ./build && ctest -R "$(TEST_NAME)" --output-on-failure; \
	else \
		echo "Running all tests..."; \
		cd ./build && ctest --output-on-failure; \
	fi

coverage:
	@echo "Generating coverage...\n"
	@$(CMAKE) --build $(BUILD_DIR) --target coverage_report

docs:
	@echo "Generating Doxygen documentation..."
	@$(CMAKE) --build $(BUILD_DIR) --target docs

check_backends:
	@echo "Checking available backends for your system...\n"
	@echo "Default GEMM: Available! (always)"
	@echo "Blocked GEMM: Available! (always)"
	@if lscpu | grep -q 'avx2'; then \
		echo "AVX2: Available!"; \
	else \
		echo "AVX2: Not available!"; \
	fi
	@if lscpu | grep -q 'avx512'; then \
		echo "AVX-512: Available!"; \
	else \
		echo "AVX-512: Not available!"; \
	fi

clean:
	@echo "Cleaning up...\n"
	@rm -rf $(BUILD_DIR)
