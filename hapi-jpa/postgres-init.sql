CREATE TABLE HFJ_RESOURCE (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    RES_ID bigint PRIMARY KEY,
    RES_VER bigint NOT NULL,
    RES_VERSION text NOT NULL,
    RES_TYPE text NOT NULL,
    HASH_SHA256 bigint NOT NULL,
    RES_PUBLISHED timestamp NOT NULL,
    RES_UPDATED timestamp NOT NULL,
    RES_DELETED_AT timestamp
);

GRANT ALL ON HFJ_RESOURCE TO admin;

CREATE TABLE HFJ_FORCED_ID (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    PID bigint PRIMARY KEY,
    RESOURCE_PID bigint NOT NULL,
    FORCED_ID text,

    FOREIGN KEY (RESOURCE_PID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_FORCED_ID TO admin;

CREATE TABLE HFJ_RES_VER (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    PID bigint PRIMARY KEY,
    RES_ID bigint NOT NULL,
    RES_VER bigint,
    RES_ENCODING text,
    RES_TEXT bytea,
    FOREIGN KEY (RES_ID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_RES_VER TO admin;

CREATE TABLE HFJ_RES_LINK (
    PARTITION_ID int,
    PARTITION_DATE timestamp,
    PID bigint PRIMARY KEY,
    SRC_PATH text,
    SOURCE_RESOURCE_TYPE text,
    SRC_RESOURCE_ID bigint NOT NULL,
    TARGET_RESOURCE_TYPE text,
    TARGET_RESOURCE_ID bigint NOT NULL,
    TARGET_RESOURCE_URL text,
    SP_UPDATED timestamp,

    FOREIGN KEY (SRC_RESOURCE_ID) REFERENCES HFJ_RESOURCE(RES_ID),
    FOREIGN KEY (TARGET_RESOURCE_ID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_RES_LINK TO admin;

CREATE TABLE HFJ_SPIDX_COORDS (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    SP_ID bigint PRIMARY KEY,
    RES_ID bigint NOT NULL,
    SP_NAME text,
    RES_TYPE text,
    SP_UPDATED timestamp,
    SP_MISSING boolean NOT NULL,
    SP_LATITUDE double precision,
    SP_LONGITUDE double precision,
    HASH_IDENTITY bigint NOT NULL,

    FOREIGN KEY (RES_ID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_SPIDX_COORDS TO admin;

CREATE TABLE HFJ_SPIDX_DATE (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    SP_ID bigint PRIMARY KEY,
    RES_ID bigint NOT NULL,
    SP_NAME text,
    RES_TYPE text,
    SP_UPDATED timestamp,
    SP_MISSING boolean,
    SP_VALUE_HIGH timestamp,
    SP_VALUE_LOW timestamp,
    SP_VALUE_HIGH_DATE_ORDINAL int,
    SP_VALUE_LOW_DATE_ORDINAL int,
    HASH_IDENTITY bigint,

    FOREIGN KEY (RES_ID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_SPIDX_DATE TO admin;


CREATE TABLE HFJ_SPIDX_NUMBER (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    SP_ID bigint PRIMARY KEY,
    RES_ID bigint NOT NULL,
    SP_NAME text,
    RES_TYPE text,
    SP_UPDATED timestamp,
    SP_MISSING boolean,
    SP_VALUE numeric NOT NULL,
    HASH_IDENTITY bigint,

    FOREIGN KEY (RES_ID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_SPIDX_NUMBER TO admin;

CREATE TABLE HFJ_SPIDX_QUANTITY (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    SP_ID bigint PRIMARY KEY,
    RES_ID bigint NOT NULL,
    SP_NAME text,
    RES_TYPE text,
    SP_UPDATED timestamp,
    SP_MISSING boolean,
    SP_SYSTEM text NOT NULL,
    SP_UNITS text NOT NULL,
    SP_VALUE numeric NOT NULL,
    HASH_IDENTITY bigint NOT NULL,
    HASH_IDENTITY_AND_UNITS bigint NOT NULL,
    HASH_IDENTITY_SYS_UNITS bigint NOT NULL,

    FOREIGN KEY (RES_ID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_SPIDX_QUANTITY TO admin;

CREATE TABLE HFJ_SPIDX_STRING (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    SP_ID bigint PRIMARY KEY,
    RES_ID bigint NOT NULL,
    SP_NAME text,
    RES_TYPE text,
    SR_UPDATED timestamp,
    SP_MISSING boolean NOT NULL,
    SP_VALUE_NORMALIZED text NOT NULL,
    SP_VALUE_EXACT text NOT NULL,
    HASH_IDENTITY bigint NOT NULL,
    HASH_NORM_PREFIX bigint,
    HASH_EXACT bigint NOT NULL,

    FOREIGN KEY (RES_ID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_SPIDX_STRING TO admin;

CREATE TABLE HFJ_SPIDX_TOKEN (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    SP_ID bigint PRIMARY KEY,
    RES_ID bigint NOT NULL,
    SP_NAME text,
    RES_TYPE text,
    SP_UPDATED timestamp,
    SP_MISSING boolean NOT NULL,
    SP_SYSTEM text NOT NULL,
    SP_VALUE text NOT NULL,
    HASH_IDENTITY bigint NOT NULL,
    HASH_SYS bigint NOT NULL,
    HASH_SYS_AND_VALUE bigint NOT NULL,
    HASH_VALUE text NOT NULL,

    FOREIGN KEY (RES_ID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_SPIDX_TOKEN TO admin;

CREATE TABLE HFJ_SPIDX_URI (
    PARTITION_ID bigint,
    PARTITION_DATE timestamp,
    SP_ID bigint PRIMARY KEY,
    RES_ID bigint NOT NULL,
    SP_NAME text,
    RES_TYPE text,
    SP_UPDATED timestamp,
    SP_MISSING boolean NOT NULL,
    SP_URI text NOT NULL,
    HASH_IDENTITY bigint NOT NULL,
    HASH_URI bigint NOT NULL,

    FOREIGN KEY (RES_ID) REFERENCES HFJ_RESOURCE(RES_ID)
);

GRANT ALL ON HFJ_SPIDX_URI TO admin;














