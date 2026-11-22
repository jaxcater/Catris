import Foundation
import AVFoundation
import CatrisCore

/// Multi-bus native AVAudioEngine with strict separation:
/// Master -> Music / Ambience / Foley / Cats / UI.
/// Enforces meow cooldown (anti-spam) and max 2 concurrent cat voices per presentation/design.md.
final class AudioEngineManager {
    static let shared = AudioEngineManager()

    private let engine = AVAudioEngine()
    private let musicMixer = AVAudioMixerNode()
    private let ambienceMixer = AVAudioMixerNode()
    private let foleyMixer = AVAudioMixerNode()
    private let catsMixer = AVAudioMixerNode()
    private let uiMixer = AVAudioMixerNode()

    private let musicPlayer = AVAudioPlayerNode()
    private let ambiencePlayer = AVAudioPlayerNode()
    private let purrPlayer = AVAudioPlayerNode()

    private let sfxPoolSize = 8
    private var sfxPlayers: [AVAudioPlayerNode] = []
    private var sfxPitchUnits: [AVAudioUnitTimePitch] = []
    private var sfxPoolCursor = 0

    private let catVoiceCount = 2
    private var catPlayers: [AVAudioPlayerNode] = []
    private var catPitchUnits: [AVAudioUnitTimePitch] = []
    private var catVoiceCursor = 0

    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var currentMapId: String = ""
    private var currentIsNightMusic: Bool? = nil
    private var lastMeowTimeByCat: [String: TimeInterval] = [:]
    private var settings = GameSettings()
    private var isSetup = false

    private init() {
        setupSessionAndGraph()
        observeAudioNotifications()
    }

    private func setupSessionAndGraph() {
        guard !isSetup else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Safe silent fallback on simulator or audio-restricted environments
        }

        let main = engine.mainMixerNode
        for bus in [musicMixer, ambienceMixer, foleyMixer, catsMixer, uiMixer] {
            engine.attach(bus)
            engine.connect(bus, to: main, format: nil)
        }

        engine.attach(musicPlayer)
        engine.connect(musicPlayer, to: musicMixer, format: nil)

        engine.attach(ambiencePlayer)
        engine.connect(ambiencePlayer, to: ambienceMixer, format: nil)

        engine.attach(purrPlayer)
        engine.connect(purrPlayer, to: catsMixer, format: nil)

        for _ in 0..<sfxPoolSize {
            let p = AVAudioPlayerNode()
            let pitch = AVAudioUnitTimePitch()
            engine.attach(p)
            engine.attach(pitch)
            engine.connect(p, to: pitch, format: nil)
            engine.connect(pitch, to: foleyMixer, format: nil)
            sfxPlayers.append(p)
            sfxPitchUnits.append(pitch)
        }

        for _ in 0..<catVoiceCount {
            let p = AVAudioPlayerNode()
            let pitch = AVAudioUnitTimePitch()
            engine.attach(p)
            engine.attach(pitch)
            engine.connect(p, to: pitch, format: nil)
            engine.connect(pitch, to: catsMixer, format: nil)
            catPlayers.append(p)
            catPitchUnits.append(pitch)
        }

        preloadBuffers()
        applySettings(settings)
        startEngineIfNeeded()
        isSetup = true
    }

    private func preloadBuffers() {
        let names = [
            "bgm_day", "bgm_night",
            "amb_m01", "amb_m02", "amb_m03", "amb_m04", "amb_m05",
            "sfx_pickup", "sfx_rotate", "sfx_snap", "sfx_invalid", "sfx_ui_tap", "sfx_solve",
            "cat_meow_high", "cat_meow_mid", "cat_meow_low", "cat_chirp", "cat_grumble", "cat_purr"
        ]
        for name in names {
            if let url = AssetBundle.url(name: name, ext: "wav", folder: "Audio"),
               let file = try? AVAudioFile(forReading: url) {
                let frameCount = AVAudioFrameCount(file.length)
                if let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) {
                    try? file.read(into: buf)
                    buffers[name] = buf
                }
            }
        }
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            engine.prepare()
            try engine.start()
        } catch {
            // Silently ignore if device audio hardware unavailable
        }
    }

    func applySettings(_ newSettings: GameSettings) {
        settings = newSettings
        let master: Float = newSettings.isMuted ? 0.0 : 1.0
        musicMixer.outputVolume    = Float(newSettings.musicVolume) * 0.38 * master
        ambienceMixer.outputVolume = Float(newSettings.ambienceVolume) * 0.42 * master
        foleyMixer.outputVolume    = Float(newSettings.foleyVolume) * 0.85 * master
        catsMixer.outputVolume     = Float(newSettings.catsVolume) * 0.80 * master
        uiMixer.outputVolume       = Float(newSettings.uiVolume) * 0.65 * master
    }

    func setMapAudio(mapId: String) {
        startEngineIfNeeded()
        let isNight = (mapId == "M04" || mapId == "M05")
        if currentIsNightMusic != isNight {
            currentIsNightMusic = isNight
            let track = isNight ? "bgm_night" : "bgm_day"
            if let buf = buffers[track] {
                musicPlayer.stop()
                musicPlayer.scheduleBuffer(buf, at: nil, options: .loops, completionHandler: nil)
                musicPlayer.play()
            }
        }

        if currentMapId != mapId {
            currentMapId = mapId
            let ambName = "amb_\(mapId.lowercased())"
            if let buf = buffers[ambName] {
                ambiencePlayer.stop()
                ambiencePlayer.scheduleBuffer(buf, at: nil, options: .loops, completionHandler: nil)
                ambiencePlayer.play()
            }
        }
    }

    func playPickup() { playFoley("sfx_pickup", pitchCents: Float.random(in: -35...35)) }
    func playRotate() { playFoley("sfx_rotate", pitchCents: Float.random(in: -30...30)) }
    func playSnap()   { playFoley("sfx_snap", pitchCents: Float.random(in: -40...40)) }
    func playInvalid() { playFoley("sfx_invalid", pitchCents: Float.random(in: -20...20)) }
    func playUITap()  { playFoley("sfx_ui_tap", pitchCents: Float.random(in: -25...25)) }
    func playSolve()  { playFoley("sfx_solve", pitchCents: 0) }

    func playCatMeow(catId: String, pitchMultiplier: Double, force: Bool = false) {
        let now = Date().timeIntervalSinceReferenceDate
        if !force, let last = lastMeowTimeByCat[catId], now - last < 7.5 {
            return // Respect cozy meow cooldown (no per-drag meow spam!)
        }
        lastMeowTimeByCat[catId] = now
        let bank = pitchMultiplier > 1.12 ? "cat_meow_high" : (pitchMultiplier < 0.90 ? "cat_meow_low" : "cat_meow_mid")
        let cents = Float(1200.0 * log2(max(0.65, min(1.45, pitchMultiplier)))) + Float.random(in: -40...40)
        playCatVoice(bank, pitchCents: cents)
    }

    func playCatChirp(pitchMultiplier: Double) {
        let cents = Float(1200.0 * log2(max(0.75, min(1.35, pitchMultiplier))))
        playCatVoice("cat_chirp", pitchCents: cents)
    }

    func playCatGrumble(pitchMultiplier: Double) {
        let cents = Float(1200.0 * log2(max(0.70, min(1.30, pitchMultiplier))))
        playCatVoice("cat_grumble", pitchCents: cents)
    }

    func playCatPurrPulse() {
        guard !settings.isMuted, let buf = buffers["cat_purr"] else { return }
        startEngineIfNeeded()
        purrPlayer.stop()
        purrPlayer.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
        purrPlayer.play()
    }

    private func playFoley(_ name: String, pitchCents: Float) {
        guard !settings.isMuted, let buf = buffers[name] else { return }
        startEngineIfNeeded()
        let idx = sfxPoolCursor % sfxPoolSize
        sfxPoolCursor += 1
        let player = sfxPlayers[idx]
        sfxPitchUnits[idx].pitch = pitchCents
        player.stop()
        player.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    private func playCatVoice(_ name: String, pitchCents: Float) {
        guard !settings.isMuted, let buf = buffers[name] else { return }
        startEngineIfNeeded()
        let idx = catVoiceCursor % catVoiceCount
        catVoiceCursor += 1
        let player = catPlayers[idx]
        catPitchUnits[idx].pitch = pitchCents
        player.stop()
        player.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    func handleBackground() {
        engine.pause()
    }

    func handleForeground() {
        try? AVAudioSession.sharedInstance().setActive(true)
        startEngineIfNeeded()
    }

    private func observeAudioNotifications() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let info = note.userInfo,
                  let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
            if type == .began {
                self.engine.pause()
            } else if type == .ended {
                self.handleForeground()
            }
        }
    }
}
