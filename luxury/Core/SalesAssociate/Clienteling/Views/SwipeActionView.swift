import SwiftUI

struct SwipeActionView<Content: View>: View {
    var content: () -> Content
    var onConfirm: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    @State private var isSwipedRightToLeft: Bool = false
    @State private var isSwipedLeftToRight: Bool = false
    
    @State private var showDeleteAlert: Bool = false
    @State private var showConfirmAlert: Bool = false
    
    private let buttonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Background action buttons
            HStack(spacing: 0) {
                // Leading side (Left-to-Right Swipe)
                if onConfirm != nil {
                    Button(action: {
                        showConfirmAlert = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(AppFonts.sansSerif(size: 16, weight: .bold))
                            Text("Done")
                                .font(AppFonts.sansSerif(size: 10, weight: .medium))
                        }
                        .frame(width: buttonWidth, alignment: .center)
                        .frame(maxHeight: .infinity)
                        .background(AppColors.success)
                        .foregroundColor(.white)
                    }
                    .opacity(offset > 0 ? 1 : 0)
                }
                
                Spacer()
                
                // Trailing side (Right-to-Left Swipe)
                if onDelete != nil {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(AppFonts.sansSerif(size: 16, weight: .bold))
                            Text("Delete")
                                .font(AppFonts.sansSerif(size: 10, weight: .medium))
                        }
                        .frame(width: buttonWidth, alignment: .center)
                        .frame(maxHeight: .infinity)
                        .background(AppColors.error)
                        .foregroundColor(.white)
                    }
                    .opacity(offset < 0 ? 1 : 0)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Foreground Content
            content()
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let currentOffset = isSwipedRightToLeft ? -buttonWidth : (isSwipedLeftToRight ? buttonWidth : 0)
                            let newOffset = currentOffset + value.translation.width
                            
                            // Restrict swiping if action is nil
                            if newOffset > 0 && onConfirm == nil {
                                offset = 0
                                return
                            }
                            if newOffset < 0 && onDelete == nil {
                                offset = 0
                                return
                            }
                            
                            // Rubber band effect
                            if newOffset > buttonWidth {
                                let excess = newOffset - buttonWidth
                                offset = buttonWidth + (excess * 0.2)
                            } else if newOffset < -buttonWidth {
                                let excess = -buttonWidth - newOffset
                                offset = -buttonWidth - (excess * 0.2)
                            } else {
                                offset = newOffset
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if value.translation.width < -40 || value.predictedEndTranslation.width < -100 {
                                    // Swipe Right-to-Left
                                    if onDelete != nil {
                                        offset = -buttonWidth
                                        isSwipedRightToLeft = true
                                        isSwipedLeftToRight = false
                                    } else {
                                        offset = 0
                                    }
                                } else if value.translation.width > 40 || value.predictedEndTranslation.width > 100 {
                                    // Swipe Left-to-Right
                                    if onConfirm != nil {
                                        offset = buttonWidth
                                        isSwipedLeftToRight = true
                                        isSwipedRightToLeft = false
                                    } else {
                                        offset = 0
                                    }
                                } else {
                                    offset = 0
                                    isSwipedRightToLeft = false
                                    isSwipedLeftToRight = false
                                }
                            }
                        }
                )
        }
        .alert("Confirm Deletion", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                withAnimation { resetSwipe() }
            }
            Button("Delete", role: .destructive) {
                withAnimation { resetSwipe() }
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete this appointment?")
        }
        .alert("Mark as Done", isPresented: $showConfirmAlert) {
            Button("Cancel", role: .cancel) {
                withAnimation { resetSwipe() }
            }
            Button("Confirm") {
                withAnimation { resetSwipe() }
                onConfirm?()
            }
        } message: {
            Text("Are you sure you want to mark this appointment as done?")
        }
    }
    
    private func resetSwipe() {
        offset = 0
        isSwipedLeftToRight = false
        isSwipedRightToLeft = false
    }
}
