-- =====================================================================
-- MCC Complaint System : MySQL 8.0+ schema
-- Flow: Citizen -> District Controller -> Flying Squad -> Returning Officer
--       (-> DEO / CEO / ECI on escalation)
-- Engine: InnoDB, charset utf8mb4 (Hindi + English text)
-- Times are stored in UTC (DATETIME(3)); convert to IST in the app/UI.
-- Locations use POINT SRID 4326 (WGS84) with SPATIAL indexes.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS mcc_complaints
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE mcc_complaints;

SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- 1. MASTER DATA
-- ---------------------------------------------------------------------

CREATE TABLE districts (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  code          VARCHAR(10)      NOT NULL,              -- e.g. BPL
  name_en       VARCHAR(100)     NOT NULL,
  name_hi       VARCHAR(100)     NULL,
  state_code    VARCHAR(5)       NOT NULL DEFAULT 'MP',
  boundary      MULTIPOLYGON     SRID 4326 NULL,         -- for geo checks
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  created_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_districts_code (code)
) ENGINE=InnoDB;

CREATE TABLE constituencies (                           -- Assembly Constituency (AC)
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  district_id   INT UNSIGNED     NOT NULL,
  ac_no         SMALLINT UNSIGNED NOT NULL,              -- official AC number
  code          VARCHAR(20)      NOT NULL,               -- e.g. AC-152
  name_en       VARCHAR(100)     NOT NULL,
  name_hi       VARCHAR(100)     NULL,
  boundary      MULTIPOLYGON     SRID 4326 NULL,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  created_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_ac_code (code),
  KEY idx_ac_district (district_id),
  CONSTRAINT fk_ac_district FOREIGN KEY (district_id) REFERENCES districts(id)
) ENGINE=InnoDB;

CREATE TABLE violation_types (
  id            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code          VARCHAR(40)      NOT NULL,               -- e.g. LIQUOR_DISTRIBUTION
  name_en       VARCHAR(120)     NOT NULL,
  name_hi       VARCHAR(120)     NULL,
  sort_order    SMALLINT         NOT NULL DEFAULT 0,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_vt_code (code)
) ENGINE=InnoDB;

CREATE TABLE sla_config (
  stage         ENUM('ALLOCATION','TRAVEL','ENQUIRY','RO_DECISION') NOT NULL,
  target_min    SMALLINT UNSIGNED NOT NULL,
  warn_pct      TINYINT UNSIGNED NOT NULL DEFAULT 80,    -- sla.warning at this % of target
  escalate_to_role ENUM('DC','DEO','CEO') NULL,          -- who is alerted on breach
  updated_by    BIGINT UNSIGNED  NULL,
  updated_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (stage),
  CONSTRAINT chk_sla_warn CHECK (warn_pct BETWEEN 1 AND 100)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. USERS, AUTH, DEVICES
-- ---------------------------------------------------------------------

CREATE TABLE users (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid            CHAR(36)        NOT NULL,              -- exposed in API
  role            ENUM('CITIZEN','DC','FS','RO','DEO','CEO','ADMIN') NOT NULL,
  name            VARCHAR(150)    NULL,
  mobile          VARCHAR(15)     NOT NULL,
  email           VARCHAR(150)    NULL,
  username        VARCHAR(60)     NULL,                  -- officials only
  password_hash   VARCHAR(255)    NULL,                  -- officials only (bcrypt/argon2)
  designation     VARCHAR(100)    NULL,
  district_id     INT UNSIGNED    NULL,                  -- DC, FS, RO, DEO
  ac_id           INT UNSIGNED    NULL,                  -- RO
  squad_id        BIGINT UNSIGNED NULL,                  -- FS member
  preferred_lang  ENUM('hi','en') NOT NULL DEFAULT 'hi',
  is_active       TINYINT(1)      NOT NULL DEFAULT 1,
  last_login_at   DATETIME(3)     NULL,
  created_by      BIGINT UNSIGNED NULL,
  created_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_uuid (uuid),
  UNIQUE KEY uq_users_mobile_role (mobile, role),
  UNIQUE KEY uq_users_username (username),
  KEY idx_users_role_district (role, district_id),
  KEY idx_users_ac (ac_id),
  KEY idx_users_squad (squad_id),
  CONSTRAINT fk_users_district FOREIGN KEY (district_id) REFERENCES districts(id),
  CONSTRAINT fk_users_ac       FOREIGN KEY (ac_id)       REFERENCES constituencies(id),
  CONSTRAINT fk_users_squad    FOREIGN KEY (squad_id)    REFERENCES flying_squads(id),
  CONSTRAINT fk_users_creator  FOREIGN KEY (created_by)  REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE otp_requests (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  otp_ref       CHAR(36)        NOT NULL,
  mobile        VARCHAR(15)     NOT NULL,
  purpose       ENUM('CITIZEN_LOGIN','OFFICIAL_2FA') NOT NULL,
  otp_hash      VARCHAR(255)    NOT NULL,                -- never store plain OTP
  attempts      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  expires_at    DATETIME(3)     NOT NULL,
  verified_at   DATETIME(3)     NULL,
  request_ip    VARCHAR(45)     NULL,
  created_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_otp_ref (otp_ref),
  KEY idx_otp_mobile_time (mobile, created_at)          -- rate limiting
) ENGINE=InnoDB;

CREATE TABLE refresh_tokens (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NOT NULL,
  token_hash    CHAR(64)        NOT NULL,                -- SHA-256 of token
  device_id     VARCHAR(100)    NULL,
  expires_at    DATETIME(3)     NOT NULL,
  revoked_at    DATETIME(3)     NULL,
  created_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_rt_hash (token_hash),
  KEY idx_rt_user (user_id),
  CONSTRAINT fk_rt_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE user_devices (                               -- FCM push tokens (API N1)
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NOT NULL,
  platform      ENUM('ANDROID','IOS','WEB') NOT NULL,
  fcm_token     VARCHAR(255)    NOT NULL,
  app_version   VARCHAR(20)     NULL,
  is_active     TINYINT(1)      NOT NULL DEFAULT 1,
  last_seen_at  DATETIME(3)     NULL,
  created_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_device_token (fcm_token),
  KEY idx_device_user (user_id),
  CONSTRAINT fk_device_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. FLYING SQUADS
-- ---------------------------------------------------------------------

CREATE TABLE flying_squads (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code             VARCHAR(20)     NOT NULL,             -- e.g. FS-02
  district_id      INT UNSIGNED    NOT NULL,
  vehicle_no       VARCHAR(20)     NULL,
  leader_user_id   BIGINT UNSIGNED NULL,                 -- magistrate in charge
  status           ENUM('AVAILABLE','BUSY','OFF_DUTY') NOT NULL DEFAULT 'OFF_DUTY',
  last_location    POINT SRID 4326 NULL,
  last_location_at DATETIME(3)     NULL,
  is_active        TINYINT(1)      NOT NULL DEFAULT 1,
  created_at       DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at       DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_squad_code_district (district_id, code),
  KEY idx_squad_status (district_id, status),
  CONSTRAINT fk_squad_district FOREIGN KEY (district_id)    REFERENCES districts(id),
  CONSTRAINT fk_squad_leader   FOREIGN KEY (leader_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE squad_areas (                                -- ACs a squad covers
  squad_id      BIGINT UNSIGNED NOT NULL,
  ac_id         INT UNSIGNED    NOT NULL,
  PRIMARY KEY (squad_id, ac_id),
  KEY idx_sa_ac (ac_id),
  CONSTRAINT fk_sa_squad FOREIGN KEY (squad_id) REFERENCES flying_squads(id) ON DELETE CASCADE,
  CONSTRAINT fk_sa_ac    FOREIGN KEY (ac_id)    REFERENCES constituencies(id)
) ENGINE=InnoDB;

CREATE TABLE squad_location_log (                         -- GPS pings (API F4)
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  squad_id      BIGINT UNSIGNED NOT NULL,
  user_id       BIGINT UNSIGNED NOT NULL,
  location      POINT SRID 4326 NOT NULL,
  accuracy_m    SMALLINT UNSIGNED NULL,
  recorded_at   DATETIME(3)     NOT NULL,
  received_at   DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_sll_squad_time (squad_id, recorded_at),
  CONSTRAINT fk_sll_squad FOREIGN KEY (squad_id) REFERENCES flying_squads(id),
  CONSTRAINT fk_sll_user  FOREIGN KEY (user_id)  REFERENCES users(id)
) ENGINE=InnoDB;
-- High-volume table: partition by month or purge after the election period.

-- ---------------------------------------------------------------------
-- 4. COMPLAINTS AND EVIDENCE
-- ---------------------------------------------------------------------

CREATE TABLE complaints (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid              CHAR(36)        NOT NULL,
  complaint_no      VARCHAR(20)     NULL,                -- BPL-24-0433, set on submit
  citizen_id        BIGINT UNSIGNED NOT NULL,
  is_anonymous      TINYINT(1)      NOT NULL DEFAULT 0,
  violation_type_id SMALLINT UNSIGNED NOT NULL,
  description       TEXT            NULL,
  language          ENUM('hi','en') NOT NULL DEFAULT 'hi',
  latitude          DECIMAL(10,7)   NOT NULL,
  longitude         DECIMAL(10,7)   NOT NULL,
  location          POINT GENERATED ALWAYS
                    AS (ST_SRID(POINT(longitude, latitude), 4326)) STORED NOT NULL SRID 4326,
  gps_accuracy_m    SMALLINT UNSIGNED NULL,
  address_text      VARCHAR(255)    NULL,                -- reverse-geocoded
  district_id       INT UNSIGNED    NULL,                -- resolved on submit
  ac_id             INT UNSIGNED    NULL,
  status            ENUM('DRAFT','RECEIVED','WITHDRAWN','DUPLICATE','DROPPED_AT_DC',
                         'ASSIGNED','ACCEPTED','EN_ROUTE','REACHED',
                         'REPORT_SUBMITTED','REPORT_RETURNED',
                         'DISPOSED','DROPPED','ESCALATED','RESOLVED')
                    NOT NULL DEFAULT 'DRAFT',
  current_stage     ENUM('ALLOCATION','TRAVEL','ENQUIRY','RO_DECISION') NULL,
  stage_deadline    DATETIME(3)     NULL,                -- deadline of current stage
  sla_deadline      DATETIME(3)     NULL,                -- submitted_at + 100 min
  is_sla_breached   TINYINT(1)      NOT NULL DEFAULT 0,
  duplicate_of_id   BIGINT UNSIGNED NULL,
  dc_drop_reason    ENUM('NOT_MCC_VIOLATION','FAKE_EVIDENCE','OUTSIDE_JURISDICTION','INSUFFICIENT_DETAILS') NULL,
  dc_remarks        VARCHAR(500)    NULL,
  captured_at       DATETIME(3)     NOT NULL,            -- when citizen captured evidence
  upload_deadline   DATETIME(3)     NOT NULL,            -- captured_at + 5 min
  submitted_at      DATETIME(3)     NULL,
  closed_at         DATETIME(3)     NULL,
  created_at        DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at        DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_complaint_uuid (uuid),
  UNIQUE KEY uq_complaint_no (complaint_no),
  KEY idx_c_citizen (citizen_id, created_at),
  KEY idx_c_district_status (district_id, status, stage_deadline),   -- DC queue (D1)
  KEY idx_c_ac_status (ac_id, status, stage_deadline),               -- RO queue (R1)
  KEY idx_c_breach (is_sla_breached, status),
  KEY idx_c_type (violation_type_id),
  KEY idx_c_submitted (submitted_at),
  SPATIAL KEY sp_c_location (location),                              -- duplicate check
  CONSTRAINT fk_c_citizen  FOREIGN KEY (citizen_id)        REFERENCES users(id),
  CONSTRAINT fk_c_type     FOREIGN KEY (violation_type_id) REFERENCES violation_types(id),
  CONSTRAINT fk_c_district FOREIGN KEY (district_id)       REFERENCES districts(id),
  CONSTRAINT fk_c_ac       FOREIGN KEY (ac_id)             REFERENCES constituencies(id),
  CONSTRAINT fk_c_dup      FOREIGN KEY (duplicate_of_id)   REFERENCES complaints(id),
  CONSTRAINT chk_c_lat CHECK (latitude  BETWEEN -90  AND 90),
  CONSTRAINT chk_c_lng CHECK (longitude BETWEEN -180 AND 180)
) ENGINE=InnoDB;

CREATE TABLE complaint_media (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid            CHAR(36)        NOT NULL,
  complaint_id    BIGINT UNSIGNED NOT NULL,
  uploaded_by     BIGINT UNSIGNED NOT NULL,
  source          ENUM('CITIZEN','SQUAD') NOT NULL,
  assignment_id   BIGINT UNSIGNED NULL,                  -- set when source = SQUAD
  media_type      ENUM('PHOTO','VIDEO','AUDIO','DOCUMENT') NOT NULL,
  doc_kind        ENUM('PANCHNAMA','SEIZURE_MEMO','STATEMENT','OTHER') NULL,
  storage_key     VARCHAR(500)    NOT NULL,              -- S3/MinIO object key (original)
  display_key     VARCHAR(500)    NULL,                  -- EXIF-stripped copy
  mime_type       VARCHAR(100)    NOT NULL,
  size_bytes      BIGINT UNSIGNED NOT NULL,
  duration_sec    SMALLINT UNSIGNED NULL,
  sha256          CHAR(64)        NOT NULL,
  latitude        DECIMAL(10,7)   NULL,
  longitude       DECIMAL(10,7)   NULL,
  captured_at     DATETIME(3)     NOT NULL,
  created_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_media_uuid (uuid),
  KEY idx_media_complaint (complaint_id, source),
  KEY idx_media_sha (sha256),
  CONSTRAINT fk_media_complaint  FOREIGN KEY (complaint_id)  REFERENCES complaints(id),
  CONSTRAINT fk_media_user       FOREIGN KEY (uploaded_by)   REFERENCES users(id),
  CONSTRAINT fk_media_assignment FOREIGN KEY (assignment_id) REFERENCES assignments(id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. SQUAD ASSIGNMENT AND FIELD REPORT
-- ---------------------------------------------------------------------

CREATE TABLE assignments (
  id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid               CHAR(36)        NOT NULL,
  complaint_id       BIGINT UNSIGNED NOT NULL,
  squad_id           BIGINT UNSIGNED NOT NULL,
  assigned_by        BIGINT UNSIGNED NOT NULL,           -- DC user
  note               VARCHAR(500)    NULL,
  distance_km        DECIMAL(6,2)    NULL,               -- at time of assignment
  eta_min            SMALLINT UNSIGNED NULL,
  assigned_at        DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  accepted_at        DATETIME(3)     NULL,
  started_at         DATETIME(3)     NULL,
  reached_at         DATETIME(3)     NULL,
  reached_location   POINT SRID 4326 NULL,
  reached_distance_m SMALLINT UNSIGNED NULL,             -- geofence check result
  is_active          TINYINT(1)      NOT NULL DEFAULT 1, -- 0 after reassign
  ended_reason       ENUM('COMPLETED','REASSIGNED','CANCELLED') NULL,
  ended_at           DATETIME(3)     NULL,
  reassign_reason    VARCHAR(500)    NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_asg_uuid (uuid),
  KEY idx_asg_complaint (complaint_id, is_active),
  KEY idx_asg_squad (squad_id, is_active),
  CONSTRAINT fk_asg_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(id),
  CONSTRAINT fk_asg_squad     FOREIGN KEY (squad_id)     REFERENCES flying_squads(id),
  CONSTRAINT fk_asg_dc        FOREIGN KEY (assigned_by)  REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE field_reports (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  assignment_id       BIGINT UNSIGNED NOT NULL,
  complaint_id        BIGINT UNSIGNED NOT NULL,
  submitted_by        BIGINT UNSIGNED NOT NULL,
  version             TINYINT UNSIGNED NOT NULL DEFAULT 1, -- +1 after RO send-back
  finding             ENUM('VIOLATION_CONFIRMED','NOTHING_FOUND','NOT_MCC','PARTIAL') NOT NULL,
  summary             TEXT            NOT NULL,
  party_or_candidate  VARCHAR(200)    NULL,
  actions_taken       JSON            NULL,   -- ["MATERIAL_REMOVED","PANCHNAMA",...]
  seizure_made        TINYINT(1)      NOT NULL DEFAULT 0,
  recommendation      ENUM('DISPOSE','DROP','ESCALATE') NULL,
  returned_by_ro_id   BIGINT UNSIGNED NULL,               -- R4 send-back
  returned_remarks    VARCHAR(500)    NULL,
  returned_at         DATETIME(3)     NULL,
  submitted_at        DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_fr_assignment_version (assignment_id, version),
  KEY idx_fr_complaint (complaint_id),
  CONSTRAINT fk_fr_assignment FOREIGN KEY (assignment_id)     REFERENCES assignments(id),
  CONSTRAINT fk_fr_complaint  FOREIGN KEY (complaint_id)      REFERENCES complaints(id),
  CONSTRAINT fk_fr_user       FOREIGN KEY (submitted_by)      REFERENCES users(id),
  CONSTRAINT fk_fr_ro         FOREIGN KEY (returned_by_ro_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE seizure_items (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  field_report_id BIGINT UNSIGNED NOT NULL,
  item_type       ENUM('CASH','LIQUOR','GIFTS','DRUGS','PRECIOUS_METAL','OTHER') NOT NULL,
  description     VARCHAR(255)    NULL,
  quantity        DECIMAL(12,2)   NOT NULL,
  unit            VARCHAR(20)     NOT NULL,              -- INR, litre, pieces, kg
  value_inr       DECIMAL(14,2)   NULL,
  PRIMARY KEY (id),
  KEY idx_si_report (field_report_id),
  KEY idx_si_type (item_type),
  CONSTRAINT fk_si_report FOREIGN KEY (field_report_id) REFERENCES field_reports(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. RO DECISION AND ESCALATION
-- ---------------------------------------------------------------------

CREATE TABLE decisions (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  complaint_id   BIGINT UNSIGNED NOT NULL,
  field_report_id BIGINT UNSIGNED NULL,
  decided_by     BIGINT UNSIGNED NOT NULL,               -- RO user
  action         ENUM('DISPOSE','DROP','ESCALATE') NOT NULL,
  final_action   ENUM('WARNING_ISSUED','MATERIAL_REMOVED','SEIZURE','FIR_REGISTERED','NOTICE_TO_CANDIDATE') NULL,
  fir_no         VARCHAR(50)     NULL,
  reason_code    ENUM('NOTHING_FOUND','NOT_MCC','DUPLICATE','FAKE_EVIDENCE') NULL,
  escalate_to    ENUM('DEO','CEO','ECI') NULL,
  remarks        VARCHAR(500)    NOT NULL,               -- shown to citizen
  total_minutes  SMALLINT UNSIGNED NULL,                 -- submitted_at -> decided_at
  sla_met        TINYINT(1)      NULL,
  is_current     TINYINT(1)      NOT NULL DEFAULT 1,     -- 0 when DEO/CEO returns case to RO
  decided_at     DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_dec_complaint (complaint_id, decided_at),      -- latest row = current decision
  KEY idx_dec_ro (decided_by, decided_at),
  KEY idx_dec_action (action, decided_at),
  CONSTRAINT fk_dec_complaint FOREIGN KEY (complaint_id)    REFERENCES complaints(id),
  CONSTRAINT fk_dec_report    FOREIGN KEY (field_report_id) REFERENCES field_reports(id),
  CONSTRAINT fk_dec_ro        FOREIGN KEY (decided_by)      REFERENCES users(id),
  CONSTRAINT chk_dec_fields CHECK (
       (action = 'DISPOSE'  AND final_action IS NOT NULL)
    OR (action = 'DROP'     AND reason_code  IS NOT NULL)
    OR (action = 'ESCALATE' AND escalate_to  IS NOT NULL)
  )
) ENGINE=InnoDB;

CREATE TABLE escalations (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  complaint_id    BIGINT UNSIGNED NOT NULL,
  parent_id       BIGINT UNSIGNED NULL,                  -- previous level (DEO -> CEO)
  level           ENUM('DEO','CEO','ECI') NOT NULL,
  raised_by       BIGINT UNSIGNED NOT NULL,
  raised_remarks  VARCHAR(500)    NOT NULL,
  assigned_to     BIGINT UNSIGNED NULL,
  action          ENUM('RESOLVE','FORWARD','RETURN_TO_RO') NULL,
  final_action    VARCHAR(100)    NULL,
  action_remarks  VARCHAR(500)    NULL,
  action_by       BIGINT UNSIGNED NULL,
  created_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  closed_at       DATETIME(3)     NULL,
  PRIMARY KEY (id),
  KEY idx_esc_complaint (complaint_id),
  KEY idx_esc_open (level, closed_at),
  KEY idx_esc_assignee (assigned_to, closed_at),
  CONSTRAINT fk_esc_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(id),
  CONSTRAINT fk_esc_parent    FOREIGN KEY (parent_id)    REFERENCES escalations(id),
  CONSTRAINT fk_esc_raised    FOREIGN KEY (raised_by)    REFERENCES users(id),
  CONSTRAINT fk_esc_assignee  FOREIGN KEY (assigned_to)  REFERENCES users(id),
  CONSTRAINT fk_esc_actor     FOREIGN KEY (action_by)    REFERENCES users(id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. TRACKING: STATUS HISTORY, SLA STAGES, AUDIT, NOTIFICATIONS
-- ---------------------------------------------------------------------

CREATE TABLE status_history (                             -- citizen timeline (C7)
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  complaint_id  BIGINT UNSIGNED NOT NULL,
  from_status   VARCHAR(30)     NULL,
  to_status     VARCHAR(30)     NOT NULL,
  actor_id      BIGINT UNSIGNED NULL,                    -- NULL = system
  actor_role    ENUM('CITIZEN','DC','FS','RO','DEO','CEO','ADMIN','SYSTEM') NOT NULL,
  remarks       VARCHAR(500)    NULL,
  created_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_sh_complaint (complaint_id, created_at),
  CONSTRAINT fk_sh_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(id),
  CONSTRAINT fk_sh_actor     FOREIGN KEY (actor_id)     REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE complaint_stage_sla (                        -- one row per stage per complaint
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  complaint_id  BIGINT UNSIGNED NOT NULL,
  stage         ENUM('ALLOCATION','TRAVEL','ENQUIRY','RO_DECISION') NOT NULL,
  owner_role    ENUM('DC','FS','RO') NOT NULL,
  started_at    DATETIME(3)     NOT NULL,
  deadline_at   DATETIME(3)     NOT NULL,
  ended_at      DATETIME(3)     NULL,
  duration_sec  INT UNSIGNED    NULL,
  warned_at     DATETIME(3)     NULL,                    -- sla.warning sent
  breached_at   DATETIME(3)     NULL,                    -- sla.breached sent
  PRIMARY KEY (id),
  UNIQUE KEY uq_css (complaint_id, stage),
  KEY idx_css_open (ended_at, deadline_at),              -- SLA worker scan
  KEY idx_css_stage_time (stage, started_at),            -- pipeline averages (B2)
  CONSTRAINT fk_css_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(id)
) ENGINE=InnoDB;

CREATE TABLE audit_log (                                  -- append-only (B5)
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity        VARCHAR(40)     NOT NULL,                -- complaint, assignment, user...
  entity_id     BIGINT UNSIGNED NOT NULL,
  action        VARCHAR(60)     NOT NULL,                -- ASSIGN, DECISION, LOGIN...
  actor_id      BIGINT UNSIGNED NULL,
  actor_role    VARCHAR(10)     NULL,
  ip_address    VARCHAR(45)     NULL,
  user_agent    VARCHAR(255)    NULL,
  payload       JSON            NULL,                    -- before/after snapshot
  created_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_audit_entity (entity, entity_id, created_at),
  KEY idx_audit_actor (actor_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE notifications (                              -- in-app list (N2, N3)
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NOT NULL,
  complaint_id  BIGINT UNSIGNED NULL,
  type          VARCHAR(40)     NOT NULL,                -- STATUS_CHANGED, SLA_WARNING...
  title         VARCHAR(150)    NOT NULL,
  body          VARCHAR(500)    NOT NULL,
  data          JSON            NULL,
  push_status   ENUM('PENDING','SENT','FAILED','SKIPPED') NOT NULL DEFAULT 'PENDING',
  read_at       DATETIME(3)     NULL,
  created_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_notif_user (user_id, read_at, created_at),
  KEY idx_notif_complaint (complaint_id),
  CONSTRAINT fk_notif_user      FOREIGN KEY (user_id)      REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_notif_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(id)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- Block UPDATE/DELETE on audit_log so it stays append-only.
DELIMITER $$
CREATE TRIGGER trg_audit_no_update BEFORE UPDATE ON audit_log
FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'audit_log is append-only'$$
CREATE TRIGGER trg_audit_no_delete BEFORE DELETE ON audit_log
FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'audit_log is append-only'$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- 8. SEED DATA
-- ---------------------------------------------------------------------

INSERT INTO sla_config (stage, target_min, warn_pct, escalate_to_role) VALUES
  ('ALLOCATION',   5, 80, 'DC'),
  ('TRAVEL',      15, 80, 'DC'),
  ('ENQUIRY',     30, 80, 'DC'),
  ('RO_DECISION', 50, 80, 'DEO');

INSERT INTO violation_types (code, name_en, name_hi, sort_order) VALUES
  ('MONEY_DISTRIBUTION',   'Distribution of money',             'पैसे का वितरण',            1),
  ('LIQUOR_DISTRIBUTION',  'Distribution of liquor',            'शराब का वितरण',            2),
  ('GIFTS_DISTRIBUTION',   'Distribution of gifts / coupons',   'उपहार / कूपन का वितरण',     3),
  ('POSTERS_BANNERS',      'Posters / banners without permission','बिना अनुमति पोस्टर / बैनर', 4),
  ('PAID_NEWS',            'Paid news',                          'पेड न्यूज़',                 5),
  ('HATE_SPEECH',          'Hate speech / provocative speech',  'भड़काऊ भाषण',               6),
  ('LOUDSPEAKER',          'Loudspeaker beyond permitted time', 'निर्धारित समय के बाद लाउडस्पीकर', 7),
  ('GOVT_VEHICLE_MISUSE',  'Misuse of government vehicle',      'सरकारी वाहन का दुरुपयोग',    8),
  ('UNAUTHORISED_RALLY',   'Rally / meeting without permission','बिना अनुमति रैली / सभा',     9),
  ('VOTER_INTIMIDATION',   'Threatening / intimidating voters', 'मतदाताओं को धमकाना',       10),
  ('RELIGIOUS_PLACE_USE',  'Use of religious place for campaign','धार्मिक स्थल का प्रचार में उपयोग', 11),
  ('OTHER',                'Other',                             'अन्य',                      99);

-- ---------------------------------------------------------------------
-- 9. USEFUL QUERIES
-- ---------------------------------------------------------------------

-- D3: nearest free squads for a complaint (distance in km)
-- SELECT s.id, s.code,
--        ROUND(ST_Distance_Sphere(s.last_location, c.location) / 1000, 2) AS distance_km
-- FROM flying_squads s
-- JOIN complaints c ON c.id = ?
-- WHERE s.district_id = c.district_id AND s.status = 'AVAILABLE' AND s.is_active = 1
--   AND s.last_location IS NOT NULL
-- ORDER BY distance_km
-- LIMIT 5;

-- C4: duplicate check (same type within 200 m in the last hour)
-- SELECT id, complaint_no FROM complaints
-- WHERE violation_type_id = ? AND status NOT IN ('DRAFT','WITHDRAWN')
--   AND submitted_at >= UTC_TIMESTAMP(3) - INTERVAL 1 HOUR
--   AND ST_Distance_Sphere(location, ST_SRID(POINT(?lng, ?lat), 4326)) <= 200;

-- DC dashboard queue (D1), sorted by time left in the current stage
CREATE OR REPLACE VIEW v_dc_queue AS
SELECT c.id, c.complaint_no, vt.name_en AS violation, c.address_text,
       ac.name_en AS ac_name, c.district_id, c.status, c.current_stage,
       fs.code AS squad_code, c.stage_deadline,
       TIMESTAMPDIFF(SECOND, UTC_TIMESTAMP(3), c.stage_deadline) AS seconds_left,
       c.is_sla_breached, c.submitted_at
FROM complaints c
JOIN violation_types vt ON vt.id = c.violation_type_id
LEFT JOIN constituencies ac ON ac.id = c.ac_id
LEFT JOIN assignments a ON a.complaint_id = c.id AND a.is_active = 1
LEFT JOIN flying_squads fs ON fs.id = a.squad_id
WHERE c.status NOT IN ('DRAFT','WITHDRAWN','DUPLICATE','DROPPED_AT_DC',
                       'DISPOSED','DROPPED','RESOLVED');
