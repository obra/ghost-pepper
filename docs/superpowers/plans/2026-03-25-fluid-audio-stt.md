# FluidAudio STT Backend Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a unified speech model picker that routes internally to WhisperKit or FluidAudio so GhostPepper can offer Parakeet v3 without exposing backend details.

**Architecture:** Introduce a backend-neutral speech model catalog and speech controller, keep WhisperKit behind one backend, add FluidAudio behind a second backend, and update the UI to render models from the unified catalog. The existing app should continue to behave the same for Whisper users while making Parakeet v3 selectable.

**Tech Stack:** Swift, SwiftUI, XcodeGen/Xcode project, WhisperKit, FluidAudio, XCTest

---

## Chunk 1: Catalog And Backend Surface

### Task 1: Define unified speech model types

**Files:**
- Create: `GhostPepper/Transcription/SpeechModelCatalog.swift`
- Test: `GhostPepperTests/SpeechModelCatalogTests.swift`

- [ ] Step 1: Write failing tests for the unified speech model catalog
- [ ] Step 2: Run targeted tests to verify they fail for missing types
- [ ] Step 3: Add minimal model catalog and backend kind types
- [ ] Step 4: Run targeted tests to verify they pass
- [ ] Step 5: Commit

### Task 2: Define backend-neutral speech interfaces

**Files:**
- Create: `GhostPepper/Transcription/SpeechTranscriptionBackend.swift`
- Modify: `GhostPepper/Transcription/ModelManager.swift`
- Test: `GhostPepperTests/SpeechBackendRoutingTests.swift`

- [ ] Step 1: Write failing tests for model-to-backend routing and selected-model loading
- [ ] Step 2: Run targeted tests to verify they fail
- [ ] Step 3: Add the minimal backend protocol and adapt Whisper model metadata to the shared catalog
- [ ] Step 4: Run targeted tests to verify they pass
- [ ] Step 5: Commit

## Chunk 2: Whisper And FluidAudio Backends

### Task 3: Move Whisper behavior behind a backend

**Files:**
- Create: `GhostPepper/Transcription/WhisperKitSpeechBackend.swift`
- Modify: `GhostPepper/Transcription/WhisperTranscriber.swift`
- Modify: `GhostPepper/AppState.swift`
- Test: `GhostPepperTests/WhisperBackendTests.swift`

- [ ] Step 1: Write failing tests for Whisper backend load and transcription delegation
- [ ] Step 2: Run targeted tests to verify they fail
- [ ] Step 3: Implement the minimal Whisper backend and controller integration
- [ ] Step 4: Run targeted tests to verify they pass
- [ ] Step 5: Commit

### Task 4: Add FluidAudio package and backend

**Files:**
- Modify: `project.yml`
- Modify: `GhostPepper.xcodeproj/project.pbxproj`
- Modify: `GhostPepper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- Create: `GhostPepper/Transcription/FluidAudioSpeechBackend.swift`
- Test: `GhostPepperTests/FluidAudioBackendTests.swift`

- [ ] Step 1: Write failing tests for FluidAudio model selection and backend state reporting
- [ ] Step 2: Run targeted tests to verify they fail
- [ ] Step 3: Add the FluidAudio package and implement the minimal Parakeet v3 backend
- [ ] Step 4: Run targeted tests to verify they pass
- [ ] Step 5: Commit

## Chunk 3: UI And Integration

### Task 5: Replace Whisper-specific settings state with selected speech model state

**Files:**
- Modify: `GhostPepper/AppState.swift`
- Modify: `GhostPepper/UI/SettingsWindow.swift`
- Test: `GhostPepperTests/GhostPepperTests.swift`

- [ ] Step 1: Write failing tests for selected speech model persistence and initialization
- [ ] Step 2: Run targeted tests to verify they fail
- [ ] Step 3: Implement the minimal selected speech model state wiring
- [ ] Step 4: Run targeted tests to verify they pass
- [ ] Step 5: Commit

### Task 6: Update onboarding and model inventory to use the unified speech catalog

**Files:**
- Modify: `GhostPepper/ModelInventory.swift`
- Modify: `GhostPepper/UI/ModelInventoryViews.swift`
- Modify: `GhostPepper/UI/OnboardingWindow.swift`
- Modify: `GhostPepper/UI/SettingsWindow.swift`
- Test: `GhostPepperTests/RuntimeModelInventoryTests.swift`

- [ ] Step 1: Write failing tests for unified speech model inventory rows
- [ ] Step 2: Run targeted tests to verify they fail
- [ ] Step 3: Implement the minimal inventory updates
- [ ] Step 4: Run targeted tests to verify they pass
- [ ] Step 5: Commit

## Chunk 4: Final Verification

### Task 7: Full regression and testable app build

**Files:**
- Modify only as needed for fallout

- [ ] Step 1: Run the full GhostPepper test suite
- [ ] Step 2: Fix any regressions with additional red/green cycles
- [ ] Step 3: Build a local testable app
- [ ] Step 4: Commit the final integration state
