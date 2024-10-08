import SwiftUI

struct OpenAITestView: View {
    @State private var prompt: String = ""
    @State private var outputText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    let apiKey = ""// Replace with secure storage solution

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter your prompt", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                generateText()
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Generate")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Text(outputText)
                .padding()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .border(Color.gray, width: 1)
        }
        .padding()
    }

    func generateText() {
        guard !prompt.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 100,
            "temperature": 0.5,
            "frequency_penalty": 0.5,
            "presence_penalty": 0.5
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
            }
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    errorMessage = error?.localizedDescription ?? "Unknown error"
                }
                return
            }

            // Debugging: Print the raw response
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Debugging: Print parsed JSON structure
                    print("Parsed JSON: \(json)")

                    if let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let text = message["content"] as? String {
                        DispatchQueue.main.async {
                            outputText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    } else {
                        DispatchQueue.main.async {
                            errorMessage = "Failed to parse response structure"
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        errorMessage = "Failed to parse JSON response"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to decode JSON: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }
}

#Preview {
    OpenAITestView()
}
