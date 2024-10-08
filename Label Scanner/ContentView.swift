import SwiftUI
import Vision

struct ContentView: View {
    @State private var capturedImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var isShowingCamera: Bool = false
    @State private var isShowingManualEntry: Bool = false
    @State private var openAIResponse: String = "" // To store the OpenAI response
    
    // TODO: Store api key safely in .env file or equivalent
    let apiKey = ""

    // TODO: Testing UI - to be updated
    var body: some View {
        NavigationStack {
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
                
                if !openAIResponse.isEmpty {
                    Text("OpenAI Response:")
                    Text(openAIResponse)
                        .padding()
                }

                Button("Enter Manually") {
                    isShowingManualEntry = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                
                // TODO: Integrate openAI calls with this button
                Button("Open Camera") {
                    isShowingCamera = true
                }
                .sheet(isPresented: $isShowingCamera) {
                    CameraView { image in
                        capturedImage = image
                        recognizeText(from: image)
                        print(recognizedText)
                    }
                }

                
                
                Button("Test with Sample Image") {
                    if let testImage = UIImage(named: "testFoodLabel") {
                        capturedImage = testImage
                        recognizeText(from: testImage)
                        print(recognizedText)
                        print(openAIResponse)
                    }
                }
                .padding()
            }
            .padding()
            .navigationDestination(isPresented: $isShowingManualEntry) {
                ManualEntryView()
            }
        }
    }

    // This function recognizes text from an image using Vision framework
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
            let lineThreshold: CGFloat = 0.02
            
            for observation in sortedObservations {
                if let lastObservation = currentLine.last {
                    let yDifference = abs(observation.boundingBox.minY - lastObservation.boundingBox.minY)
                    if yDifference > lineThreshold {
                        let lineText = currentLine.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                        recognizedStrings.append(lineText)
                        currentLine = []
                    }
                }
                currentLine.append(observation)
            }
            
            if !currentLine.isEmpty {
                let lineText = currentLine.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                recognizedStrings.append(lineText)
            }
            
            // Recognized text - manipulate if required
            recognizedText = recognizedStrings.joined(separator: "\n")
            
            // OpenAI method call from here after recognizing the text
            sendToOpenAI(text: recognizedText)
        }
        
        request.recognitionLevel = .accurate
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error recognizing text:", error.localizedDescription)
        }
    }
    
    // Function to handle http requests and openAI integration
    func sendToOpenAI(text: String) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!  // Using chat completions endpoint
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",  // Update the model to gpt-3.5-turbo
            
            // Prompt to be fine tuned
            "messages": [
                ["role": "system", "content": "You are an assistant that extracts only numerical values from food labels. Provide the following numerical values and nothing else, each on a new line: serving size, calories, total fat (g), saturated fat (g), sodium (mg), total sugars (g), and protein (g). Only return the numbers, without units or extra text. If the field is absent, return 0"],
                ["role": "user", "content": text]
            ],
            "max_tokens": 200
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Error encoding request body: \(error.localizedDescription)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error with OpenAI API request: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("OpenAI API Response status: \(httpResponse.statusCode)")
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Raw response from OpenAI API: \(dataString)")
            }
            
            guard let data = data else {
                print("No data returned from OpenAI API.")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let openAIResponseText = choices.first?["message"] as? [String: Any],
                   let content = openAIResponseText["content"] as? String {
                    
                    // Print OpenAI response. Any string manipulation or calling nutriscore class for analysis to be done from here.
                    print("Parsed OpenAI response: \(content)")
                    DispatchQueue.main.async {
                        self.openAIResponse = content
                    }
                } else {
                    print("Failed to parse OpenAI response.")
                }
            } catch {
                print("Error parsing OpenAI response: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }


}



#Preview {
    ContentView()
}
