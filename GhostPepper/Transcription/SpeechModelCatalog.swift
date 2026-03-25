import Foundation

enum SpeechBackendKind: Equatable {
    case whisperKit
    case fluidAudio
}

enum FluidAudioModelVariant: Equatable {
    case parakeetV3
}

struct SpeechModelDescriptor: Identifiable, Equatable {
    let name: String
    let pickerTitle: String
    let variantName: String
    let sizeDescription: String
    let backend: SpeechBackendKind
    let cachePathComponents: [String]
    let fluidAudioVariant: FluidAudioModelVariant?

    var id: String { name }

    var pickerLabel: String {
        "\(pickerTitle) (\(variantName) — \(sizeDescription))"
    }

    var statusName: String {
        switch backend {
        case .whisperKit:
            "Whisper \(variantName) (\(pickerTitle.lowercased()))"
        case .fluidAudio:
            "\(pickerTitle) (\(variantName.lowercased()))"
        }
    }
}

enum SpeechModelCatalog {
    static let whisperTiny = SpeechModelDescriptor(
        name: "openai_whisper-tiny.en",
        pickerTitle: "Speed",
        variantName: "tiny.en",
        sizeDescription: "~75 MB",
        backend: .whisperKit,
        cachePathComponents: ["openai", "whisper-tiny.en"],
        fluidAudioVariant: nil
    )

    static let whisperSmallEnglish = SpeechModelDescriptor(
        name: "openai_whisper-small.en",
        pickerTitle: "Accuracy",
        variantName: "small.en",
        sizeDescription: "~466 MB",
        backend: .whisperKit,
        cachePathComponents: ["openai", "whisper-small.en"],
        fluidAudioVariant: nil
    )

    static let whisperSmallMultilingual = SpeechModelDescriptor(
        name: "openai_whisper-small",
        pickerTitle: "Multilingual",
        variantName: "small",
        sizeDescription: "~466 MB",
        backend: .whisperKit,
        cachePathComponents: ["openai", "whisper-small"],
        fluidAudioVariant: nil
    )

    static let parakeetV3 = SpeechModelDescriptor(
        name: "fluid_parakeet-v3",
        pickerTitle: "Parakeet v3",
        variantName: "25 languages",
        sizeDescription: "~1.4 GB",
        backend: .fluidAudio,
        cachePathComponents: ["FluidInference", "parakeet-tdt-0.6b-v3-coreml"],
        fluidAudioVariant: .parakeetV3
    )

    static let availableModels = [
        whisperTiny,
        whisperSmallEnglish,
        whisperSmallMultilingual,
        parakeetV3,
    ]

    static let defaultModelID = whisperSmallEnglish.id

    static let whisperModels = availableModels.filter { $0.backend == .whisperKit }

    static func model(named name: String) -> SpeechModelDescriptor? {
        availableModels.first { $0.name == name }
    }
}
