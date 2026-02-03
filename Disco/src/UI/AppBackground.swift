import SwiftUI

struct AppBackground: View {
    @State private var startDate = Date()
    private let pixelsPerSecond: CGFloat = 50
    
    var body: some View {
        GeometryReader { proxy in
            let tileHeight = proxy.size.height
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0x11/255, green: 0x30/255, blue: 0x52/255), location: 0.30),
                        .init(color: Color(red: 0x02/255, green: 0x0E/255, blue: 0x19/255), location: 1)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea()

                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate
                    let distance = CGFloat(t) * (pixelsPerSecond / 8)
                    let w = tileHeight
                    let base = -distance.truncatingRemainder(dividingBy: w)

                    ZStack(alignment: .leading) {
                        Image("2.2")
                            .resizable()
                            .scaledToFill()
                            .frame(height: tileHeight)
                            .offset(x: base)

                        Image("2.2")
                            .resizable()
                            .scaledToFill()
                            .frame(height: tileHeight)
                            .offset(x: base + w)

                        Image("2.2")
                            .resizable()
                            .scaledToFill()
                            .frame(height: tileHeight)
                            .offset(x: base + 2 * w)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .allowsHitTesting(false)

                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate
                    let distance = CGFloat(t) * (pixelsPerSecond / 1.5)
                    let w = tileHeight
                    let base = -distance.truncatingRemainder(dividingBy: w)

                    ZStack(alignment: .leading) {
                        Image("3.3")
                            .resizable()
                            .scaledToFill()
                            .frame(height: tileHeight)
                            .offset(x: base)

                        Image("3.3")
                            .resizable()
                            .scaledToFill()
                            .frame(height: tileHeight)
                            .offset(x: base + w)

                        Image("3.3")
                            .resizable()
                            .scaledToFill()
                            .frame(height: tileHeight)
                            .offset(x: base + 2 * w)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .onAppear { startDate = Date() }
                .allowsHitTesting(false)

                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate
                    let distance = CGFloat(t) * (pixelsPerSecond)
                    let w = tileHeight
                    let base = -distance.truncatingRemainder(dividingBy: w)

                    ZStack(alignment: .leading) {
                        Image("4.4")
                            .resizable()
                            .scaledToFill()
                            .frame(height: tileHeight)
                            .offset(x: base)

                        Image("4.4")
                            .resizable()
                            .scaledToFill()
                            .frame(height: tileHeight)
                            .offset(x: base + w)

                        Image("4.4")
                            .resizable()
                            .scaledToFill()
                            .frame(height: tileHeight)
                            .offset(x: base + 2 * w)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .allowsHitTesting(false)
            }
            .compositingGroup()
        }
        .ignoresSafeArea()
    }
}

#Preview("AppBackground – Light") {
    AppBackground()
        .environment(\.colorScheme, .light)
}

#Preview("AppBackground – Dark") {
    AppBackground()
        .environment(\.colorScheme, .dark)
}

