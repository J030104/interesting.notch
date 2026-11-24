@main
enum NotchHoverSmoke {
    static func main() {
        expect(.openHome, thumbnail: true, playing: true)
        expect(.openCurrentTab, thumbnail: false, playing: true)
        expect(.openCurrentTab, thumbnail: true, playing: false)
        expect(.openCurrentTab, thumbnail: false, playing: false)

        expect(.openHome, thumbnail: true, playing: true, preview: .music)
        expect(nil, thumbnail: false, playing: true, preview: .music)
        expect(nil, thumbnail: true, playing: false, preview: .music)
        expect(nil, thumbnail: false, playing: false, preview: .music)

        expect(nil, thumbnail: true, playing: true, preview: .system)
        expect(nil, thumbnail: false, playing: true, preview: .system)
        expect(nil, thumbnail: true, playing: false, preview: .system)
        expect(nil, thumbnail: false, playing: false, preview: .system)

        print("Music thumbnail hover routes playback and preview states correctly.")
    }

    private static func expect(
        _ expected: NotchHoverAction?,
        thumbnail: Bool,
        playing: Bool,
        preview: NotchHoverAction.Preview? = nil,
        line: UInt = #line
    ) {
        let actual = NotchHoverAction.resolve(
            isHoveringThumbnail: thumbnail,
            isPlaying: playing,
            preview: preview
        )
        precondition(actual == expected, "Expected \(String(describing: expected)), got \(String(describing: actual))", line: line)
    }
}
