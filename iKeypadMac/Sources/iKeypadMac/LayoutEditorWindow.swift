import AppKit
import SwiftUI
import iKeypadShared

/// The "Sidekey Layouts" window. Sidekey has no Dock icon, so showing it activates the app, as
/// ``PairingCodeWindow`` does.
@MainActor
final class LayoutEditorWindow {
    static let shared = LayoutEditorWindow()

    private var window: NSWindow?
    private lazy var model = LayoutEditorModel(monitor: .shared, store: .app)

    func show() {
        model.reload()
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: LayoutEditorView(model: model)))
            window.title = "Sidekey Layouts"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 1000, height: 600))
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

/// Role colours, matching the iPad's ``DeckTheme.tint(for:)`` in `iKeypad/Sources/iKeypad/DeckTheme.swift`.
/// Keep the two in step.
enum EditorTheme {
    static let cap = Color(red: 0.141, green: 0.153, blue: 0.180)   // #24272E
    static let plate = Color(red: 0.063, green: 0.071, blue: 0.090) // #101218

    static func tint(for role: KeyRole?) -> Color {
        switch role {
        case .navigate, .none: return Color(red: 0.796, green: 0.835, blue: 0.882) // #CBD5E1
        case .create: return Color(red: 0.478, green: 0.706, blue: 1.0)            // #7AB4FF
        case .run: return Color(red: 0.369, green: 0.890, blue: 0.557)             // #5EE38E
        case .danger: return Color(red: 1.0, green: 0.478, blue: 0.478)            // #FF7A7A
        case .modify: return Color(red: 0.788, green: 0.659, blue: 1.0)            // #C9A8FF
        }
    }
}

struct LayoutEditorView: View {
    @ObservedObject var model: LayoutEditorModel
    @State private var selectedSlot: Int?
    @State private var confirmingResetLayout = false
    @State private var fileToDelete: LayoutFileError?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                if !model.fileErrors.isEmpty {
                    fileErrorsSection
                    Divider()
                }
                List(model.entries, selection: $model.selectedLayoutId) { entry in
                    HStack {
                        Text(entry.title)
                        Spacer()
                        if entry.isCustomised {
                            Circle().fill(Color.accentColor).frame(width: 7, height: 7)
                                .accessibilityLabel("Customised")
                        }
                    }
                }
            }
            .frame(minWidth: 230)
        } detail: {
            if let id = model.selectedLayoutId, let layout = model.layout(id) {
                detail(id: id, layout: layout)
            } else {
                Text("Choose an app on the left.").foregroundStyle(.secondary)
            }
        }
        .onChange(of: model.selectedLayoutId) { _ in selectedSlot = nil }
        .alert("Sidekey couldn't make that change", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    /// Broken layout files, so a file the app refused to load is never invisible.
    private var fileErrorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Files with errors").font(.headline)
            ForEach(model.fileErrors, id: \.fileName) { error in
                VStack(alignment: .leading, spacing: 2) {
                    Text(error.fileName).font(.callout.weight(.medium))
                    Text(error.reason).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Delete File...") { fileToDelete = error }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .confirmationDialog("Delete \(fileToDelete?.fileName ?? "")?", isPresented: Binding(
            get: { fileToDelete != nil },
            set: { if !$0 { fileToDelete = nil } }
        ), presenting: fileToDelete) { error in
            Button("Delete File", role: .destructive) {
                model.resetLayout(String(error.fileName.dropLast(".json".count)))
            }
        } message: { error in
            Text("Delete \(error.fileName)? Your changes in it are lost; the app goes back to its built-in layout.")
        }
    }

    private func detail(id: String, layout: DeckProfile) -> some View {
        let changed = model.changedSlots(in: id)
        return HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(layout.appName).font(.title2.weight(.semibold))
                    Spacer()
                    if !changed.isEmpty || !model.isBuiltIn(id) {
                        Button("Reset Layout...") { confirmingResetLayout = true }
                    }
                }
                KeyGridView(model: model, layoutId: id, layout: layout, changed: changed, selection: $selectedSlot, columns: 5)
                Text("Dot: changed from the built-in layout. Drag a key to move it.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Portrait on the iPad").font(.caption.weight(.semibold)).padding(.top, 8)
                KeyGridView(model: model, layoutId: id, layout: layout, changed: changed, selection: $selectedSlot, columns: 3, compact: true)
            }
            if let slot = selectedSlot {
                KeyInspectorView(model: model, layoutId: id, slot: slot)
            }
        }
        .padding(24)
        .confirmationDialog("Reset \(layout.appName)?", isPresented: $confirmingResetLayout) {
            Button("Reset Layout", role: .destructive) { model.resetLayout(id) }
        } message: {
            Text(model.isBuiltIn(id)
                 ? "Every key goes back to Sidekey's built-in layout."
                 : "This removes the layout for this app.")
        }
    }
}

/// A layout's 15 slots. ``columns`` is 5 for landscape, or 3 for the portrait preview, which keeps
/// reading order the way the iPad does (`iKeypadApp.swift` `keyGrid`).
struct KeyGridView: View {
    @ObservedObject var model: LayoutEditorModel
    let layoutId: String
    let layout: DeckProfile
    let changed: Set<Int>
    @Binding var selection: Int?
    let columns: Int
    var compact = false

    var body: some View {
        let keys = Dictionary(layout.keys.map { ($0.position, $0) }, uniquingKeysWith: { first, _ in first })
        let rows = layout.rows * layout.columns / columns
        Grid(horizontalSpacing: compact ? 4 : 8, verticalSpacing: compact ? 4 : 8) {
            ForEach(0..<rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<columns, id: \.self) { column in
                        let slot = row * columns + column
                        SlotView(key: keys[slot], isChanged: changed.contains(slot), isSelected: selection == slot, compact: compact)
                            .onTapGesture { selection = slot }
                            .draggable(String(slot))
                            .dropDestination(for: String.self) { items, _ in
                                guard let from = items.first.flatMap(Int.init) else { return false }
                                model.moveKey(from: from, to: slot, in: layoutId)
                                selection = slot
                                return true
                            }
                    }
                }
            }
        }
        .padding(compact ? 6 : 12)
        .background(EditorTheme.plate, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SlotView: View {
    let key: DeckKey?
    let isChanged: Bool
    let isSelected: Bool
    let compact: Bool

    var body: some View {
        let size = compact ? CGSize(width: 46, height: 40) : CGSize(width: 104, height: 84)
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                if let key {
                    if let icon = key.iconSystemName {
                        Image(systemName: icon).font(compact ? .caption : .title2).foregroundStyle(EditorTheme.tint(for: key.role))
                    }
                    if !compact {
                        Text(key.label).font(.caption).lineLimit(1).foregroundStyle(.white)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .background(key == nil ? EditorTheme.plate : EditorTheme.cap, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isSelected ? Color.accentColor : .white.opacity(0.08),
                                                                     lineWidth: isSelected ? 2 : 1))
            if isChanged {
                Circle().fill(Color.accentColor).frame(width: 7, height: 7).padding(5)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(key.map { "\($0.label)\(isChanged ? ", changed" : "")" } ?? "Empty slot")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
