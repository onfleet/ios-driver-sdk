# Change Log
Breaking changes and additions to to Onfleet SDK will be documented in this file.

## [0.16] - 2023-04-26

### Added

- new flag `haveToRespectTasksOrder` for `Organization` model and `DriverManaging` interface

### Changed

- `isTaskOrderEnforced` was renamed into `shouldRespectTasksOrder`

### Notes

- `isTaskOrderEnforced` will be removed in future release!

## [0.15] - 2023-04-01

### Added

- support to define notes for success and failure completion results
- support to specify optional App group definition
- support to specify optional Keychain sharing access group definition
- `DriverManaging` selfAssign function now takes a list of tasks to be self-assigned

### Changed

- conformance to localized error for SDKs errors definitions
- data fetching mechanism
- small access control definitions for models
- models don't have any longer getter for specific properties
- deinitialization now has proper clean up to reduce memory footage
- init function now accept `AppConfig` definition instead of `Config`

### Fixed

- automatic fetching data
- closing session when there is no proper connection