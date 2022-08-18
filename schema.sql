USE abir_counter;

CREATE TABLE channel (
    id INT(64) UNSIGNED NOT NULL UNIQUE,
    last_user INT(64) UNSIGNED NULL,
    next_number INT(64) UNSIGNED NOT NULL DEFAULT 1
);
