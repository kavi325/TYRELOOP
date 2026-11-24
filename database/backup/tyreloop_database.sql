

CREATE DATABASE IF NOT EXISTS tyreloop_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tyreloop_db;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS recovery_events, recovery_records, depth_measurements,
  sensor_calibrations, sensor_devices, ai_analysis_results, inspection_images,
  inspections, tyre_ownership_history, tyres, vehicles, organization_members,
  organizations, user_roles, roles, users;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20),
  account_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (account_status IN ('pending','active','suspended','disabled'))
) ENGINE=InnoDB;

CREATE TABLE roles (
  role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE user_roles (
  user_role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  role_id INT UNSIGNED NOT NULL,
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_role (user_id, role_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(role_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_user_roles_role (role_id)
) ENGINE=InnoDB;

CREATE TABLE organizations (
  organization_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  organization_name VARCHAR(150) NOT NULL,
  organization_type VARCHAR(40) NOT NULL,
  registration_number VARCHAR(100) UNIQUE,
  address TEXT,
  contact_number VARCHAR(20),
  email VARCHAR(150),
  approval_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (organization_type IN ('TYRE_SHOP','RECYCLING_CENTRE','RETREADING_CENTRE')),
  CHECK (approval_status IN ('pending','approved','rejected','suspended'))
) ENGINE=InnoDB;

CREATE TABLE organization_members (
  membership_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  organization_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  organization_role VARCHAR(30) NOT NULL,
  membership_status VARCHAR(20) NOT NULL DEFAULT 'active',
  joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_org_member (organization_id, user_id),
  CHECK (organization_role IN ('OWNER','MANAGER','STAFF')),
  CHECK (membership_status IN ('active','pending','inactive','suspended')),
  FOREIGN KEY (organization_id) REFERENCES organizations(organization_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_org_members_user (user_id)
) ENGINE=InnoDB;

CREATE TABLE vehicles (
  vehicle_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  registration_number VARCHAR(30) NOT NULL UNIQUE,
  vehicle_type VARCHAR(50),
  manufacturer VARCHAR(100),
  model VARCHAR(100),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_vehicles_user (user_id)
) ENGINE=InnoDB;

CREATE TABLE tyres (
  tyre_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  vehicle_id INT UNSIGNED NULL,
  current_owner_user_id INT UNSIGNED NULL,
  qr_code VARCHAR(255) NOT NULL UNIQUE,
  brand VARCHAR(100),
  model VARCHAR(100),
  tyre_size VARCHAR(50),
  serial_number VARCHAR(100) UNIQUE,
  manufacture_date DATE,
  installation_date DATE,
  lifecycle_status VARCHAR(40) NOT NULL DEFAULT 'IN_USE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (lifecycle_status IN ('IN_USE','UNDER_INSPECTION','REQUIRES_REVIEW','UNDER_RETREADING','END_OF_LIFE','RECYCLED')),
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON UPDATE CASCADE ON DELETE SET NULL,
  FOREIGN KEY (current_owner_user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_tyres_vehicle (vehicle_id),
  INDEX idx_tyres_owner (current_owner_user_id),
  INDEX idx_tyres_lifecycle (lifecycle_status)
) ENGINE=InnoDB;

CREATE TABLE tyre_ownership_history (
  ownership_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tyre_id INT UNSIGNED NOT NULL,
  previous_owner_user_id INT UNSIGNED NULL,
  new_owner_user_id INT UNSIGNED NOT NULL,
  transfer_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  transfer_notes TEXT,
  FOREIGN KEY (tyre_id) REFERENCES tyres(tyre_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (previous_owner_user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL,
  FOREIGN KEY (new_owner_user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_ownership_tyre_date (tyre_id, transfer_date),
  INDEX idx_ownership_new_user (new_owner_user_id)
) ENGINE=InnoDB;

CREATE TABLE inspections (
  inspection_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tyre_id INT UNSIGNED NOT NULL,
  inspected_by INT UNSIGNED NOT NULL,
  organization_id INT UNSIGNED NULL,
  inspection_type VARCHAR(30) NOT NULL,
  inspection_status VARCHAR(30) NOT NULL DEFAULT 'pending',
  inspection_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  inspection_notes TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (inspection_type IN ('AI_IMAGE','TREAD_DEPTH','COMBINED')),
  CHECK (inspection_status IN ('pending','processing','completed','failed','requires_review')),
  FOREIGN KEY (tyre_id) REFERENCES tyres(tyre_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (inspected_by) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (organization_id) REFERENCES organizations(organization_id) ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_inspections_tyre_date (tyre_id, inspection_date),
  INDEX idx_inspections_user (inspected_by),
  INDEX idx_inspections_org (organization_id)
) ENGINE=InnoDB;

CREATE TABLE inspection_images (
  image_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  inspection_id INT UNSIGNED NOT NULL,
  image_path VARCHAR(500) NOT NULL,
  image_type VARCHAR(30) NOT NULL DEFAULT 'OTHER',
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (image_type IN ('TREAD','SIDEWALL','OTHER')),
  FOREIGN KEY (inspection_id) REFERENCES inspections(inspection_id) ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_images_inspection (inspection_id)
) ENGINE=InnoDB;

CREATE TABLE ai_analysis_results (
  analysis_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  inspection_id INT UNSIGNED NOT NULL,
  image_id INT UNSIGNED NOT NULL,
  predicted_class VARCHAR(100) NOT NULL,
  confidence_score DECIMAL(6,5),
  model_name VARCHAR(100),
  model_version VARCHAR(50),
  analysis_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  analysis_notes TEXT,
  CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1),
  FOREIGN KEY (inspection_id) REFERENCES inspections(inspection_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (image_id) REFERENCES inspection_images(image_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_ai_inspection (inspection_id),
  INDEX idx_ai_image (image_id)
) ENGINE=InnoDB;

CREATE TABLE sensor_devices (
  device_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  device_name VARCHAR(100),
  device_serial_number VARCHAR(100) NOT NULL UNIQUE,
  sensor_model VARCHAR(50) NOT NULL DEFAULT 'VL53L1X',
  organization_id INT UNSIGNED NULL,
  device_status VARCHAR(20) NOT NULL DEFAULT 'active',
  registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (device_status IN ('active','inactive','maintenance')),
  FOREIGN KEY (organization_id) REFERENCES organizations(organization_id) ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_sensor_org (organization_id)
) ENGINE=InnoDB;

CREATE TABLE sensor_calibrations (
  calibration_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  device_id INT UNSIGNED NOT NULL,
  reference_distance_mm DECIMAL(8,3) NOT NULL,
  measured_distance_mm DECIMAL(8,3) NOT NULL,
  calibration_error_mm DECIMAL(8,3) NOT NULL,
  calibrated_by INT UNSIGNED NOT NULL,
  calibration_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  calibration_notes TEXT,
  FOREIGN KEY (device_id) REFERENCES sensor_devices(device_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (calibrated_by) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_calibration_device_date (device_id, calibration_date)
) ENGINE=InnoDB;

CREATE TABLE depth_measurements (
  measurement_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  inspection_id INT UNSIGNED NOT NULL,
  device_id INT UNSIGNED NOT NULL,
  calibration_id INT UNSIGNED NULL,
  surface_distance_mm DECIMAL(8,3),
  groove_distance_mm DECIMAL(8,3),
  calculated_depth_mm DECIMAL(8,3),
  measurement_position VARCHAR(50),
  measurement_status VARCHAR(30) NOT NULL DEFAULT 'pending',
  measurement_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (measurement_status IN ('pending','valid','invalid','requires_review')),
  CHECK (calculated_depth_mm IS NULL OR calculated_depth_mm >= 0),
  FOREIGN KEY (inspection_id) REFERENCES inspections(inspection_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (device_id) REFERENCES sensor_devices(device_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (calibration_id) REFERENCES sensor_calibrations(calibration_id) ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_depth_inspection (inspection_id),
  INDEX idx_depth_device (device_id),
  INDEX idx_depth_calibration (calibration_id)
) ENGINE=InnoDB;

CREATE TABLE recovery_records (
  recovery_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tyre_id INT UNSIGNED NOT NULL,
  initiated_by INT UNSIGNED NOT NULL,
  current_organization_id INT UNSIGNED NULL,
  recovery_type VARCHAR(30) NOT NULL,
  recovery_status VARCHAR(30) NOT NULL DEFAULT 'requested',
  start_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completion_date DATETIME NULL,
  recovery_notes TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (recovery_type IN ('RECYCLING','RETREADING')),
  CHECK (recovery_status IN ('requested','collected','in_transit','received','processing','completed','rejected','cancelled')),
  FOREIGN KEY (tyre_id) REFERENCES tyres(tyre_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (initiated_by) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (current_organization_id) REFERENCES organizations(organization_id) ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_recovery_tyre (tyre_id),
  INDEX idx_recovery_org (current_organization_id),
  INDEX idx_recovery_status (recovery_status)
) ENGINE=InnoDB;

CREATE TABLE recovery_events (
  event_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  recovery_id INT UNSIGNED NOT NULL,
  event_type VARCHAR(40) NOT NULL,
  from_organization_id INT UNSIGNED NULL,
  to_organization_id INT UNSIGNED NULL,
  recorded_by INT UNSIGNED NOT NULL,
  event_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  event_status VARCHAR(30),
  event_notes TEXT,
  CHECK (event_type IN ('COLLECTION','HANDOVER','RECEIVED','PROCESSING_STARTED','PROCESSING_COMPLETED','REJECTED')),
  FOREIGN KEY (recovery_id) REFERENCES recovery_records(recovery_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (from_organization_id) REFERENCES organizations(organization_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (to_organization_id) REFERENCES organizations(organization_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (recorded_by) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_events_recovery_date (recovery_id, event_date),
  INDEX idx_events_from_org (from_organization_id),
  INDEX idx_events_to_org (to_organization_id)
) ENGINE=InnoDB;

INSERT INTO roles (role_name, description) VALUES
('CLIENT', 'Vehicle owner or normal TYRELOOP client'),
('MANAGEMENT', 'Authorized management dashboard user'),
('ADMIN', 'System administrator');


