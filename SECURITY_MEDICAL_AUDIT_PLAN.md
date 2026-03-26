# Medical Vertical Security and Audit Plan

## Scope

This plan covers healthcare-professional companies only.
It does not include storage of advanced medical records.

## Sensitive operations audited

- Medical profile updates:
  - professional category
  - specialty
  - convention sector
  - teleconsultation flag
  - accessibility information
  - practical information
  - cancellation policy
- Medical scheduling settings updates:
  - slot interval
  - buffer between appointments
  - controlled overbooking flags and limits
  - emergency capacity
- Company closures:
  - create closure
  - delete closure
- Appointments from company back-office:
  - create
  - update
  - cancel

## Audit event model

- Table: `medical_audit_logs`
- Fields:
  - `company_id`
  - `user_id` (nullable for future system events)
  - `action`
  - `record_type`
  - `record_id`
  - `metadata` (jsonb)
  - `created_at`

## Current implementation notes

- Logging is enabled only when `company.healthcare_professional?`.
- Metadata stores relevant changed fields or contextual attributes.
- Logs are immutable by convention from application flows.

## Reinforced test plan

### 1. Access and authorization

- Verify only company admins can trigger audited healthcare operations.
- Verify cross-company access is denied and not logged as successful action.

### 2. Audit integrity

- For each sensitive operation, assert exactly one log entry is created.
- Assert `action`, `record_type`, `record_id`, and `company_id` are correct.
- Assert `user_id` matches the authenticated actor.

### 3. Data minimization

- Assert audit metadata never stores medical dossier data.
- Assert metadata only contains operational fields necessary for traceability.

### 4. Failure behavior

- Invalid updates should not create success audit logs.
- Successful operations with downstream async jobs still keep synchronous audit trace.

### 5. Regression suite (minimum)

- `test/controllers/company/medical_audit_logging_test.rb`
- `test/controllers/company/profiles_controller_test.rb`
- `test/controllers/company/settings_controller_test.rb`
- `test/controllers/company/company_closures_controller_test.rb`
- `test/models/medical_audit_log_test.rb`

## Operational recommendations (next step)

- Add a read-only audit screen for healthcare companies.
- Add retention policy and export endpoint for compliance requests.
- Add alerting on unusual patterns (mass cancellations, repeated profile rewrites).
