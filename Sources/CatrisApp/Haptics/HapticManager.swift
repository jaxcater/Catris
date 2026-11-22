import Foundation
import CoreHaptics
import UIKit

/// Tactile CoreHaptics manager with graceful UIImpactFeedbackGenerator fallback on unsupported devices/Simulator.
final class HapticManager {
    static let shared = HapticManager()

    var isEnabled: Bool = true
    private var engine: CHHapticEngine?
    private let supportsHaptics: Bool

    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        prepareEngine()
    }

    private func prepareEngine() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    func playPickup() {
        guard isEnabled else { return }
        playTransient(intensity: 0.45, sharpness: 0.35, fallback: .light)
    }

    func playRotate() {
        guard isEnabled else { return }
        playTransient(intensity: 0.55, sharpness: 0.72, fallback: .soft)
    }

    func playSnap() {
        guard isEnabled else { return }
        playTransient(intensity: 0.65, sharpness: 0.25, fallback: .medium)
    }

    func playInvalid() {
        guard isEnabled else { return }
        guard supportsHaptics, let engine else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        let e1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.70),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.80)
            ],
            relativeTime: 0.0
        )
        let e2 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.65)
            ],
            relativeTime: 0.09
        )
        playPattern([e1, e2], on: engine)
    }

    func playPurrOrSolve() {
        guard isEnabled else { return }
        guard supportsHaptics, let engine else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }
        let rumble = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.42),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.14)
            ],
            relativeTime: 0.0,
            duration: 0.55
        )
        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.20),
                .init(relativeTime: 0.25, value: 0.55),
                .init(relativeTime: 0.55, value: 0.08)
            ],
            relativeTime: 0.0
        )
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: [rumble], parameterCurves: [curve])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    private func playTransient(intensity: Float, sharpness: Float, fallback: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard supportsHaptics, let engine else {
            UIImpactFeedbackGenerator(style: fallback).impactOccurred()
            return
        }
        let ev = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0.0
        )
        playPattern([ev], on: engine)
    }

    private func playPattern(_ events: [CHHapticEvent], on engine: CHHapticEngine) {
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
}
