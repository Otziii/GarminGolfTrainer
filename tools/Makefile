# Builds the MTP sideload helper. Requires: brew install libmtp
LIBMTP_PREFIX := $(shell brew --prefix libmtp 2>/dev/null)

CFLAGS  += -Wall -Wextra -O2 -I$(LIBMTP_PREFIX)/include
LDFLAGS += -L$(LIBMTP_PREFIX)/lib -lmtp

mtpsend: mtpsend.c
ifeq ($(LIBMTP_PREFIX),)
	@echo "libmtp not found. Run: brew install libmtp" >&2; exit 1
endif
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f mtpsend

.PHONY: clean
