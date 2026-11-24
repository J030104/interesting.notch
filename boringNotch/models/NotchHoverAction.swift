enum NotchHoverAction: Equatable {
    case openCurrentTab
    case openHome

    enum Preview {
        case music
        case system
    }

    static func resolve(
        isHoveringLeftSide: Bool,
        isPlaying: Bool,
        preview: Preview?
    ) -> Self? {
        let opensHome = isHoveringLeftSide && isPlaying
        if let preview, preview != .music || !opensHome {
            return nil
        }
        return opensHome ? .openHome : .openCurrentTab
    }
}
