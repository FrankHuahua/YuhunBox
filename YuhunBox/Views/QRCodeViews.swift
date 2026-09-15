import SwiftUI
import VisionKit

struct PresetQRView: View {
    @Environment(\.dismiss) private var dismiss
    let team: TeamPreset

    private var code: String { (try? PresetCodeCodec.encode(team)) ?? "" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                AppMark(size: 52)
                Text(team.title).font(.title3.weight(.bold))
                if let image = PresetCodeCodec.qrImage(for: code) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300)
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                } else {
                    EmptyState(symbol: "exclamationmark.triangle", title: "二维码生成失败", detail: "预设内容可能过长，请精简备注后重试。")
                }
                Text("使用御魂匣的“扫码导入”恢复完整队伍")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                ShareLink(item: code) {
                    Label("分享预设码", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Spacer()
            }
            .padding(20)
            .background(AppTheme.page)
            .navigationTitle("分享预设")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
}

struct TeamImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var showScanner = false
    @State private var errorMessage: String?
    let onImport: (TeamPreset) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { showScanner = true } label: {
                        Label("打开相机扫码", systemImage: "qrcode.viewfinder")
                    }
                } footer: {
                    Text("可扫描御魂匣预设二维码；识别到其他文本时会作为官方阵容码保存。")
                }

                Section("或粘贴阵容码") {
                    TextEditor(text: $code)
                        .font(.caption.monospaced())
                        .frame(minHeight: 140)
                    Button("导入") { importCode(code) }
                        .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("导入队伍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .sheet(isPresented: $showScanner) {
                QRScannerScreen { value in
                    showScanner = false
                    code = value
                    importCode(value)
                }
            }
            .alert("无法导入", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("知道了", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "未知错误") }
        }
    }

    private func importCode(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if trimmed.hasPrefix("YHX1:") {
            do {
                onImport(try PresetCodeCodec.decode(trimmed))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            let team = TeamPreset(title: "扫码导入的官方阵容", scene: "待整理", members: [], officialCode: trimmed, notes: "请在编辑页补充式神与御魂方案。")
            onImport(team)
            dismiss()
        }
    }
}

private struct QRScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    let onScan: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerView(onScan: onScan)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(alignment: .center) {
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, dash: [10, 7]))
                                .frame(width: 250, height: 250)
                                .shadow(color: .black.opacity(0.4), radius: 4)
                        }
                } else {
                    EmptyState(symbol: "camera.fill", title: "此设备不支持相机扫描", detail: "请返回后把预设码粘贴到文本框中。")
                        .padding()
                }
            }
            .background(.black)
            .navigationTitle("扫描二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
    }
}

private struct DataScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !hasScanned else { return }
            for item in addedItems {
                guard case .barcode(let barcode) = item, let value = barcode.payloadStringValue else { continue }
                hasScanned = true
                onScan(value)
                return
            }
        }
    }
}

