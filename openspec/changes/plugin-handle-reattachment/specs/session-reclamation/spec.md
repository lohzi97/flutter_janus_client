## ADDED Requirements
### Requirement: Plugin Handle Re-attachment
The package SHALL support re-attaching to existing plugin handles within reclaimed sessions without sending new "attach" requests to the Janus server.

#### Scenario: Successful Plugin Handle Re-attachment
**Given** an application has a reclaimed Janus session with existing plugin handles
**When** the application calls `session.attach<PluginType>(existingHandleId: handleId)`
**Then** the package SHALL create a plugin instance using the provided handle ID
**And** SHALL NOT send an "attach" request to the Janus server
**And** SHALL register the plugin instance in the session's plugin handle registry
**And** SHALL initialize the plugin for WebRTC operations and event handling

#### Scenario: Plugin Handle Re-attachment with Invalid Handle
**Given** an application calls `session.attach<PluginType>(existingHandleId: invalidHandleId)`
**When** the method executes
**Then** the package SHALL validate that the session is active before re-attachment
**And** SHALL create the plugin instance with the provided handle ID
**And** subsequent plugin operations SHALL fail with appropriate Janus server errors if the handle is invalid

#### Scenario: Plugin Handle Re-achment Session Validation
**Given** an application calls `session.attach<PluginType>(existingHandleId: handleId)`
**When** the session ID is null or the session is not active
**Then** the package SHALL throw an exception indicating the session is not active
**And** SHALL not proceed with plugin re-attachment

### Requirement: Backward Compatible Plugin Attachment
The plugin re-attachment feature SHALL maintain full backward compatibility with existing plugin attachment functionality.

#### Scenario: Normal Plugin Attachment Unchanged
**Given** an application calls `session.attach<PluginType>()` without existingHandleId parameter
**When** the method executes
**Then** it SHALL behave exactly as before the re-attachment feature was added
**And** SHALL send an "attach" request to create a new plugin handle
**And** SHALL not attempt plugin re-attachment

#### Scenario: Optional Existing Handle ID Parameter
**Given** an application calls `session.attach<PluginType>(existingHandleId: null)`
**When** existingHandleId is null
**Then** the method SHALL treat it as a normal plugin attachment request
**And** SHALL send an "attach" request to create a new plugin handle

### Requirement: Plugin Registry Management
The package SHALL properly manage plugin instances when using handle re-attachment.

#### Scenario: Plugin Registry Registration
**Given** a plugin is successfully re-attached using existingHandleId
**When** re-attachment completes
**Then** the plugin instance SHALL be registered in `_pluginHandles[handleId]`
**And** SHALL be available for session-level operations and cleanup

#### Scenario: Plugin Instance Initialization
**Given** a plugin instance is created with an existing handle ID
**When** the plugin is re-attached
**Then** the package SHALL call the plugin's `_init()` method
**And** SHALL call the plugin's `onCreate()` method
**And** SHALL set up WebRTC and event handling capabilities

### Requirement: Plugin Operation Compatibility
Re-attached plugin handles SHALL support all standard plugin operations.

#### Scenario: Standard Plugin Operations
**Given** a plugin is re-attached to an existing handle
**When** application calls standard plugin methods (send, keepAlive, etc.)
**Then** these operations SHALL work identically to normally attached plugins
**And** SHALL use the existing handle ID for Janus server communication

#### Scenario: Plugin Event Handling
**Given** a plugin is re-attached to an existing handle with active operations
**When** Janus server sends events for that handle ID
**Then** the re-attached plugin instance SHALL receive and process these events
**And** SHALL emit them through the standard plugin event streams