//
//  ManualEntryView.swift
//  Label Scanner
//
//  Created by Kabir Rajkotia on 9/10/24.
//

import SwiftUI

struct ManualEntryView: View {
    @State private var servingSize: String = ""
    @State private var calories: String = ""
    @State private var totalFat: String = ""
    @State private var saturatedFat: String = ""
    @State private var sodium: String = ""
    @State private var totalSugars: String = ""
    @State private var fiber: String = ""
    @State private var protein: String = ""
    
    @State private var nutriScore: Int? = nil

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Enter Nutritional Info")) {
                    TextField("Serving Size (g)", text: $servingSize)
                        .keyboardType(.decimalPad)
                    TextField("Calories (kcal)", text: $calories)
                        .keyboardType(.decimalPad)
                    TextField("Total Fat (g)", text: $totalFat)
                        .keyboardType(.decimalPad)
                    TextField("Saturated Fat (g)", text: $saturatedFat)
                        .keyboardType(.decimalPad)
                    TextField("Sodium (mg)", text: $sodium)
                        .keyboardType(.decimalPad)
                    TextField("Total Sugars (g)", text: $totalSugars)
                        .keyboardType(.decimalPad)
                    TextField("Fiber (g)", text: $fiber)
                        .keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                }
            }
            
            Button(action: calculateNutriScore) {
                Text("Calculate Nutri-Score")
                    .bold()
                    .frame(minWidth: 100, minHeight: 40)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            
            if let score = nutriScore {
                Text("Nutri-Score: \(score)")
                    .font(.title)
                    .padding()
            }
        }
        .navigationTitle("Manual Entry")
    }
    
    func calculateNutriScore() {
        guard let servingSizeValue = Double(servingSize),
              let caloriesValue = Double(calories),
              let totalFatValue = Double(totalFat),
              let saturatedFatValue = Double(saturatedFat),
              let sodiumValue = Double(sodium),
              let totalSugarsValue = Double(totalSugars),
              let fiberValue = Double(fiber),
              let proteinValue = Double(protein) else {
            return
        }
        
        let nutritionInfo = NutritionInfo(
            servingSize: servingSizeValue,
            calories: caloriesValue,
            totalFat: totalFatValue,
            saturatedFat: saturatedFatValue,
            sodium: sodiumValue,
            totalSugars: totalSugarsValue,
            fiber: fiberValue,
            protein: proteinValue
        )
        
        nutriScore = NutriScoreCalculator.calculateNutriScore(for: nutritionInfo)
    }
}

#Preview {
    ManualEntryView()
}
