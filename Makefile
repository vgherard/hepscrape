DB_DIR := db

.PHONY: clean install

install:
	@if ! [ -d $(DB_DIR) ]; then\
		mkdir $(DB_DIR);\
		sqlite3 $(DB_DIR)/arxivhepabs.sqlite "VACUUM";\
	fi

clean:
	@rm -r $(DB_DIR)
