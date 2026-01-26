import SwiftUI

struct ChangePillView: View {
    let currentText: String
    let impactText: String?
    let isIncrease: Bool
    let unitSuffix: String?
    let slashUnit: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 2) {
                Text(currentText)
                    .lexendFont(13)
                    .foregroundColor(Color(hex: "231F30"))
                
                if let impactText = impactText {
                    Text(impactText)
                        .lexendFont(10)
                        .baselineOffset(6)
                        .foregroundColor(isIncrease ? Color(hex: "FA003F") : Color(hex: "4CAF50"))
                }
            }
                        
            if let unitSuffix = unitSuffix {
                Text(slashUnit ? " / \(unitSuffix)" : " \(unitSuffix)")
                    .lexendFont(13)
                    .foregroundColor(Color(hex: "231F30"))
            }
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}

#Preview("ChangePillView") {
    VStack(spacing: 12) {
        ChangePillView(
            currentText: "₱12",
            impactText: "+₱2.00",
            isIncrease: true,
            unitSuffix: "pc",
            slashUnit: true
        )
        ChangePillView(
            currentText: "2",
            impactText: "+1",
            isIncrease: true,
            unitSuffix: "ea",
            slashUnit: false
        )
    }
    .padding()
    .background(Color.white)
}
