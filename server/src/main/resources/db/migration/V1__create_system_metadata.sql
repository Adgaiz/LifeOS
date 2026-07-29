CREATE TABLE system_metadata (
    metadata_key VARCHAR(100) NOT NULL,
    metadata_value VARCHAR(500) NOT NULL,
    updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (metadata_key)
);

INSERT INTO system_metadata (metadata_key, metadata_value)
VALUES ('schema_baseline', '1');
