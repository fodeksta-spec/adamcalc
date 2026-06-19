import SwiftUI

// MARK: - Colors

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

private enum Palette {
    static let bg       = Color(hex: 0x15130F)
    static let readout  = Color(hex: 0xF2E8D5)
    static let dim      = Color(hex: 0x8A8073)
    static let digit    = Color(hex: 0x2A2723)
    static let fn       = Color(hex: 0x403A33)
    static let op       = Color(hex: 0xE0922F)
    static let onOp     = Color(hex: 0x1A130A)
}

// MARK: - Engine

struct Calculator {
    private(set) var display = "0"
    private(set) var expression = ""
    private var stored: Double?
    private var op: String?
    private var justEvaluated = false

    private static let ops: [String: (Double, Double) -> Double] = [
        "+": (+), "−": (-), "×": (*),
        "÷": { $1 == 0 ? Double.nan : $0 / $1 }
    ]

    var activeOp: String? { justEvaluated ? nil : op }

    mutating func digit(_ d: String) {
        if display == "Error" { display = "0" }
        if justEvaluated { hardReset() }
        display = (display == "0") ? d : display + d
    }

    mutating func decimal() {
        if justEvaluated { hardReset() }
        if display == "Error" { display = "0" }
        if !display.contains(".") { display += "." }
    }

    mutating func choose(_ symbol: String) {
        guard display != "Error" else { return }
        if op != nil, !justEvaluated {
            compute()
        } else {
            stored = Double(display)
        }
        op = symbol
        justEvaluated = false
        display = "0"
        if let s = stored { expression = Self.fmt(s) + " " + symbol }
    }

    mutating func equals() {
        guard let o = op, display != "Error", let a = stored else { return }
        let b = display
        compute()
        if display != "Error" {
            expression = "\(Self.fmt(a)) \(o) \(Self.fmt(Double(b) ?? 0)) ="
        }
        op = nil
        justEvaluated = true
    }

    mutating func clear() {
        display = "0"; expression = ""; stored = nil; op = nil; justEvaluated = false
    }

    mutating func negate() {
        guard display != "Error", display != "0" else { return }
        display = display.hasPrefix("-") ? String(display.dropFirst()) : "-" + display
    }

    mutating func percent() {
        guard display != "Error", let v = Double(display) else { return }
        display = Self.raw(v / 100)
        justEvaluated = false
    }

    private mutating func compute() {
        guard let o = op, let a = stored, let fn = Self.ops[o], let b = Double(display) else { return }
        let out = fn(a, b)
        if out.isFinite {
            stored = out
            display = Self.raw(out)
        } else {
            display = "Error"; stored = nil; op = nil
        }
    }

    private mutating func hardReset() {
        stored = nil; op = nil; justEvaluated = false; expression = ""; display = "0"
    }

    // raw machine string (no grouping) so it can be parsed back
    private static func raw(_ v: Double) -> String {
        if v == v.rounded() && abs(v) < 1e15 { return String(Int64(v)) }
        return String(v)
    }

    // pretty grouped string for showing
    static func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 8
        f.usesGroupingSeparator = true
        return f.string(from: NSNumber(value: v)) ?? String(v)
    }

    // what the display should show — group the integer part of the typed string
    var prettyDisplay: String {
        if display == "Error" { return display }
        let neg = display.hasPrefix("-")
        let body = neg ? String(display.dropFirst()) : display
        let parts = body.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intPart = String(parts[0])
        let grouped = Self.fmt(Double(intPart) ?? 0)
        var out = grouped
        if body.contains(".") {
            let dec = parts.count > 1 ? String(parts[1]) : ""
            out = grouped + "." + dec
        }
        return (neg ? "-" : "") + out
    }
}

// MARK: - Button model

enum Key: Equatable {
    case digit(String), op(String), zero, decimal, equals, clear, negate, percent

    var label: String {
        switch self {
        case .digit(let d): return d
        case .op(let o):    return o
        case .zero:         return "0"
        case .decimal:      return "."
        case .equals:       return "="
        case .clear:        return "AC"
        case .negate:       return "±"
        case .percent:      return "%"
        }
    }

    var isOp: Bool { if case .op = self { return true }; if case .equals = self { return true }; return false }
    var isFn: Bool {
        switch self { case .clear, .negate, .percent: return true; default: return false }
    }
}

// MARK: - View

struct ContentView: View {
    @State private var calc = Calculator()

    private let rows: [[Key]] = [
        [.clear, .negate, .percent, .op("÷")],
        [.digit("7"), .digit("8"), .digit("9"), .op("×")],
        [.digit("4"), .digit("5"), .digit("6"), .op("−")],
        [.digit("1"), .digit("2"), .digit("3"), .op("+")],
        [.zero, .decimal, .equals]
    ]

    var body: some View {
        GeometryReader { geo in
            let pad: CGFloat = 14
            let gap: CGFloat = 11
            let side = (geo.size.width - pad * 2 - gap * 3) / 4

            VStack(spacing: gap) {
                Spacer(minLength: 0)

                // Display
                VStack(alignment: .trailing, spacing: 6) {
                    Text(calc.expression)
                        .font(.system(size: 20, design: .monospaced))
                        .foregroundColor(Palette.dim)
                        .lineLimit(1)
                    Text(calc.prettyDisplay)
                        .font(.system(size: 64, weight: .regular, design: .monospaced))
                        .foregroundColor(Palette.readout)
                        .lineLimit(1)
                        .minimumScaleFactor(0.35)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

                // Keypad
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(rows[r].indices, id: \.self) { c in
                            key(rows[r][c], side: side, gap: gap)
                        }
                    }
                }
            }
            .padding(.horizontal, pad)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .background(Palette.bg.ignoresSafeArea())
    }

    @ViewBuilder
    private func key(_ k: Key, side: CGFloat, gap: CGFloat) -> some View {
        let isZero = (k == .zero)
        let bg: Color = k.isOp ? Palette.op : (k.isFn ? Palette.fn : Palette.digit)
        let fg: Color = k.isOp ? Palette.onOp : Palette.readout
        let selected = k.isOp && k != .equals && {
            if case .op(let s) = k { return s == calc.activeOp }; return false
        }()

        Button(action: { tap(k) }) {
            Text(k.label)
                .font(.system(size: 30, weight: k.isOp ? .semibold : .regular))
                .foregroundColor(selected ? Palette.op : fg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            width: isZero ? side * 2 + gap : side,
            height: side
        )
        .background(selected ? Palette.readout : bg)
        .clipShape(Capsule())
    }

    private func tap(_ k: Key) {
        switch k {
        case .digit(let d): calc.digit(d)
        case .zero:         calc.digit("0")
        case .op(let o):    calc.choose(o)
        case .decimal:      calc.decimal()
        case .equals:       calc.equals()
        case .clear:        calc.clear()
        case .negate:       calc.negate()
        case .percent:      calc.percent()
        }
    }
}
