import SwiftUI
import Vision

struct ContentView: View {
    @State private var capturedImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var isShowingCamera: Bool = false
    @State private var isShowingManualEntry: Bool = false
    @State private var openAIResponse: String = ""
    @State private var isComplete = false
    @State private var valueArr = [Double]()
    @State private var nutriScore: Int = 0
    @State private var grade: String = ""
    @State private var isTitleScaled = false 
    @State private var total: Int = 0
    
    let apiKey = ProcessInfo.processInfo.environment["API_KEY"]!

    // TODO: Testing UI - to be updated
    var body: some View {
        ZStack {
            
            NavigationStack {
                ZStack {
                    Image("backgroundImage").resizable().scaledToFill().ignoresSafeArea()
                    VStack {
//                        Image("hackathon_image-removebg-preview").resizable()
                        
                        Text("Nutri-Lens").font(.custom("AvenirNext-Bold", size: 40))
                            .shadow(color: .gray, radius: 5, x: 0, y: 2)
                            .padding(.top, 30)
                        Spacer()
                        
                        

                        Button("Enter Manually") {
                            isShowingManualEntry = true
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color(red: 0.6, green: 0.8, blue: 1.0))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .font(.custom("Avenir Next", size: 18))
                        .padding(.bottom, 1)
                                        
                        
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
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .font(.custom("Avenir Next", size: 18))

                        
                        
                        Button("Test with Sample Image") {
                            if let testImage = UIImage(named: "testFoodLabel") {
                                capturedImage = testImage
                                recognizeText(from: testImage)
                                print(recognizedText)
                                print(openAIResponse)
                            }
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color(red: 0.6, green: 0.8, blue: 1.0))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .font(.custom("Avenir Next", size: 18))
                        .padding(.bottom, 1)
                    }
                    .padding()
                    .navigationDestination(isPresented: $isShowingManualEntry) {
                        ManualEntryView()
                    }
                    .navigationDestination(isPresented: $isComplete) {
                        ResultView(scoreArr: valueArr, score: nutriScore, grade: grade, total: total)
                    }
                }
                
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
            "model": "gpt-3.5-turbo",
            
            // Prompt to be fine tuned
            "messages": [
                ["role": "system", "content": "Please extract the following nutritional values from the provided text (only numerical value), listing each value (only numerical) on a new line (not a numbered list): serving size, calories, total fat (g), saturated fat (g), sodium (g), total sugars (g), dietary fiber (g), and protein (g). If a value is absent, assume it is 0"],
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
                //completion([])
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                // print("OpenAI API Response status: \(httpResponse.statusCode)")
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                // print("Raw response from OpenAI API: \(dataString)")
            }
            
            guard let data = data else {
                print("No data returned from OpenAI API.")
                //completion([])
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let openAIResponseText = choices.first?["message"] as? [String: Any],
                   let content = openAIResponseText["content"] as? String {
                    
                    // Print OpenAI response. Any string manipulation or calling nutriscore class for analysis to be done from here.
                    
                    print(content)
                    
                    let parsableContent = content.components(separatedBy: .newlines)
                        
                    let cleanedLines = parsableContent.map { line in
                        line.trimmingCharacters(in: .whitespaces)
                    }
                    
                    //var valueArr = [Double]()
                    
                    
                    for str in cleanedLines {
                        if let val = Double(str) {
                            valueArr.append(val)
                        }
                    }
                    print(valueArr)
                    scoreCalculation(valueArr: valueArr)
                    
                    
                    
                    
                    DispatchQueue.main.async {
                        self.openAIResponse = content
                        //completion(valueArr)
                    }
                } else {
                    print("Failed to parse OpenAI response.")
                    //completion([])
                }
            } catch {
                print("Error parsing OpenAI response: \(error.localizedDescription)")
                //completion([])
            }
        }
        
        task.resume()
    }
    
    
    
    func scoreCalculation(valueArr: [Double]) {
        guard valueArr.count >= 8 else {
            print("Oops something went wrong. Please try again")
            return
        }

        let servingSize = valueArr[0]
        let calories = valueArr[1]
        let totalFat = valueArr[2]
        let saturatedFat = valueArr[3]
        let sodium = valueArr[4]
        let totalSugars = valueArr[5]
        let fiber = valueArr[6]
        let protein = valueArr[7]
        
        let nutriInfo = NutritionInfo(
            servingSize: servingSize,
            calories: calories,
            totalFat: totalFat,
            saturatedFat: saturatedFat,
            sodium: sodium,
            totalSugars: totalSugars,
            fiber: fiber,
            protein: protein)

        nutriScore = NutriScoreCalculator.calculateNutriScore(for: nutriInfo)
        switch nutriScore {
            case ..<(-1):
                grade = "A"
            case 0..<2:
                grade = "B"
            case 3..<10:
                grade = "C"
            case 11..<19:
                grade = "D"
            case 19...:
                grade = "E"
            default:
                grade = "E" 
            }
        
        total = Int(valueArr[1]+valueArr[2]+valueArr[3]+valueArr[4]+valueArr[5]+valueArr[6]+valueArr[7])

        print(nutriScore)
        print(grade)
        isComplete = true
    }




}



#Preview {
    ContentView()
}
