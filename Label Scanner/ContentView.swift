import SwiftUI
import Vision
struct ContentView: View {
    @State private var capturedImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var isShowingCamera: Bool = false
    let apiKey = "sk-ZpGlQBp2LJVsCQxA4sKIqUBTjB4ouqtd5TcAT2BzBHT3BlbkFJbcQSmK6Eroc6CppF66Vuh0QWCOIGdqc_4ZhH_nLsgA"

    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                Image(systemName: "camera")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.tint)
            }

            if !recognizedText.isEmpty {
                Text(recognizedText)
                    .padding()
            }
            
            Button("Open Camera") {
                isShowingCamera = true
            }
            .sheet(isPresented: $isShowingCamera) {
                CameraView { image in
                capturedImage = image
                }
            }

            Button("Test with Sample Image") {
                if let testImage = UIImage(named: "testFoodLabel") { // Replace "YourImageName" with the name of your image
                    capturedImage = testImage
                    recognizeText(from: testImage)
                    print(recognizedText)
                }
            }
            .padding(15)
        }
        .padding(15)
    }

    func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            // Sort the observations top to bottom, then left to right
            let sortedObservations = observations.sorted { first, second in
                if first.boundingBox.minY > second.boundingBox.minY {
                    return true
                } else if first.boundingBox.minY == second.boundingBox.minY {
                    return first.boundingBox.minX < second.boundingBox.minX
                } else {
                    return false
                }
            }
            
            // Group observations into lines based on their y-coordinate proximity
            var recognizedStrings: [String] = []
            var currentLine: [VNRecognizedTextObservation] = []
            let lineThreshold: CGFloat = 0.02 // Adjust threshold for line grouping
            
            for observation in sortedObservations {
                if let lastObservation = currentLine.last {
                    let yDifference = abs(observation.boundingBox.minY - lastObservation.boundingBox.minY)
                    if yDifference > lineThreshold {
                        // Append the current line and start a new one
                        let lineText = currentLine.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                        recognizedStrings.append(lineText)
                        currentLine = []
                    }
                }
                currentLine.append(observation)
            }
            
            // Append the last line
            if !currentLine.isEmpty {
                let lineText = currentLine.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                recognizedStrings.append(lineText)
            }
            
            // Update the recognized text state variable
            recognizedText = recognizedStrings.joined(separator: "\n")
        }
        
        request.recognitionLevel = .accurate
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error recognizing text:", error.localizedDescription)
        }
    }

}

#Preview {
    ContentView()
}
