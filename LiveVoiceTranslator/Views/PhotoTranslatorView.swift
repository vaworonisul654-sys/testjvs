import SwiftUI
import PhotosUI

/// Photo translation screen with crop selection
struct PhotoTranslatorView: View {
    @State private var viewModel = PhotoTranslatorViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    private let teal = Color(red: 0, green: 0.76, blue: 0.66)
    private let bgColor = Color(red: 0.02, green: 0.027, blue: 0.059)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            Circle()
                .fill(emerald.opacity(0.03))
                .frame(width: 350, height: 350)
                .blur(radius: 80)

            VStack(spacing: 0) {
                Text("Фото перевод")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 16).padding(.bottom, 8)

                languageSelector
                    .padding(.horizontal, 20).padding(.bottom, 10)

                if !viewModel.isAPIKeyConfigured {
                    apiBanner.padding(.horizontal, 20).padding(.bottom, 8)
                }
                if let error = viewModel.errorMessage {
                    errorBanner(error).padding(.horizontal, 20).padding(.bottom, 8)
                }

                if viewModel.isCropping {
                    cropView
                } else if viewModel.capturedImage != nil {
                    resultView
                } else {
                    emptyState
                }

                Spacer(minLength: 80)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showCamera) {
            CameraView(
                onImageCaptured: { viewModel.handleCapturedImage($0) },
                onCancel: { viewModel.showCamera = false }
            ).ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { viewModel.handleCapturedImage(image) }
                }
            }
            selectedPhotoItem = nil
        }
    }

    // MARK: - Language Selector

    private var languageSelector: some View {
        HStack(spacing: 0) {
            LanguagePickerView(
                selectedLanguage: Binding(
                    get: { viewModel.sourceLanguage ?? .english },
                    set: { viewModel.sourceLanguage = $0 }
                ),
                label: "ИЗ"
            )

            Button(action: swapLanguages) {
                ZStack {
                    Circle()
                        .fill(emerald.opacity(0.12))
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(emerald.opacity(0.25), lineWidth: 1))

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(emerald)
                }
            }
            .disabled(viewModel.isTranslating)

            LanguagePickerView(
                selectedLanguage: $viewModel.targetLanguage,
                label: "НА"
            )
        }
    }

    private func swapLanguages() {
        let temp = viewModel.sourceLanguage ?? .english
        viewModel.sourceLanguage = viewModel.targetLanguage
        viewModel.targetLanguage = temp
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Button(action: viewModel.openCamera) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [emerald.opacity(0.12), .clear], center: .center, startRadius: 30, endRadius: 90))
                        .frame(width: 180, height: 180)
                    Circle()
                        .fill(RadialGradient(colors: [emerald.opacity(0.8), teal.opacity(0.6), Color(red: 0.02, green: 0.15, blue: 0.10)], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 5, endRadius: 60))
                        .frame(width: 120, height: 120)
                        .overlay(Circle().fill(RadialGradient(colors: [.white.opacity(0.2), .clear], center: UnitPoint(x: 0.3, y: 0.25), startRadius: 0, endRadius: 40)))
                        .overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.15), emerald.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                        .shadow(color: emerald.opacity(0.2), radius: 20)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36, weight: .light)).foregroundStyle(.white)
                }
            }.buttonStyle(.plain)

            VStack(spacing: 6) {
                Text("Сфотографируйте текст")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white.opacity(0.85))
                Text("Меню, вывеска, документ — перевод мгновенно")
                    .font(.system(size: 13)).foregroundStyle(.white.opacity(0.3))
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle").font(.system(size: 14))
                    Text("Импорт из галереи").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(emerald)
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(emerald.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(emerald.opacity(0.15), lineWidth: 1))
                )
            }
            Spacer()
        }
    }

    // MARK: - Crop View

    private var cropView: some View {
        VStack(spacing: 12) {
            // Header with Back Button
            HStack {
                Button(action: viewModel.clearResult) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(12)
                        .background(Circle().fill(.white.opacity(0.05)))
                }
                Spacer()
                
                // Instruction
                HStack(spacing: 6) {
                    Image(systemName: "crop")
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(emerald)
                    Text("Выберите область")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(
                    Capsule().fill(emerald.opacity(0.08))
                        .overlay(Capsule().stroke(emerald.opacity(0.15), lineWidth: 1))
                )
                
                Spacer()
                Spacer().frame(width: 44) // Balance the back button
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)

            // Photo with crop rectangle
            if let image = viewModel.capturedImage {
                GeometryReader { geo in
                    let containerSize: CGSize = geo.size
                    let rotatedImageSize: CGSize = viewModel.rotatedImageSize
                    let fit: CGSize = aspectFitSize(imageSize: rotatedImageSize, containerSize: containerSize)
                    let scaleX: CGFloat = fit.width / max(rotatedImageSize.width, 1)
                    let scaleY: CGFloat = fit.height / max(rotatedImageSize.height, 1)
                    let offsetX: CGFloat = (containerSize.width - fit.width) / 2
                    let offsetY: CGFloat = (containerSize.height - fit.height) / 2

                ZStack {
                    // Photo
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .rotationEffect(.degrees(viewModel.totalRotation))

                    // Dimmed area
                    let displayRect = CGRect(
                        x: offsetX + viewModel.cropRect.origin.x * scaleX,
                        y: offsetY + viewModel.cropRect.origin.y * scaleY,
                        width: viewModel.cropRect.width * scaleX,
                        height: viewModel.cropRect.height * scaleY
                    )

                    CropOverlay(cropRect: displayRect, containerSize: containerSize)
                        .fill(Color.black.opacity(0.5))

                    Rectangle()
                        .stroke(emerald, lineWidth: 2)
                        .frame(width: displayRect.width, height: displayRect.height)
                        .position(x: displayRect.midX, y: displayRect.midY)

                    // Corner handles
                    ForEach(0..<4, id: \.self) { corner in
                        let pos = cornerPosition(corner: corner, rect: displayRect)
                        Circle()
                            .fill(emerald)
                            .frame(width: 20, height: 20)
                            .position(pos)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        handleCornerDrag(corner: corner, location: value.location,
                                                         scaleX: scaleX, scaleY: scaleY,
                                                         offsetX: offsetX, offsetY: offsetY,
                                                         imageSize: rotatedImageSize)
                                    }
                            )
                    }

                    // Move gesture
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: max(displayRect.width - 40, 20), height: max(displayRect.height - 40, 20))
                        .position(x: displayRect.midX, y: displayRect.midY)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let dx = value.translation.width / scaleX
                                    let dy = value.translation.height / scaleY
                                    var newRect = viewModel.cropRect
                                    newRect.origin.x = max(0, min(rotatedImageSize.width - newRect.width, newRect.origin.x + dx))
                                    newRect.origin.y = max(0, min(rotatedImageSize.height - newRect.height, newRect.origin.y + dy))
                                    viewModel.cropRect = newRect
                                }
                        )
                }
                .gesture(
                    RotationGesture()
                        .onChanged { angle in
                            viewModel.updateRotation(angle.degrees)
                        }
                        .onEnded { _ in
                            viewModel.finalizeRotation()
                        }
                )
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
            }

            // Buttons
            HStack(spacing: 12) {
                Button(action: viewModel.rotate) {
                    ZStack {
                        Circle()
                            .fill(emerald.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(emerald.opacity(0.2), lineWidth: 1))
                        Image(systemName: "rotate.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(emerald)
                    }
                }

                Button(action: viewModel.translateCroppedArea) {
                    HStack(spacing: 6) {
                        Image(systemName: "translate").font(.system(size: 14))
                        Text("Перевести").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(emerald))
                }

                Button(action: viewModel.reshoot) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.rotate").font(.system(size: 14))
                        Text("Переснять")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(emerald)
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12).fill(emerald.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(emerald.opacity(0.2), lineWidth: 1))
                    )
                }
            }
            .padding(.top, 6)
        }
        .padding(.top, 4)
    }

    // MARK: - Result View

    private var resultView: some View {
        VStack(spacing: 0) {
            // Header with Back Button
            HStack {
                Button(action: viewModel.clearResult) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(12)
                        .background(Circle().fill(.white.opacity(0.05)))
                }
                Spacer()
                Text("Результат")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Spacer().frame(width: 44)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 12) {
                if let image = viewModel.capturedImage {
                    VStack(spacing: 8) {
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .rotationEffect(.degrees(viewModel.totalRotation))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(emerald.opacity(0.1), lineWidth: 1))
                            
                            // AR Overlay
                            if let blocks = viewModel.translation?.blocks, !blocks.isEmpty {
                                GeometryReader { geo in
                                    AROverlayView(blocks: blocks, imageSize: image.size, containerSize: geo.size)
                                }
                            }
                        }
                        .frame(maxHeight: 400) // Slightly taller for detailed tables/signs
                        .onTapGesture {
                            viewModel.reselectArea()
                        }
                        
                        Text("Нажмите на фото, чтобы изменить область")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                }

                if viewModel.isTranslating {
                    HStack(spacing: 10) {
                        ProgressView().tint(emerald)
                        Text("Перевожу...")
                            .font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.5))
                    }.padding(.vertical, 16)
                }

                if let result = viewModel.translation {
                    let translated = result.translatedText ?? result.blocks?.map { $0.text }.joined(separator: "\n\n") ?? "Отсутствует текст для перевода"
                    if !translated.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if let lang = result.sourceLang {
                                Text("🌐 \(lang)")
                                    .font(.system(size: 11, weight: .bold)).foregroundStyle(emerald.opacity(0.7))
                            }
                            Spacer()
                            Button(action: viewModel.copyTranslation) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc").font(.system(size: 12))
                                    Text("Скопировать").font(.system(size: 11, weight: .medium))
                                }.foregroundStyle(emerald.opacity(0.6))
                            }
                        }
                        ScrollView {
                            Text(translated)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                        .scrollIndicators(.visible)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.03))
                            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.2)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(emerald.opacity(0.1), lineWidth: 1))
                    )
                    .padding(.horizontal, 16)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: viewModel.openCamera) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill").font(.system(size: 14))
                            Text("Переснять").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(emerald)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(emerald.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(emerald.opacity(0.2), lineWidth: 1))
                        )
                    }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle").font(.system(size: 14))
                            Text("Галерея").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.04))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
                        )
                    }
                }
                .padding(.top, 4).padding(.bottom, 20)
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }
}

    // MARK: - Helpers

    private func aspectFitSize(imageSize: CGSize, containerSize: CGSize) -> CGSize {
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    private func cornerPosition(corner: Int, rect: CGRect) -> CGPoint {
        switch corner {
        case 0: return CGPoint(x: rect.minX, y: rect.minY)
        case 1: return CGPoint(x: rect.maxX, y: rect.minY)
        case 2: return CGPoint(x: rect.maxX, y: rect.maxY)
        case 3: return CGPoint(x: rect.minX, y: rect.maxY)
        default: return .zero
        }
    }

    private func handleCornerDrag(corner: Int, location: CGPoint, scaleX: CGFloat, scaleY: CGFloat, offsetX: CGFloat, offsetY: CGFloat, imageSize: CGSize) {
        let imgX = (location.x - offsetX) / scaleX
        let imgY = (location.y - offsetY) / scaleY
        var r = viewModel.cropRect
        let minSize: CGFloat = 50

        switch corner {
        case 0: // top-left
            let newW = r.maxX - max(0, imgX)
            let newH = r.maxY - max(0, imgY)
            if newW > minSize { r.origin.x = max(0, imgX); r.size.width = newW }
            if newH > minSize { r.origin.y = max(0, imgY); r.size.height = newH }
        case 1: // top-right
            let newW = max(minSize, min(imageSize.width, imgX) - r.origin.x)
            let newH = r.maxY - max(0, imgY)
            r.size.width = newW
            if newH > minSize { r.origin.y = max(0, imgY); r.size.height = newH }
        case 2: // bottom-right
            r.size.width = max(minSize, min(imageSize.width, imgX) - r.origin.x)
            r.size.height = max(minSize, min(imageSize.height, imgY) - r.origin.y)
        case 3: // bottom-left
            let newW = r.maxX - max(0, imgX)
            if newW > minSize { r.origin.x = max(0, imgX); r.size.width = newW }
            r.size.height = max(minSize, min(imageSize.height, imgY) - r.origin.y)
        default: break
        }
        viewModel.cropRect = r
    }

    // MARK: - Banners

    private var apiBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(emerald).font(.system(size: 12))
            Text("Добавьте OPENAI_API_KEY в Debug.xcconfig").font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.6))
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(emerald.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 10).stroke(emerald.opacity(0.12), lineWidth: 1)))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red.opacity(0.7)).font(.system(size: 12))
            Text(message).font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.6))
            Spacer()
            Button { viewModel.errorMessage = nil } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(.red.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 10).stroke(.red.opacity(0.12), lineWidth: 1)))
    }
}

// MARK: - Crop Overlay Shape (dims area outside selection)

struct CropOverlay: Shape {
    let cropRect: CGRect
    let containerSize: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(origin: .zero, size: containerSize))
        path.addRect(cropRect)
        return path
    }
}

extension CropOverlay {
    var fillStyle: FillStyle { FillStyle(eoFill: true) }

    func fill(_ color: Color) -> some View {
        self.fill(color, style: FillStyle(eoFill: true))
    }
}

// MARK: - AR Overlay View

struct AROverlayView: View {
    let blocks: [OpenAIVisionService.TranslationBlock]
    let imageSize: CGSize
    let containerSize: CGSize
    
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)

    var body: some View {
        let fit = aspectFitSize(imageSize: imageSize, containerSize: containerSize)
        let scale = fit.width / imageSize.width
        let offsetX = (containerSize.width - fit.width) / 2
        let offsetY = (containerSize.height - fit.height) / 2

        ZStack(alignment: .topLeading) {
            ForEach(0..<blocks.count, id: \.self) { index in
                let block = blocks[index]
                let bbox = block.bbox // [ymin, xmin, ymax, xmax] normalized 0-1000
                
                let x = (CGFloat(bbox[1]) / 1000.0 * imageSize.width) * scale + offsetX
                let y = (CGFloat(bbox[0]) / 1000.0 * imageSize.height) * scale + offsetY
                let w = (CGFloat(bbox[3] - bbox[1]) / 1000.0 * imageSize.width) * scale
                let h = (CGFloat(bbox[2] - bbox[0]) / 1000.0 * imageSize.height) * scale
                
                Text(block.text)
                    .font(.system(size: max(8, h * 0.7), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(4)
                    .frame(width: w, height: h, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.black.opacity(0.6))
                            .shadow(radius: 2)
                    )
                    .position(x: x + w/2, y: y + h/2)
            }
        }
    }

    private func aspectFitSize(imageSize: CGSize, containerSize: CGSize) -> CGSize {
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}

#Preview {
    PhotoTranslatorView()
}
