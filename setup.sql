-- 1. USERS
CREATE TABLE users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  first_name    VARCHAR(50)  NOT NULL,
  last_name     VARCHAR(50)  NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP
);

-- 2. AUTH TOKENS
CREATE TABLE auth_tokens (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id      INT UNSIGNED NOT NULL,
  token        VARCHAR(255) NOT NULL,
  expires_at   DATETIME     NOT NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX (user_id)
);

-- 3. GROUPS
CREATE TABLE groups (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(100) NOT NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP
);

-- 4. GOALS
CREATE TABLE goals (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id            INT UNSIGNED NOT NULL,  -- who created it
  group_id            INT UNSIGNED     NULL,  -- if communal
  description         VARCHAR(255)      NOT NULL,
  reporting_interval  ENUM('daily','weekly','monthly') NOT NULL DEFAULT 'daily',
  created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id)   ON DELETE CASCADE,
  FOREIGN KEY (group_id) REFERENCES groups(id)  ON DELETE SET NULL,
  INDEX (owner_id),
  INDEX (group_id)
);

-- 5. USER ↔ GROUP JOIN
CREATE TABLE user_groups (
  user_id      INT UNSIGNED NOT NULL,
  group_id     INT UNSIGNED NOT NULL,
  role         ENUM('member','admin') NOT NULL DEFAULT 'member',
  joined_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, group_id),
  FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
  INDEX (group_id)
);

-- 6. PROGRESS LOGS
CREATE TABLE progress_logs (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  goal_id    INT UNSIGNED    NOT NULL,
  user_id    INT UNSIGNED    NOT NULL,
  log_date   DATE            NOT NULL,
  notes      TEXT            NULL,
  created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(goal_id, user_id, log_date),
  FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX (goal_id, log_date),
  INDEX (user_id)
);

-- 7. GROUP RULES
CREATE TABLE group_rules (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  group_id            INT UNSIGNED NOT NULL,
  rule_type           ENUM('streak','deadline','custom') NOT NULL,
  frequency           ENUM('daily','weekly','monthly') NOT NULL,
  max_allowed_misses  INT UNSIGNED NOT NULL DEFAULT 0,
  parameters          JSON            NULL,
  created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
  INDEX (group_id)
);

-- 8. STREAKS
CREATE TABLE streaks (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  goal_id        INT UNSIGNED NOT NULL,
  user_id        INT UNSIGNED NOT NULL,
  current_len    INT UNSIGNED NOT NULL DEFAULT 0,
  last_log       DATE            NOT NULL,
  highest_len    INT UNSIGNED NOT NULL DEFAULT 0,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_goal_user (goal_id, user_id),
  FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX (user_id),
  INDEX (current_len)
);
