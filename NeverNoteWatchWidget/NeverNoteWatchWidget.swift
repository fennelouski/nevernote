//
//  NeverNoteWatchWidget.swift
//  Nevernote
//

import SwiftUI
import WidgetKit

struct NevernoteComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> NevernoteComplicationEntry {
        NevernoteComplicationEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (NevernoteComplicationEntry) -> Void) {
        completion(NevernoteComplicationEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NevernoteComplicationEntry>) -> Void) {
        let entry = NevernoteComplicationEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct NevernoteComplicationEntry: TimelineEntry {
    let date: Date
}

struct NevernoteComplicationView: View {
    var entry: NevernoteComplicationProvider.Entry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "note.text")
                .font(.title.weight(.semibold))
        }
    }
}

struct NevernoteComplication: Widget {
    let kind: String = "com.nathanfennel.NeverNote.watchkitapp.complication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NevernoteComplicationProvider()) { entry in
            NevernoteComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(LocalizedStringResource("Nevernote"))
        .description(LocalizedStringResource("Open Nevernote to read or capture a note."))
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular,
        ])
    }
}

@main
struct NevernoteWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        NevernoteComplication()
    }
}
