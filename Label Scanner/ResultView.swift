import SwiftUI
import Charts // Make sure to import Charts framework

struct ResultView: View {
    var scoreArr: [Double]
    var score: Int
    var grade: String
    var total: Int
    
    var body: some View {
        ZStack {
            Image("backgroundImage").resizable().scaledToFill().ignoresSafeArea()
            VStack {
                Text("Nutrition Summary")
                    .font(.title)
                    .padding()

                // Check if scoreArr has values to display the chart
                if !scoreArr.isEmpty {
                    DonutChart(values: Array(scoreArr[1...])) // Start from index 1 to skip serving size
                        .frame(width: 300, height: 300)
                        .padding()
                } else {
                    Text("No data available")
                        .foregroundColor(.gray)
                }

                Text("NutriScore: \(score)")
                Text("Grade: \(grade)")
                    .font(.headline)
                
                switch grade {
                    case "A":
                        Text("Highly Nutritious")
                    case "B":
                        Text("Healthy")
                    case "C":
                        Text("Balanced Choice")
                    case "D":
                        Text("Less Healthy")
                    default:
                        Text("Unhealthy")
                    }
                }
            }
        }
    }

// Donut Chart View
struct DonutChart: View {
    var values: [Double]

    var body: some View {
        // Prepare the data for the donut chart, excluding serving size
        let categories = ["Calories      ", "Total Fat    ", "Saturated Fat  ", "Sodium           ", "Total Sugars          ", "Fiber  ", "Protein  "]
        let totalValue = values.reduce(0, +) // Calculate total value for percentage calculation
        let data = categories.enumerated().map { (index, name) in
            (name: name, value: values[index])
        }

        ZStack {
            Chart(data, id: \.name) { entry in
                SectorMark(
                    angle: .value("Value", entry.value),
                    innerRadius: .ratio(0.618), // Inner radius for the donut effect
                    outerRadius: .inset(10) // Outer radius
                )
                .foregroundStyle(by: .value("Nutrient", entry.name))
            }

            // Individual Text views for each percentage
            let percentages = data.map { totalValue > 0 ? ($0.value / totalValue) * 100 : 0 }
            let positions: [(CGFloat, CGFloat)] = [
                (75, 251),
                (170, 251),
                (314, 251),
                (73, 272),
                (193, 272),
                (272, 272),
                (70, 293)
            ]

            // Creating Text views for each percentage independently
            ForEach(0..<data.count, id: \.self) { index in
                Text(String(format: "%.1f%%", percentages[index]))
                    .position(x: positions[index].0, y: positions[index].1)
                    .foregroundColor(.black)
                    .font(.caption)
            }
        }
    }
}

// Preview for testing
#Preview {
    ResultView(scoreArr: [10, 20, 30, 40, 50, 60, 70, 80], score: 5, grade: "B", total: 0)
}
