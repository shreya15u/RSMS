import Foundation
import Accelerate

/// Hardware-accelerated vector math operations using vDSP.
enum MathUtilities {
    
    /// Calculates the dot product of two vectors.
    static func dotProduct(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var result: Float = 0
        vDSP_dotpr(a, 1, b, 1, &result, vDSP_Length(a.count))
        return result
    }
    
    /// Calculates the magnitude (L2 norm) of a vector.
    static func magnitude(_ vector: [Float]) -> Float {
        guard !vector.isEmpty else { return 0 }
        var sumSquares: Float = 0
        vDSP_svesq(vector, 1, &sumSquares, vDSP_Length(vector.count))
        return sqrt(sumSquares)
    }
    
    /// Calculates the cosine similarity between two vectors.
    /// Returns a value between -1.0 and 1.0 (1.0 being identical).
    static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        let dp = dotProduct(a, b)
        let magA = magnitude(a)
        let magB = magnitude(b)
        
        if magA == 0 || magB == 0 { return 0 }
        return dp / (magA * magB)
    }
    
    /// Computes the mathematical average (centroid) of a list of equal-length vectors.
    static func average(of vectors: [[Float]]) -> [Float]? {
        guard let first = vectors.first, !first.isEmpty else { return nil }
        let dimension = first.count
        var result = [Float](repeating: 0, count: dimension)
        
        var validVectorsCount: Float = 0
        
        for vector in vectors {
            if vector.count == dimension {
                vDSP_vadd(result, 1, vector, 1, &result, 1, vDSP_Length(dimension))
                validVectorsCount += 1
            }
        }
        
        guard validVectorsCount > 0 else { return nil }
        vDSP_vsdiv(result, 1, &validVectorsCount, &result, 1, vDSP_Length(dimension))
        return result
    }
}
