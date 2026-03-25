# FluidAudio STT Backend Design

**Goal:** Add a second local speech-to-text backend so GhostPepper can offer Whisper and Parakeet-family transcription models from one model picker without exposing backend details in the UI.

## Current State

GhostPepper is currently Whisper-first:

- `AppState` owns a concrete `WhisperTranscriber`
- `ModelManager` assumes every speech model is a WhisperKit model
- Settings exposes a single Whisper model picker
- Model inventory and onboarding also assume a single STT backend

That structure blocks any clean introduction of FluidAudio or other speech backends.

## Constraints

- No Python in the shipped app
- Keep the app local and Apple-native
- Preserve the current Whisper path while adding Parakeet support
- The user chooses a model, not a backend
- Make the smallest reasonable change that leaves room for future STT backends

## Recommended Architecture

Introduce a hidden backend seam behind a unified speech model catalog.

### Speech Model Catalog

Create a single speech model catalog that defines every selectable STT model. Each entry contains:

- stable model ID
- user-facing name
- size label
- capabilities labels
- backend kind
- backend-specific configuration payload

The picker, onboarding, and model inventory will render from this catalog.

### Backend Abstraction

Introduce a small `SpeechTranscriptionBackend` interface responsible for:

- exposing available models for that backend
- loading a selected model
- reporting readiness and download state
- transcribing an audio buffer
- exposing cached model information for inventory UI

Two concrete backends:

- `WhisperKitSpeechBackend`
- `FluidAudioSpeechBackend`

`AppState` should depend on a single speech controller that routes model selection to the correct backend.

### Speech Controller

Replace the current Whisper-specific controller path with a generic speech controller that:

- stores the selected speech model ID
- resolves the selected catalog entry
- loads the correct backend and model
- delegates transcription to the active backend
- exposes aggregated model status to onboarding and settings

This keeps backend routing out of the rest of the app.

## Initial Model Set

Expose these models in one unified picker:

- Whisper tiny.en
- Whisper small.en
- Whisper small multilingual
- Parakeet v3

Leave FluidAudio streaming and Qwen3 ASR out of the first pass. They are distinct enough to warrant separate product decisions later.

## UX

The user sees one "Speech Model" picker.

The app does not mention WhisperKit or FluidAudio in normal settings flows. Backend identity is internal. Model inventory remains model-first and shows whichever STT models are selectable, plus cleanup models.

## Error Handling

- If a backend fails to load, surface the error as a model-loading error, not a backend-internal error
- Switching between models on different backends should cleanly unload the old active backend state
- Missing models should remain downloadable from the unified inventory UI

## Testing

Add test coverage for:

- unified speech model catalog contents and backend routing
- switching selected model across backends
- inventory rows showing all selectable speech models
- app initialization loading the selected model through the correct backend
- transcription delegation through a backend-neutral interface

## Non-Goals

- Replacing Whisper outright
- Shipping Python or MLX runtime support
- Exposing streaming Parakeet as a first-pass user option
- Refactoring unrelated cleanup model behavior
