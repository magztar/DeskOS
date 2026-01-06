//
//  ContentView.swift
//  DeskOS
//
//  Created by Magnus Larsson on 2026-01-06.
//

import SwiftUI
import Combine
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Simple representation of an app/module in DeskOS.
struct DeskModule: Identifiable, Hashable {
    let id: String
    let name: String
    let systemImage: String
    let tint: Color
}

enum SnapPosition {
    case none
    case left
    case right
    case maximized
}

// Window state for a running module.
struct WindowState: Identifiable {
    let id: UUID
    let module: DeskModule
    var offset: CGSize
    var size: CGSize
    var zIndex: Double
    var isFocused: Bool
    var snap: SnapPosition
}

final class DesktopStore: ObservableObject {
    @Published var windows: [WindowState] = []
    @Published var isLauncherOpen = false

    let modules: [DeskModule] = [
        DeskModule(id: "notes", name: "Notes", systemImage: "note.text", tint: .yellow),
        DeskModule(id: "browser", name: "Browser", systemImage: "globe", tint: .blue),
        DeskModule(id: "files", name: "Files", systemImage: "folder", tint: .cyan),
        DeskModule(id: "chat", name: "Chat", systemImage: "bubble.left.and.bubble.right", tint: .green)
    ]

    private var nextZ: Double = 1
    private let defaultSize = CGSize(width: 420, height: 320)
    private let dockHeight: CGFloat = 80

    func bootIfNeeded(canvas: CGSize) {
        guard windows.isEmpty else { return }
        open(modules[0], in: canvas, offset: CGSize(width: 32, height: 48))
        open(modules[1], in: canvas, offset: CGSize(width: 96, height: 96))
    }

    func open(_ module: DeskModule, in canvas: CGSize, offset: CGSize? = nil) {
        let startOffset: CGSize
        if let offset {
            startOffset = offset
        } else {
            startOffset = centeredOffset(for: defaultSize, in: canvas)
        }

        let window = WindowState(
            id: UUID(),
            module: module,
            offset: startOffset,
            size: defaultSize,
            zIndex: nextZ,
            isFocused: true,
            snap: .none
        )
        nextZ += 1
        focus(window.id)
        windows.append(window)
    }

    func close(_ id: UUID) {
        windows.removeAll { $0.id == id }
    }

    func focus(_ id: UUID) {
        for index in windows.indices {
            windows[index].isFocused = windows[index].id == id
        }
        if let idx = windows.firstIndex(where: { $0.id == id }) {
            windows[idx].zIndex = nextZ
            nextZ += 1
        }
    }

    func updateOffset(_ id: UUID, to offset: CGSize) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[idx].offset = offset
        windows[idx].snap = .none
    }

    func endDrag(_ id: UUID, in canvas: CGSize) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        let window = windows[idx]
        let edgeThreshold = canvas.width * 0.2
        let rightEdge = window.offset.width + window.size.width

        windows[idx].offset = clampedOffset(for: window.size, proposed: window.offset, in: canvas)

        if window.offset.width < edgeThreshold {
            snap(id, to: .left, in: canvas)
        } else if rightEdge > canvas.width - edgeThreshold {
            snap(id, to: .right, in: canvas)
        }
    }

    func snap(_ id: UUID, to position: SnapPosition, in canvas: CGSize) {
        guard let idx = windows.firstIndex(where: { $0.id == id }) else { return }
        let verticalPadding: CGFloat = 4
        let usableHeight = max(200, canvas.height - dockHeight - verticalPadding * 2)
        switch position {
        case .left:
            windows[idx].offset = CGSize(width: 4, height: verticalPadding)
            windows[idx].size = CGSize(width: canvas.width * 0.48, height: usableHeight)
            windows[idx].snap = .left
        case .right:
            windows[idx].offset = CGSize(width: canvas.width * 0.52, height: verticalPadding)
            windows[idx].size = CGSize(width: canvas.width * 0.48 - 4, height: usableHeight)
            windows[idx].snap = .right
        case .maximized:
            windows[idx].offset = CGSize(width: 0, height: 0)
            windows[idx].size = CGSize(width: canvas.width, height: canvas.height - dockHeight - verticalPadding)
            windows[idx].snap = .maximized
        case .none:
            windows[idx].size = defaultSize
            windows[idx].snap = .none
        }
        windows[idx].offset = clampedOffset(for: windows[idx].size, proposed: windows[idx].offset, in: canvas)
        focus(id)
    }

    private func centeredOffset(for size: CGSize, in canvas: CGSize) -> CGSize {
        let x = max(0, (canvas.width - size.width) * 0.5)
        let y = max(-12, (canvas.height - size.height - dockHeight) * 0.35)
        return CGSize(width: x, height: y)
    }

    private func clampedOffset(for size: CGSize, proposed: CGSize, in canvas: CGSize) -> CGSize {
        // Allow more freedom so fönster kan flyttas över hela ytan, men se till att en liten del alltid är synlig.
        let minX = -size.width * 0.6
        let maxX = canvas.width - 60
        let minY = -size.height * 0.6
        let maxY = canvas.height - dockHeight - 40

        let clampedX = clamp(proposed.width, min: minX, max: maxX)
        let clampedY = clamp(proposed.height, min: minY, max: maxY)
        return CGSize(width: clampedX, height: clampedY)
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, min), max)
    }
}

struct ContentView: View {
    @StateObject private var store = DesktopStore()
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                desktopBackground

                ZStack(alignment: .topLeading) {
                    ForEach(store.windows.sorted(by: { $0.zIndex < $1.zIndex })) { window in
                        if let binding = binding(for: window.id) {
                            DesktopWindow(
                                window: binding,
                                canvasSize: geo.size,
                                onClose: { store.close(window.id) },
                                onFocus: { store.focus(window.id) },
                                onDragEnd: { dragOffset in
                                    withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.86, blendDuration: 0.06)) {
                                        store.updateOffset(window.id, to: CGSize(width: window.offset.width + dragOffset.width, height: window.offset.height + dragOffset.height))
                                        store.endDrag(window.id, in: geo.size)
                                    }
                                },
                                onSnap: { position in
                                    withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.86, blendDuration: 0.06)) {
                                        store.snap(window.id, to: position, in: geo.size)
                                    }
                                }
                            )
                            .zIndex(window.zIndex)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                .clipped()
                .onAppear {
                    canvasSize = geo.size
                    store.bootIfNeeded(canvas: geo.size)
                }
                .onChange(of: geo.size) { _, newSize in
                    canvasSize = newSize
                }

                DockView(modules: store.modules) {
                    store.open($0, in: canvasSize)
                } launcherTapped: {
                    withAnimation(.easeInOut) {
                        store.isLauncherOpen.toggle()
                    }
                }

                if store.isLauncherOpen {
                    LauncherOverlay(modules: store.modules) { module in
                        store.open(module, in: canvasSize)
                        withAnimation(.easeInOut) {
                            store.isLauncherOpen = false
                        }
                    } onDismiss: {
                        withAnimation(.easeInOut) {
                            store.isLauncherOpen = false
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
    }

    private func binding(for id: UUID) -> Binding<WindowState>? {
        guard let index = store.windows.firstIndex(where: { $0.id == id }) else { return nil }
        return $store.windows[index]
    }

    private var desktopBackground: some View {
        LinearGradient(
            colors: [.black.opacity(0.9), Color.blue.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(colors: [Color.white.opacity(0.12), .clear], center: .center, startRadius: 80, endRadius: 420)
        )
    }
}

struct DesktopWindow: View {
    @Binding var window: WindowState
    let canvasSize: CGSize
    let onClose: () -> Void
    let onFocus: () -> Void
    let onDragEnd: (CGSize) -> Void
    let onSnap: (SnapPosition) -> Void

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(window.module.name, systemImage: window.module.systemImage)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                HStack(spacing: 8) {
                    Button(action: { onSnap(.left) }) {
                        Image(systemName: "rectangle.leadinghalf.inset.filled")
                    }
                    Button(action: { onSnap(.right) }) {
                        Image(systemName: "rectangle.trailinghalf.inset.filled")
                    }
                    Button(action: { onSnap(window.snap == .maximized ? .none : .maximized) }) {
                        Image(systemName: window.snap == .maximized ? "rectangle.compress.vertical" : "arrow.up.left.and.arrow.down.right")
                    }
                    Button(role: .destructive, action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                .buttonStyle(.plain)
                .symbolVariant(.fill)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider().offset(y: 18)
            }
            .gesture(dragGesture)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(surfaceColor.opacity(0.9))
        }
        .frame(width: window.size.width, height: window.size.height)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(window.isFocused ? 0.35 : 0.15), radius: window.isFocused ? 18 : 8, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(window.isFocused ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.08), lineWidth: window.isFocused ? 2 : 1)
        )
        .offset(x: window.offset.width + dragOffset.width, y: window.offset.height + dragOffset.height)
        .onTapGesture(perform: onFocus)
    }

    @ViewBuilder
    private var content: some View {
        switch window.module.id {
        case "notes":
            AnyView(notesApp)
        case "browser":
            AnyView(browserApp)
        case "files":
            AnyView(filesApp)
        case "chat":
            AnyView(chatApp)
        default:
            AnyView(
                Text("App coming soon")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(secondarySurfaceColor)
            )
        }
    }

    private var notesApp: some View {
        VStack(alignment: .leading) {
            Text("Notes")
                .font(.title3.weight(.semibold))
            Text("Write quick notes or todos. This is a static placeholder for now.")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    private var browserApp: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe")
                Text("Browser")
                    .font(.headline)
                Spacer()
                Capsule()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 80, height: 26)
                    .overlay(Text("Offline").font(.caption).foregroundStyle(.blue))
            }
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.08))
                .frame(maxWidth: .infinity)
                .overlay(
                    Text("Web view placeholder")
                        .foregroundStyle(.secondary)
                )
            Spacer()
        }
        .padding()
    }

    private var filesApp: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Files")
                .font(.headline)
            ForEach(0..<5) { index in
                HStack {
                    Image(systemName: "doc")
                    Text("Document_0\(index).txt")
                    Spacer()
                    Text("12 KB")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Divider()
            }
            Spacer()
        }
        .padding()
    }

    private var chatApp: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chat")
                .font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    chatBubble(text: "Hej! Detta är en mockad konversation.", isMe: false)
                    chatBubble(text: "Ser ut som ett DeskOS-fönster!", isMe: true)
                    chatBubble(text: "Vi kan ersätta detta med riktig data senare.", isMe: false)
                }
            }
            Spacer()
        }
        .padding()
    }

    private func chatBubble(text: String, isMe: Bool) -> some View {
        HStack {
            if isMe { Spacer() }
            Text(text)
                .padding(10)
                .background(isMe ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if !isMe { Spacer() }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                onFocus()
                dragOffset = value.translation
            }
            .onEnded { _ in
                onDragEnd(dragOffset)
                dragOffset = .zero
            }
    }

    private var surfaceColor: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    private var secondarySurfaceColor: Color {
        #if os(macOS)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }
}

struct DockView: View {
    let modules: [DeskModule]
    let onOpen: (DeskModule) -> Void
    let launcherTapped: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: launcherTapped) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                ForEach(modules) { module in
                    Button(action: { onOpen(module) }) {
                        VStack(spacing: 6) {
                            Image(systemName: module.systemImage)
                                .font(.title3)
                                .foregroundStyle(module.tint)
                            Text(module.name)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        }
        .padding(.bottom, 12)
    }
}

struct LauncherOverlay: View {
    let modules: [DeskModule]
    let onLaunch: (DeskModule) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Launcher")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                    ForEach(modules) { module in
                        Button(action: { onLaunch(module) }) {
                            HStack(spacing: 12) {
                                Image(systemName: module.systemImage)
                                    .foregroundStyle(module.tint)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(module.name)
                                        .font(.headline)
                                    Text("Open in new window")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 640)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.35), radius: 28, y: 18)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

#Preview {
    ContentView()
}
