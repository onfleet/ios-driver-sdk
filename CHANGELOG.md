# Change Log
Breaking changes and additions to to Onfleet SDK will be documented in this file.

## [0.43] - 2026-03-12

### Breaking Changes

- The minimum supported iOS version is now iOS 16 (previously iOS 13). Integrators must build against iOS 16 or later.
- `DriverContext.tasksManager` now returns `any TasksManagerProtocol` (formerly `TasksManaging`, then `OnfleetTasksManaging`). The task and driver manager protocols were migrated to a unified, `Sendable` `…ManagerProtocol` family (`TasksManagerProtocol`, `DriverManagerProtocol`, `RoutePlansManagerProtocol`, `OrganizationManagerProtocol`, `DutyStatusManagerProtocol`); update references to the old protocol names.
- `CompletedTask.pickupTask: Bool` has been replaced by `CompletedTask.type: TaskType` (cases `pickUp`, `dropOff`, `end(at:)`, `unknown(Int)`). Replace reads of `pickupTask` with `type` (use `type.isPickUp` for the previous boolean).
- `Recipient.name` and `Recipient.notes` changed from `String?` to `OverrideableProperty<String?>`; read `.value` to obtain the underlying optional string.
- Task completion requirements are now tri-state: `photo`, `signature`, and `notes` on `Onfleet.Task.Requirements` (and the related organization/legacy requirement models) changed from `Bool` to `Bool?`, distinguishing "not configured" from "not required". Update code that reads these as non-optional booleans. ([Proof of Delivery](https://support.onfleet.com/hc/en-us/articles/10348848090644-Proof-of-Delivery))
- `CompleteTaskError` now conforms to `LocalizedError`, and the associated value of its `.internal` case changed: the nested `CompleteTaskError.InternalReason` enum was removed in favor of a shared `InternalReasonError`. Update pattern matches on `.internal(.missingData)` / `.internal(.synchronization(_:))` to match `.internal(_:)` and inspect the new `InternalReasonError`. `StartTaskError`, `DutyStatusError`, `UpdateProfileError`, and `SelfAssignError` were realigned to the same `InternalReasonError`.
- The legacy tasks content provider's `tasks` published property has been renamed to `availableTasks`. Update observers of `tasks` to use `availableTasks`.

### Added Features

- **Custom fields** ([Custom Fields](https://support.onfleet.com/hc/en-us/articles/21799942217748-Custom-Fields))
- **Route plans** ([Route Plans](https://support.onfleet.com/hc/en-us/articles/25492148360596-Route-Plans))
- **Self-assign tasks** ([Self-Assign Tasks & Routes](https://support.onfleet.com/hc/en-us/articles/360041740172-Self-Assign-Tasks-Routes))
- **End-of-route task types** ([End Route / Return to Hub](https://support.onfleet.com/hc/en-us/articles/34992206461716-End-Route-Return-to-Hub))
- **Route load & bulk pick-up task types**
- **Hidden requirement state**
- **Custom task completion requirements** ([Proof of Delivery](https://support.onfleet.com/hc/en-us/articles/10348848090644-Proof-of-Delivery))
- **Custom completion reasons** ([Custom Task Completion Reasons](https://support.onfleet.com/hc/en-us/articles/9382652814228-Custom-Task-Completion-Reasons))
- **Age attestation** ([Complete a Task](https://support.onfleet.com/hc/en-us/articles/10373142665364-Complete-a-Task#h_01GGAK84GT77TGWRK5GHTH065X))
- **Order short id**
- **Completed-task PII setting** ([Remove PII from Driver Task History](https://support.onfleet.com/hc/en-us/articles/38159626547348-Remove-Personally-Identifiable-Information-PII-from-Driver-Task-History))

### Added

- Tasks expose their custom fields through the public `CustomField` model, with a typed `CustomField.Value` (boolean, integer, decimal, date, URL, single- and multi-line text, and a `checklist` of `ChecklistItem` values) and per-field `Context`; included in the completed-task representation and kept current from live updates.
- `Onfleet.RoutePlan` model — its state, vehicle type, scheduled/actual start–end times, planned distance/duration, and an ordered list of nested `RoutePlan.Task` entries (each with its own state and `type`). Route plans are provided through `DriverContext.routePlansManager` (a `RoutePlansManagerProtocol`) via the `activeRoutePlans` / `assignedRoutePlans` / `availableRoutePlans` streams; `Onfleet.Task` / `Legacy.Task` expose the associated `routePlan`.
- `Onfleet.Driver.selfAssignableTasks` surfaces the tasks a driver can claim.
- `Onfleet.TaskType.end(at:)` with `EndAt.hub` (end at a hub) and `EndAt.driverAddress` (end at the driver's address).
- `Onfleet.TaskType.routeLoad` (loading at a hub) and `Onfleet.TaskType.bulkLoadPickup` (grouping two or more pickups from the same address), with helpers `isRouteLoad`, `isBulkLoadPickup`, and `requiresBulkVerification`.
- `photo`, `signature`, and `notes` on `Onfleet.Task.Requirements` (and the organization/legacy requirement models) are now `Bool?`; `nil` means the requirement is hidden / not configured (see Breaking Changes for the migration).
- `Onfleet.CustomRequirement` type (`Visibility` — `api` / `admin` / `worker` — a `ValueType` including a `checklist` value type, `Value`, `Text`, and `key`) and a `customRequirements` collection on `Onfleet.Task`, plus an `Onfleet.Task.CompletionRequirement` model. Task completion can now fail with `CompleteTaskError.validation([ValidationFailure])`, reporting `missingRequired` / `typeMismatch`.
- `Onfleet.Organization.packageCompletionReasons` (and `getPackageCompletionReasons()`); each entry is an `Organization.CompletionReason` with a `completionStatus`.
- `attestationAge` on `TaskCompletionDetails`, `Onfleet.Task.Requirements`, and `Legacy.Task.Requirements`.
- `Onfleet.Task.orderShortId` on the public task model.
- `shouldHideCompletedTaskPII` on `Onfleet.Organization` and the `DriverManaging` provider.
- `merchantName` on `Onfleet.Task` / `Legacy.Task` and `CompletedTask`; `serviceTime` on `Onfleet.Task` / `Legacy.Task` (with `getServiceTime()` on `Legacy.Task`).
- `Onfleet.StructuredValue` — a public, read-only structured value type for arbitrary nested configuration data, queryable by subscript. `Onfleet.Organization` exposes `config`, `driverAppConfig`, and `enabledFeatures` as `StructuredValue`, and `Onfleet.Organization.Billing` exposes `commConfig` and `overrides`.
- `Onfleet.AccountsEvent` (`LogoutReason`, `InvitationResponse`, `RemoveReason`), `Onfleet.Account` (`InvitationStatus`), and `LoginDetails`; `DriverProfileDetails` with a nested `Vehicle` and factories (`.car`, `.truck`, `.motorcycle`, `.bicycle`, `.none`); `Onfleet.DataAvailabilityEvent` and the `DriverManaging` provider.
- `pendingTask` and `pendingImageUpload` streams expose `Onfleet.PendingTask` and `Onfleet.PendingImageUpload` for tasks and uploads that are not yet synchronized.
- `Onfleet.Organization.enabledFeaturesConfiguration` — an `EnabledFeaturesConfiguration` (including a `fairmatic` flag).
- `Onfleet.ProcessingType.isRealized` convenience property.
- Required-barcode models (`Onfleet.RequiredBarcode` / `Legacy.BarcodeRequest`) expose `id`, a `noBarcode` flag, and task association (originating task ID and drop-off task); `barcodeScanning` and `allowManualPackageVerification` flags on the organization configuration; `TaskCompletionDetails.Barcode` carries `id`, `data`, `symbology`, `wasRequested`, and an optional `Failure` (`reasonID`, `notes`); age-verification scanning reads both MRZ text and barcodes.
- `DriverContext.dutyStatusManager` (a `DutyStatusManagerProtocol`) exposes the `dutyStatus` stream and `setDutyStatus(…)`.

### Changed

- `ApplicationConfig` was reshaped (typed `ApplicationGroupIdentifier`, a `keychainSharing` access group, and a throwing `ApplicationConfigError`). Review your `ApplicationConfig` construction against the updated initializer.
- SDK error types now conform to `LocalizedError` and provide `errorDescription` for user-facing messages.
- Task completion requirements (photo, signature, notes) are evaluated using the pickup-style rule, so route-load tasks are treated like pickups. ([Proof of Delivery](https://support.onfleet.com/hc/en-us/articles/10348848090644-Proof-of-Delivery))
- Conformance additions: `Onfleet.BarcodeRequest` (`Hashable`, `Sendable`) and `Onfleet.LocationAccuracyPermission` (`Sendable`).

### Fixed

- Resolved a SIGBUS crash that could occur while the SDK forwarded location updates.
- Fixed crashes encountered on connection problems and when the active account changed.
- Fixed claiming of linked tasks. ([Self-Assign Tasks & Routes](https://support.onfleet.com/hc/en-us/articles/360041740172-Self-Assign-Tasks-Routes))
- Fixed the complete-task button on iPad.
- Corrected handling of optional overrideable properties on public models.
- Corrected the transformation of worker vehicles between received and stored representations.

## [0.17.2] - 2023-11-29

### Fixed

- driverAvailable provides correct value when drive has got logged out

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
