## 1. Core Implementation
- [x] 1.1 Modify `JanusSession.attach<T>()` method signature to accept optional `existingHandleId` parameter
- [x] 1.2 Extract existing handle creation logic into `_createNewPluginHandle<T>()` helper method
- [x] 1.3 Extract plugin instance creation logic into `_createPluginInstance<T>()` helper method
- [x] 1.4 Add session validation logic to ensure session is active before re-attachment
- [x] 1.5 Implement re-attachment flow that skips Janus "attach" request when existingHandleId is provided

## 2. Plugin Instance Management
- [x] 2.1 Ensure re-attached plugins are properly registered in `_pluginHandles` registry
- [x] 2.2 Verify plugin initialization (`_init()` and `onCreate()`) works for re-attached plugins
- [x] 2.3 Test that WebRTC setup and event handling work for re-attached plugins
- [x] 2.4 Confirm plugin cleanup and disposal work correctly for re-attached plugins

## 3. Backward Compatibility
- [x] 3.1 Verify existing `session.attach<T>()` calls work without any changes
- [x] 3.2 Test that `existingHandleId: null` behaves identical to omitting the parameter
- [x] 3.3 Ensure all plugin types (VideoRoom, SIP, Streaming, etc.) support re-attachment
- [x] 3.4 Validate that normal plugin creation still sends "attach" requests to Janus

## 4. Error Handling
- [x] 4.1 Add exception for re-attachment attempts when session is not active
- [x] 4.2 Ensure proper error propagation when invalid handle IDs are used
- [x] 4.3 Test that transport-level errors are properly handled during re-attachment
- [x] 4.4 Verify error messages are clear and actionable for developers

## 5. Testing
- [x] 5.1 Create unit tests for re-attachment functionality in `JanusSession`
- [x] 5.2 Create integration tests demonstrating "abandon and reclaim" flow
- [x] 5.3 Test re-attachment with both WebSocket and REST transports
- [x] 5.4 Verify plugin operations (send, keepAlive, etc.) work after re-attachment
- [x] 5.5 Test event handling and stream management for re-attached plugins

## 6. Documentation and Examples
- [x] 6.1 Create `openspec/changes/plugin-handle-reattachment/docs.md` with comprehensive documentation
- [x] 6.2 Update API documentation for `JanusSession.attach<T>()` method in docs.md
- [x] 6.3 Add usage examples showing re-attachment in "abandon and reclaim" scenarios in docs.md
- [x] 6.4 Document error handling patterns for re-attachment failures in docs.md
- [x] 6.5 Document session reclamation + plugin re-attachment flow in docs.md
- [x] 6.6 Add notes about when to use re-attachment vs normal plugin attachment in docs.md
- [x] 6.7 Include complete example demonstrating SIP call handling across isolates using re-attachment in docs.md
- [x] 6.8 Show background isolate creating session + plugin handle in docs.md example
- [x] 6.9 Show main isolate reclaiming session and re-attaching to plugin handle in docs.md example
- [x] 6.10 Demonstrate continued plugin operations (accept/decline call) after re-attachment in docs.md example

## 7. Validation and Review
- [x] 7.1 Run `openspec validate plugin-handle-reattachment --strict` to ensure compliance
- [x] 7.2 Perform manual testing with actual Janus server
- [x] 7.3 Review code changes for security implications
- [x] 7.4 Validate performance impact is minimal for normal plugin attachment
- [x] 7.5 Ensure all existing tests continue to pass