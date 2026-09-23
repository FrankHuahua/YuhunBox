import PhotosUI
import SwiftUI
import Vision
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
                } else {
                    EmptyState(symbol: "exclamationmark.triangle", title: "二维码生成失败", detail: "预设内容可能过长，请精简备注后重试。")
                }
                Text("YHX2 二维码包含式神、御魂方案和属性要求")
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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isReadingPhoto = false
    @State private var candidate: TeamImportCandidate?
    @State private var errorMessage: String?
    let onImport: (TeamPreset) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { showScanner = true } label: {
                        Label("打开相机扫码", systemImage: "qrcode.viewfinder")
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(isReadingPhoto ? "正在识别…" : "从相册选择阵容码", systemImage: "photo.on.rectangle")
                    }
                    .disabled(isReadingPhoto)
                } header: {
                    Text("选择来源")
                } footer: {
                    Text("相机与相册使用同一解析流程，识别后先展示队伍详情，确认后才保存。")
                }

                Section("或粘贴阵容码") {
                    TextEditor(text: $code)
                        .font(.caption.monospaced())
                        .frame(minHeight: 110)
                    Button("解析阵容码") { prepareImport(code) }
                        .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let candidate {
                    importPreview(candidate)
                }
            }
            .navigationTitle("导入队伍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .sheet(isPresented: $showScanner) {
                QRScannerScreen { value in
                    showScanner = false
                    code = value
                    prepareImport(value)
                }
            }
            .onChange(of: selectedPhoto) { item in
                guard let item else { return }
                readPhoto(item)
            }
            .alert("无法导入", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("知道了", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "未知错误") }
        }
    }

    @ViewBuilder private func importPreview(_ candidate: TeamImportCandidate) -> some View {
        Section {
            if candidate.isDetailed {
                Label("已解析完整预设", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 5) {
                    Text(candidate.team.title).font(.headline)
                    Text("\(candidate.team.scene.isEmpty ? "未分类" : candidate.team.scene) · \(candidate.team.members.count) 名式神")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(candidate.team.members.enumerated()), id: \.element.id) { index, member in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(index + 1). \(member.name.isEmpty ? "未命名式神" : member.name)")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            if let speed = member.speedTarget {
                                Text("速 \(speed)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            }
                        }
                        Text(member.soulPlan.isEmpty ? member.goal.title : member.soulPlan)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let requirements = member.requirements, !requirements.summary.isEmpty {
                            Text(requirements.summary.joined(separator: " · "))
                                .font(.caption2)
                                .foregroundStyle(Color.saffron)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 3)
                }

                Button {
                    onImport(candidate.team)
                    dismiss()
                } label: {
                    Label("导入完整预设", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Label("识别到官方原始阵容码", systemImage: "exclamationmark.shield.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                Text("官方阵容码是由游戏客户端计算的封闭格式，公开资料中没有可离线还原式神、御魂与属性要求的协议。御魂匣不会虚构配置；你可以保存原码草稿，再手动补全详情。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(candidate.rawCode)
                    .font(.caption2.monospaced())
                    .lineLimit(3)
                    .textSelection(.enabled)
                Button {
                    onImport(candidate.team)
                    dismiss()
                } label: {
                    Label("保存原始码草稿", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        } header: {
            Text("识别预览")
        }
    }

    private func prepareImport(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if PresetCodeCodec.canDecode(trimmed) {
            do {
                candidate = TeamImportCandidate(team: try PresetCodeCodec.decode(trimmed), rawCode: trimmed, isDetailed: true)
            } catch {
                candidate = nil
                errorMessage = error.localizedDescription
            }
        } else {
            let draft = TeamPreset(
                title: "官方阵容码草稿",
                scene: "待补全",
                members: [],
                officialCode: trimmed,
                notes: "官方阵容码格式未公开，已保留原始码；请按游戏内计算结果补充式神、御魂与属性要求。"
            )
            candidate = TeamImportCandidate(team: draft, rawCode: trimmed, isDetailed: false)
        }
    }

    private func readPhoto(_ item: PhotosPickerItem) {
        isReadingPhoto = true
        Task {
            defer { isReadingPhoto = false }
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw QRPhotoDecoderError.unreadableImage
                }
                let value = try QRPhotoDecoder.decodeFirstQR(in: data)
                code = value
                prepareImport(value)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct TeamImportCandidate {
    let team: TeamPreset
    let rawCode: String
    let isDetailed: Bool
}

private enum QRPhotoDecoderError: LocalizedError {
    case unreadableImage
    case noQRCode
    case emptyQRCode

    var errorDescription: String? {
        switch self {
        case .unreadableImage: return "无法读取这张图片，请换一张原图重试。"
        case .noQRCode: return "图片中没有识别到二维码。"
        case .emptyQRCode: return "二维码内容为空。"
        }
    }
}

private enum QRPhotoDecoder {
    static func decodeFirstQR(in data: Data) throws -> String {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(data: data, options: [:])
        try handler.perform([request])
        guard let observation = request.results?.first else { throw QRPhotoDecoderError.noQRCode }
        guard let value = observation.payloadStringValue, !value.isEmpty else { throw QRPhotoDecoderError.emptyQRCode }
        return value
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
                        }
                } else {
                    EmptyState(symbol: "camera.fill", title: "此设备不支持相机扫描", detail: "请返回后从相册选择，或粘贴预设码。")
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

