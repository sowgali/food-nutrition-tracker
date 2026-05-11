import Foundation

public enum Fmt {
    public static func g(_ value: Double) -> String { "\(Int(value.rounded()))g" }
    public static func mg(_ value: Double) -> String { "\(Int(value.rounded()))mg" }
    public static func kcal(_ value: Double) -> String { "\(Int(value.rounded())) kcal" }
    public static func quantity(_ value: Double, unit: Unit) -> String {
        let rounded = (value * 10).rounded() / 10
        let v = rounded.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(rounded))
            : String(rounded)
        return "\(v) \(unit.rawValue)"
    }
}
