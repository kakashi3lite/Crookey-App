import SwiftUI

struct CKButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return Color("AccentColor")
            case .secondary:
                return Color.gray.opacity(0.1)
            case .ghost:
                return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary, .ghost:
                return Color("AccentColor")
            }
        }
        
        var borderColor: Color {
            switch self {
            case .ghost:
                return Color("AccentColor")
            default:
                return .clear
            }
        }
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor, lineWidth: 1)
            )
        }
    }
}

// Icon Button variant
struct CKIconButton: View {
    let icon: String
    let style: CKButton.ButtonStyle
    let action: () -> Void
    
    init(
        icon: String,
        style: CKButton.ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 44, height: 44)
                .background(style.backgroundColor)
                .foregroundColor(style.foregroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style.borderColor, lineWidth: 1)
                )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CKButton("Primary Button", icon: "plus") {}
        CKButton("Secondary Button", icon: "star", style: .secondary) {}
        CKButton("Ghost Button", style: .ghost) {}
        
        HStack(spacing: 12) {
            CKIconButton(icon: "heart") {}
            CKIconButton(icon: "bookmark", style: .secondary) {}
            CKIconButton(icon: "square.and.arrow.up", style: .ghost) {}
        }
    }
    .padding()
}