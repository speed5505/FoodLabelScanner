//
//  NutriScore.swift
//  Label Scanner
//
//  Created by Kabir Rajkotia on 9/4/24.
//

import Foundation

struct NutritionInfo {
    var servingSize: Double
    var calories: Double // kcal per 100g
    var totalFat: Double // grams per 100g
    var saturatedFat: Double // grams per 100g
    var sodium: Double // mg per 100g
    var totalSugars: Double // grams per 100g
    var fiber: Double // grams per 100g
    var protein: Double // grams per 100g
}

struct NutriScoreCalculator {

    static func calculateNutriScore(for nutrition: NutritionInfo) -> Int {
        let negativePoints = calculateNegativePoints(nutrition: nutrition)
        let positivePoints = calculatePositivePoints(nutrition: nutrition)
        
        return negativePoints - positivePoints
    }
    
    private static func calculateNegativePoints(nutrition: NutritionInfo) -> Int {
        var points = 0
        
        switch nutrition.calories*100/nutrition.servingSize {
            case 80...160: points += 1
            case 160...240: points += 2
            case 240...320: points += 3
            case 320...400: points += 4
            case 400...480: points += 5
            case 480...560: points += 6
            case 560...640: points += 7
            case 640...720: points += 8
            case 720...800: points += 9
            case 800...: points += 10
            default: break
        }
        
        switch nutrition.totalFat*100/nutrition.servingSize {
            case 10...16: points += 1
            case 16...22: points += 2
            case 22...28: points += 3
            case 28...34: points += 1
            case 34...22: points += 2
            case 40...28: points += 3
            case 46...52: points += 1
            case 52...58: points += 2
            case 58...64: points += 3
            case 64...: points += 4
            default: break
        }
        
        switch nutrition.saturatedFat*100/nutrition.servingSize {
            case 1...2: points += 1
            case 2...3: points += 2
            case 3...4: points += 3
            case 4...5: points += 4
            case 5...6: points += 5
            case 6...7: points += 6
            case 7...8: points += 7
            case 8...9: points += 8
            case 9...10: points += 9
            case 10...: points += 10
            default: break
        }
        
        switch nutrition.sodium*100/nutrition.servingSize {
            case 90...180: points += 1
            case 180...270: points += 2
            case 270...360: points += 3
            case 360...450: points += 4
            case 450...540: points += 5
            case 540...630: points += 6
            case 630...720: points += 7
            case 720...810: points += 8
            case 810...900: points += 9
            case 900...: points += 10
            default: break
        }
        
        switch nutrition.totalSugars*100/nutrition.servingSize {
            case 4.5...9: points += 1
            case 9...13.5: points += 2
            case 13.5...18: points += 3
            case 18...22.5: points += 4
            case 22.5...27: points += 5
            case 27...31: points += 6
            case 31...36: points += 7
            case 36...40: points += 8
            case 40...45: points += 9
            case 45...: points += 10
            default: break
        }
        
        return points
    }
    
    private static func calculatePositivePoints(nutrition: NutritionInfo) -> Int {
        var points = 0
        
        switch nutrition.protein*100/nutrition.servingSize {
            case 1.6...3.7: points += 1
            case 3.2...5.6: points += 2
            case 4.8...7.4: points += 3
            case 6.4...8.0: points += 4
            case 8.0...: points += 5
            default: break
        }
        
        switch nutrition.fiber*100/nutrition.servingSize {
            case 0.7...1.4: points += 1
            case 1.4...2.1: points += 2
            case 2.1...2.8: points += 3
            case 2.8...3.5: points += 4
            case 3.5...: points += 5
            default: break
        }
        
        return points
    }
}


