import PofuDesignSystem
import PofuSound
import SwiftUI

/// The music room (music-system-v1 MU3): in Rehearsal mode the founder picks an
/// island, an hour, the weather, the season, the stage and Pofu's wellbeing, sees
/// what `MusicDirector` answers for that state, and plays it. It is a glass card
/// over the bottom of the screen, like the tuning lab, so the island stays visible.
///
/// While it plays, `MusicPlayer` takes this state in place of the world's own;
/// closing the room, or Stop, gives the world its music back. The Settings music
/// switch and the Silent switch still win: with the switch off nothing plays.
struct MusicRoomPanel: View {
    let rehearsal: RehearsalStage

    /// Opens scrolled to the stingers (the screenshot test uses it to show that section).
    private let startsAtStingers: Bool

    @State private var state: MusicState
    @State private var isPlaying = false
    @State private var isMusicOn = SoundEngine.shared.settings.isMusicOn
    @State private var index = (try? MusicIndex.bundled()) ?? .empty

    /// Opens on the island as it is now (`model`'s world at the rehearsed time), in clear weather.
    init(model: AppModel, rehearsal: RehearsalStage, startsAtStingers: Bool = false) {
        self.rehearsal = rehearsal
        self.startsAtStingers = startsAtStingers
        _state = State(initialValue: WorldSound.musicRoomSeed(of: model.world, at: rehearsal.clock.now))
    }

    private var answer: MusicRoomAnswer {
        MusicRoom.answer(for: state, isMusicOn: isMusicOn, index: index, tuning: SoundEngine.shared.volumes)
    }

    private var canPlay: Bool {
        if case .phrase = answer { return true }
        return false
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                header
                Divider()
                ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: PofuSpacing.m) {
                        if !isMusicOn {
                            Text("Island music is off in Settings, so nothing plays here.")
                                .font(PofuFont.caption)
                                .foregroundStyle(PofuColor.warning)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        pickers
                        Divider()
                        answerCard
                        playButton
                        Divider()
                        stingers
                            .id("stingers")
                    }
                    .padding(PofuSpacing.m)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    if startsAtStingers { reader.scrollTo("stingers", anchor: .bottom) }
                }
                }
            }
            .frame(height: min(proxy.size.height * 0.62, 560))
            // The content scrolls inside the card's own shape, and a tint under the glass
            // keeps the island's chrome from showing through as ghost shapes.
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .background(PofuColor.card.opacity(0.88), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, PofuSpacing.xs)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .onChange(of: state) { _, new in
            // Changing the state while it plays moves the sound to the new state.
            if isPlaying { MusicPlayer.shared.audition(new) }
        }
        .onDisappear {
            MusicPlayer.shared.audition(nil)
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(spacing: PofuSpacing.s) {
            Image(systemName: "music.note.house.fill")
                .accessibilityHidden(true)
            Text("Music room")
                .font(PofuFont.headline)
            Spacer(minLength: PofuSpacing.xs)
            Button {
                rehearsal.isMusicRoomOpen = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(PofuFont.title3)
                    .foregroundStyle(PofuColor.textSecondary)
                    .frame(width: PofuSize.minimumTouch, height: PofuSize.minimumTouch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close"))
        }
        .foregroundStyle(PofuColor.textPrimary)
        .padding(.horizontal, PofuSpacing.m)
        .padding(.top, PofuSpacing.xs)
    }

    // MARK: - Pickers

    private var pickers: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            row("Island") {
                Picker(selection: $state.island) {
                    ForEach(MusicIsland.allCases, id: \.self) { island in
                        islandName(island).tag(island)
                    }
                } label: {
                    Text("Island")
                }
                .pickerStyle(.menu)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Hour")
                    Spacer()
                    Text(verbatim: String(format: "%02d:00", state.hour))
                        .monospacedDigit()
                        .foregroundStyle(PofuColor.textSecondary)
                }
                .font(PofuFont.subheadline)
                Slider(
                    value: Binding(get: { Double(state.hour) }, set: { state.hour = Int($0.rounded()) }),
                    in: 0...23, step: 1
                ) {
                    Text("Hour")
                }
            }
            row("Weather") {
                Picker(selection: $state.weather) {
                    ForEach(AmbienceWeather.allCases, id: \.self) { weather in
                        weatherName(weather).tag(weather)
                    }
                } label: {
                    Text("Weather")
                }
                .pickerStyle(.menu)
            }
            Picker(selection: $state.season) {
                ForEach(MusicSeason.allCases, id: \.self) { season in
                    seasonName(season).tag(season)
                }
            } label: {
                Text("Season")
            }
            .pickerStyle(.segmented)
            Stepper(value: $state.stage, in: 1...10) {
                HStack {
                    Text("Island stage")
                    Spacer()
                    Text(verbatim: "\(state.stage)")
                        .monospacedDigit()
                        .foregroundStyle(PofuColor.textSecondary)
                }
                .font(PofuFont.subheadline)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Pofu's wellbeing")
                    Spacer()
                    Text(verbatim: "\(Int(state.wellbeing))")
                        .monospacedDigit()
                        .foregroundStyle(PofuColor.textSecondary)
                }
                .font(PofuFont.subheadline)
                Slider(value: $state.wellbeing, in: 0...100, step: 5) {
                    Text("Pofu's wellbeing")
                }
            }
        }
        .foregroundStyle(PofuColor.textPrimary)
    }

    private func row(_ title: LocalizedStringKey, @ViewBuilder control: () -> some View) -> some View {
        HStack {
            Text(title)
                .font(PofuFont.subheadline)
            Spacer()
            control()
        }
    }

    // MARK: - What the director answers

    @ViewBuilder private var answerCard: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.xs) {
            Text("The director plays")
                .font(PofuFont.caption)
                .foregroundStyle(PofuColor.textSecondary)
            switch answer {
            case .phrase(let phrase, let pause):
                Text(verbatim: "\(phrase.tune) · \(phrase.cell) · \(phrase.lead) · \(String(format: "%.1f", phrase.seconds)) s")
                    .font(PofuFont.subheadline)
                    .monospacedDigit()
                HStack(spacing: PofuSpacing.xs) {
                    ForEach(MusicStem.allCases, id: \.self) { stem in
                        stemChip(stem, isOn: phrase.stems.contains { $0.stem == stem })
                    }
                }
                Text("Then \(Int(pause.lowerBound.rounded())) to \(Int(pause.upperBound.rounded())) seconds of the island's own air")
                    .font(PofuFont.caption)
                    .foregroundStyle(PofuColor.textSecondary)
            case .silence(let reason):
                silenceText(reason)
                    .font(PofuFont.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(PofuColor.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stemChip(_ stem: MusicStem, isOn: Bool) -> some View {
        stemName(stem)
            .font(PofuFont.caption)
            .padding(.horizontal, PofuSpacing.s)
            .padding(.vertical, 4)
            .background(isOn ? PofuColor.textPrimary.opacity(0.14) : Color.clear, in: Capsule())
            .overlay(Capsule().strokeBorder(PofuColor.textSecondary.opacity(0.4), lineWidth: 1))
            .opacity(isOn ? 1 : 0.45)
            .accessibilityElement(children: .combine)
    }

    private var playButton: some View {
        Button {
            if isPlaying {
                isPlaying = false
                MusicPlayer.shared.audition(nil)
            } else {
                isMusicOn = SoundEngine.shared.settings.isMusicOn
                guard canPlay else { return }
                isPlaying = true
                MusicPlayer.shared.audition(state)
            }
        } label: {
            Label {
                if isPlaying { Text("Stop") } else { Text("Play") }
            } icon: {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
            }
            .font(PofuFont.headline)
            .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(PofuColor.textPrimary)
        .disabled(!canPlay && !isPlaying)
        .opacity(canPlay || isPlaying ? 1 : 0.4)
    }

    // MARK: - Stingers

    private var stingers: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.xs) {
            Text("Stingers")
                .font(PofuFont.subheadline)
            Text("They are written for the next music update. The buttons wake then.")
                .font(PofuFont.caption)
                .foregroundStyle(PofuColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(MusicRoom.Stinger.allCases, id: \.self) { stinger in
                Button {} label: {
                    Label {
                        stingerName(stinger)
                    } icon: {
                        Image(systemName: "play.circle")
                    }
                    .font(PofuFont.subheadline)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(true)
                .opacity(0.4)
            }
        }
        .foregroundStyle(PofuColor.textPrimary)
    }

    // MARK: - Names

    private func islandName(_ island: MusicIsland) -> Text {
        switch island {
        case .home: Text("Home")
        case .koke: Text(verbatim: "Köke")
        case .caglayan: Text(verbatim: "Çağlayan")
        case .revontuli: Text(verbatim: "Revontuli")
        case .emanet: Text(verbatim: "Emanet")
        case .mehtap: Text(verbatim: "Mehtap")
        }
    }

    private func weatherName(_ weather: AmbienceWeather) -> Text {
        switch weather {
        case .clear: Text("Clear")
        case .overcast: Text("Overcast")
        case .lightRain: Text("Light rain")
        case .mist: Text("Mist")
        case .goldenHaze: Text("Golden haze")
        }
    }

    private func seasonName(_ season: MusicSeason) -> Text {
        switch season {
        case .spring: Text("Spring")
        case .summer: Text("Summer")
        case .autumn: Text("Autumn")
        case .winter: Text("Winter")
        }
    }

    private func stemName(_ stem: MusicStem) -> Text {
        switch stem {
        case .lead: Text("Lead")
        case .bed: Text("Bed")
        case .pulse: Text("Pulse")
        }
    }

    private func stingerName(_ stinger: MusicRoom.Stinger) -> Text {
        switch stinger {
        case .stationBuilt: Text("A station built")
        case .islandGrows: Text("The island grows")
        }
    }

    private func silenceText(_ reason: MusicSilence) -> Text {
        switch reason {
        case .off: Text("Nothing: island music is off.")
        case .bedtime: Text("Nothing: bedtime. The islands are silent from 23:00 to 06:00.")
        case .noTune: Text("Nothing yet: no tune is written for this island at this hour.")
        }
    }
}
