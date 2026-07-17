-- MPSECIEMS — Survey domain tables (NEW). Safe to re-run.
-- Run via:  node setup.js   (or paste into your SQL client)

CREATE TABLE IF NOT EXISTS SURVEY_QUESTIONS (
  ID             VARCHAR(50)  NOT NULL PRIMARY KEY,
  QUESTION_HI    VARCHAR(255) NOT NULL,
  QUESTION_EN    VARCHAR(255) NULL,
  PHOTO_REQUIRED TINYINT(1)   NOT NULL DEFAULT 0,
  SORT_ORDER     INT          NOT NULL DEFAULT 0,
  IS_ACTIVE      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS SURVEY_SUBMISSIONS (
  ID           BIGINT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
  AREA_TYPE    VARCHAR(10)   NOT NULL,            -- 'urban' | 'rural'
  DIST_ID      VARCHAR(50)   NULL,
  BLOCK_ID     VARCHAR(50)   NULL,
  PANCHYT_ID   VARCHAR(50)   NULL,
  NNN_ID       VARCHAR(50)   NULL,
  BOOTH_ID     VARCHAR(50)   NULL,               -- RPSBUILDINGS.ID or UPSBUILDINGS.ID
  LATITUDE     DECIMAL(10,7) NULL,
  LONGITUDE    DECIMAL(10,7) NULL,
  REMARKS      TEXT          NULL,
  STATUS       VARCHAR(20)   NOT NULL DEFAULT 'SUBMITTED',
  SUBMITTED_BY BIGINT        NULL,               -- IEMS_SECUsers.ID
  IP_ADDRESS   VARCHAR(64)   NULL,
  USER_AGENT   VARCHAR(512)  NULL,
  APP_VERSION  VARCHAR(40)   NULL,
  DEVICE_INFO  VARCHAR(255)  NULL,
  CREATED_AT   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED_AT   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS SURVEY_ANSWERS (
  ID            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
  SUBMISSION_ID BIGINT       NOT NULL,
  QUESTION_ID   VARCHAR(50)  NOT NULL,
  CHECKED       TINYINT(1)   NOT NULL DEFAULT 0,
  IMAGE         LONGTEXT     NULL,               -- base64 data-URL
  CREATED_AT    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ans_sub FOREIGN KEY (SUBMISSION_ID) REFERENCES SURVEY_SUBMISSIONS(ID)
) ENGINE=InnoDB;

-- Audit trail: one row per lifecycle event of a submission.
CREATE TABLE IF NOT EXISTS SURVEY_SUBMISSION_LOGS (
  ID            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
  SUBMISSION_ID BIGINT       NULL,
  ACTION        VARCHAR(50)  NOT NULL,           -- CREATED | UPDATED | ERROR | ...
  DETAIL        TEXT         NULL,
  IP_ADDRESS    VARCHAR(64)  NULL,
  USER_AGENT    VARCHAR(512) NULL,
  CREATED_AT    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_log_sub (SUBMISSION_ID)
) ENGINE=InnoDB;

-- Seed checklist questions (idempotent)
INSERT INTO SURVEY_QUESTIONS (ID, QUESTION_HI, QUESTION_EN, PHOTO_REQUIRED, SORT_ORDER, IS_ACTIVE) VALUES
  ('ramp',      'रैंप की व्यवस्था है?',            'Ramp available?',            1, 1, 1),
  ('water',     'पेयजल की व्यवस्था है?',          'Drinking water available?', 1, 2, 1),
  ('furniture', 'पर्याप्त फर्नीचर है?',            'Adequate furniture?',       1, 3, 1),
  ('light',     'समुचित रोशनी की व्यवस्था है?',    'Proper lighting?',          1, 4, 1),
  ('signage',   'समुचित संकेतक (साइन बोर्ड) हैं?', 'Proper signage?',           1, 5, 1),
  ('toilet',    'शौचालय की व्यवस्था है?',          'Toilet available?',         1, 6, 1)
ON DUPLICATE KEY UPDATE
  QUESTION_HI = VALUES(QUESTION_HI),
  QUESTION_EN = VALUES(QUESTION_EN),
  PHOTO_REQUIRED = VALUES(PHOTO_REQUIRED),
  SORT_ORDER = VALUES(SORT_ORDER),
  IS_ACTIVE = VALUES(IS_ACTIVE);
