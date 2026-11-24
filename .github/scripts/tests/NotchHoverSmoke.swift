@main
enum NotchHoverSmoke {
    static func main() {
        expect(.openHome, leftSide: true, playing: true)
        expect(.openCurrentTab, leftSide: false, playing: true)
        expect(.openCurrentTab, leftSide: true, playing: false)
        expect(.openCurrentTab, leftSide: false, playing: false)

        expect(.openHome, leftSide: true, playing: true, preview: .music)
        expect(nil, leftSide: false, playing: true, preview: .music)
        expect(nil, leftSide: true, playing: false, preview: .music)
        expect(nil, leftSide: false, playing: false, preview: .music)

        expect(nil, leftSide: true, playing: true, preview: .system)
        expect(nil, leftSide: false, playing: true, preview: .system)
        expect(nil, leftSide: true, playing: false, preview: .system)
        expect(nil, leftSide: false, playing: false, preview: .system)

        print("Left-side music hover routes playback and preview states correctly.")
    }

    private static func expect(
        _ expected: NotchHoverAction?,
        leftSide: Bool,
        playing: Bool,
        preview: NotchHoverAction.Preview? = nil,
        line: UInt = #line
    ) {
        let actual = NotchHoverAction.resolve(
            isHoveringLeftSide: leftSide,
            isPlaying: playing,
            preview: preview
        )
        precondition(actual == expected, "Expected \(String(describing: expected)), got \(String(describing: actual))", line: line)
    }
}
