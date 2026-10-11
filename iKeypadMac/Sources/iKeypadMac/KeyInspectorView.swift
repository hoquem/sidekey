import SwiftUI
import iKeypadShared

/// Edits the key in one slot. Every valid change saves at once; a label outside 1 to 16
/// characters is shown as a problem and not saved until fixed.
struct KeyInspectorView: View {
    @ObservedObject var model: LayoutEditorModel
    let layoutId: String
    let slot: Int

    @State private var draft = LayoutEditorModel.newKey
    @State private var confirmingReset = false
    @State private var choosingIcon = false
    @State private var shortcutNames: [String] = []
    @State private var loadingShortcuts = false
    @StateObject private var recorder = ShortcutRecorder()

    private enum Kind: String, CaseIterable, Identifiable {
        case keyboard = "Keyboard Shortcut", windows = "Windows Shortcut", shortcut = "Apple Shortcut", mode = "Switch Layout"
        var id: Self { self }
    }

    private var key: DeckKey? { model.layout(layoutId)?.keys.first { $0.position == slot } }
    private var isChanged: Bool { model.changedSlots(in: layoutId).contains(slot) }
    private var labelProblem: String? {
        let label = draft.label.trimmingCharacters(in: .whitespaces)
        if label.isEmpty { return "Enter a label." }
        if draft.label.count > LayoutValidator.maxLabelLength { return "At most \(LayoutValidator.maxLabelLength) characters." }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key \(slot + 1)").font(.headline)
            if let key, !model.isEditable(key) {
                Text("\"\(key.label)\" is a built-in key that runs a script. Custom keys can't run scripts, so it can only be replaced or removed.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("Replace with a New Key") { model.setKey(LayoutEditorModel.newKey, at: slot, in: layoutId) }
                Button("Remove Key", role: .destructive) { model.removeKey(at: slot, in: layoutId) }
            } else if key == nil {
                Text("Empty slot").foregroundStyle(.secondary)
                Button("Add Key") { model.setKey(LayoutEditorModel.newKey, at: slot, in: layoutId) }
                if isChanged { resetButton }
            } else {
                form
            }
        }
        .frame(width: 300, alignment: .topLeading)
        .onAppear(perform: loadDraft)
        .onChange(of: slot) { _ in loadDraft() }
        .onChange(of: layoutId) { _ in loadDraft() }
        // Add Key, Replace, Reset and drag-moves change the saved key without changing the slot. Our own
        // saves leave the saved key equal to the draft, so this does not disturb typing.
        .onChange(of: key.map { CustomKey($0) }) { _ in loadDraft() }
        .onChange(of: draft) { new in
            guard labelProblem == nil, let key, new != CustomKey(key) else { return }
            model.setKey(new, at: slot, in: layoutId)
        }
        .onDisappear { recorder.stop() }
        .confirmationDialog("Reset this key?", isPresented: $confirmingReset) {
            Button("Reset Key", role: .destructive) { model.resetKey(at: slot, in: layoutId) }
        } message: {
            Text(model.isBuiltIn(layoutId) ? "It goes back to the built-in key." : "The slot becomes empty.")
        }
    }

    private var form: some View {
        Form {
            TextField("Label", text: $draft.label)
            if let labelProblem {
                Label(labelProblem, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.red)
            }

            HStack {
                Text("Icon")
                Spacer()
                Button {
                    choosingIcon = true
                } label: {
                    Image(systemName: draft.iconSystemName ?? "square.dashed")
                }
                .accessibilityLabel("Icon: \(draft.iconSystemName ?? "none")")
                .popover(isPresented: $choosingIcon) { IconPicker(selection: $draft.iconSystemName) }
            }

            Picker("Colour", selection: $draft.role) {
                Text("Navigate").tag(KeyRole?.some(.navigate))
                Text("Create").tag(KeyRole?.some(.create))
                Text("Run").tag(KeyRole?.some(.run))
                Text("Modify").tag(KeyRole?.some(.modify))
                Text("Danger").tag(KeyRole?.some(.danger))
            }

            Picker("Action", selection: kind) {
                ForEach(availableKinds) { Text($0.rawValue).tag($0) }
            }
            actionEditor

            Toggle("Hold to fire", isOn: $draft.requiresConfirm)
            if key?.toggleChipId != nil && !isChanged {
                Text("Editing this key stops it lighting with the app's state.").font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                Button("Remove Key", role: .destructive) { model.removeKey(at: slot, in: layoutId) }
                if isChanged { resetButton }
            }
        }
    }

    private var resetButton: some View {
        Button("Reset Key...") { confirmingReset = true }
    }

    private var availableKinds: [Kind] {
        model.modes(of: layoutId).count > 1 ? Kind.allCases : [.keyboard, .windows, .shortcut]
    }

    private var kind: Binding<Kind> {
        Binding(
            get: {
                switch draft.action {
                case .windowsHotkey: return .windows
                case .runShortcut: return .shortcut
                case .switchProfile: return .mode
                default: return .keyboard
                }
            },
            set: { new in
                if new != .keyboard { recorder.stop() }
                switch new {
                case .keyboard: draft.action = .hotkey(key: "a", modifiers: [.command])
                case .windows: draft.action = .windowsHotkey(key: "a", modifiers: [.ctrl])
                case .shortcut:
                    loadShortcutNames(selectFirst: true)
                case .mode:
                    if let first = model.modes(of: layoutId).first { draft.action = .switchProfile(profileId: first.id) }
                }
            }
        )
    }

    @ViewBuilder private var actionEditor: some View {
        switch draft.action {
        case .hotkey(let name, let modifiers):
            HStack {
                ForEach([(KeyModifier.control, "⌃", "Control"), (.option, "⌥", "Option"), (.shift, "⇧", "Shift"), (.command, "⌘", "Command")], id: \.1) { mod, symbol, modifierName in
                    Toggle(symbol, isOn: Binding(
                        get: { modifiers.contains(mod) },
                        set: { on in draft.action = .hotkey(key: name, modifiers: on ? modifiers + [mod] : modifiers.filter { $0 != mod }) }
                    ))
                    .toggleStyle(.button)
                    .accessibilityLabel(modifierName)
                }
                Picker("Key", selection: Binding(get: { name }, set: { draft.action = .hotkey(key: $0, modifiers: modifiers) })) {
                    ForEach(KeyNames.mac, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
            }
            Button(recorder.isRecording ? "Press a shortcut... (click to cancel)" : "Record Shortcut") {
                if recorder.isRecording { recorder.stop() } else {
                    recorder.start { key, mods in draft.action = .hotkey(key: key, modifiers: mods) }
                }
            }
            if let warning = SystemShortcuts.conflict(key: name, modifiers: modifiers) {
                Label(warning, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange)
            }
        case .windowsHotkey(let name, let modifiers):
            HStack {
                ForEach([WindowsModifier.ctrl, .alt, .shift, .win], id: \.self) { mod in
                    Toggle(mod.rawValue.capitalized, isOn: Binding(
                        get: { modifiers.contains(mod) },
                        set: { on in draft.action = .windowsHotkey(key: name, modifiers: on ? modifiers + [mod] : modifiers.filter { $0 != mod }) }
                    ))
                    .toggleStyle(.button)
                }
                Picker("Key", selection: Binding(get: { name }, set: { draft.action = .windowsHotkey(key: $0, modifiers: modifiers) })) {
                    ForEach(KeyNames.windows, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
            }
        case .runShortcut(let name):
            Picker("Shortcut", selection: Binding(get: { name }, set: { draft.action = .runShortcut(name: $0) })) {
                ForEach(shortcutNames.contains(name) ? shortcutNames : [name] + shortcutNames, id: \.self) { Text($0).tag($0) }
            }
            .onAppear { loadShortcutNames(selectFirst: false) }
        case .switchProfile(let id):
            Picker("Layout", selection: Binding(get: { id }, set: { draft.action = .switchProfile(profileId: $0) })) {
                ForEach(model.modes(of: layoutId)) { Text($0.title).tag($0.id) }
            }
        case .shellScript, .appleScript, .none:
            EmptyView()
        }
        if loadingShortcuts { Text("Loading shortcuts...").font(.caption).foregroundStyle(.secondary) }
    }

    private func loadDraft() {
        recorder.stop()
        if let key, model.isEditable(key) { draft = CustomKey(key) }
    }

    /// Lists the Apple Shortcuts off the main thread, since `shortcuts list` blocks until it exits.
    ///
    /// :param selectFirst: When true, the key's action becomes the first shortcut once listed. If
    ///     there are none, or listing failed, the editor's error alert says so instead.
    private func loadShortcutNames(selectFirst: Bool) {
        guard !loadingShortcuts else { return }
        let (requestedLayout, requestedSlot) = (layoutId, slot)
        loadingShortcuts = true
        Task { @MainActor in
            defer { loadingShortcuts = false }
            do {
                let names = try await Task.detached { try AppleShortcuts.names() }.value
                shortcutNames = names
                // The user may have selected another key while the list loaded.
                guard selectFirst, requestedLayout == layoutId, requestedSlot == slot else { return }
                if let first = names.first {
                    draft.action = .runShortcut(name: first)
                } else {
                    model.errorMessage = "You have no Apple Shortcuts yet. Make one in the Shortcuts app first."
                }
            } catch {
                model.errorMessage = error.localizedDescription
            }
        }
    }
}

/// A searchable grid of ``SymbolCatalog`` symbols.
private struct IconPicker: View {
    @Binding var selection: String?
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            TextField("Search icons", text: $query).textFieldStyle(.roundedBorder)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 8), spacing: 8) {
                    ForEach(SymbolCatalog.matching(query), id: \.self) { name in
                        Button {
                            selection = name
                            dismiss()
                        } label: {
                            Image(systemName: name).frame(width: 32, height: 32)
                        }
                        .buttonStyle(.borderless)
                        .help(name)
                        .accessibilityLabel(name)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 340, height: 360)
    }
}
