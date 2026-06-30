import Foundation
import UIKit
import CoreText

final class InvoicePDFGenerator {
    
    struct InvoiceData {
        let storeName: String
        let storeAddress: String
        let storePhone: String
        let gstin: String
        
        let date: Date
        let invoiceNumber: String
        let customerId: String
        
        let clientName: String
        let clientDetails: String // company or email/phone
        
        struct Item {
            let description: String
            let qty: Int
            let rate: Double
            let amount: Double
        }
        
        let items: [Item]
        let subtotal: Double
        let cgst: Double
        let sgst: Double
        let total: Double
        var isGiftInvoice: Bool = false
    }
    
    static func generateInvoice(data: InvoiceData) -> URL? {
        let format = UIGraphicsPDFRendererFormat()
        let pageWidth = 595.2 // A4 width
        let pageHeight = 841.8 // A4 height
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let dataURL = FileManager.default.temporaryDirectory.appendingPathComponent("invoice_\(data.invoiceNumber).pdf")
        
        do {
            try renderer.writePDF(to: dataURL, withActions: { context in
                context.beginPage()
                
                let cgContext = context.cgContext
                
                // Title
                drawText("Invoice", at: CGPoint(x: pageWidth / 2 - 50, y: 40), font: .boldSystemFont(ofSize: 24))
                
                var currentY: CGFloat = 100
                let leftMargin: CGFloat = 50
                let rightMargin: CGFloat = pageWidth - 50
                let rightAlignedX: CGFloat = 350
                
                // Left Header (Store details)
                let storeFont = UIFont.systemFont(ofSize: 12)
                drawText(data.storeName, at: CGPoint(x: leftMargin, y: currentY), font: storeFont)
                currentY += 16
                drawText(data.storeAddress, at: CGPoint(x: leftMargin, y: currentY), font: storeFont)
                currentY += 16
                drawText("Phone \(data.storePhone)", at: CGPoint(x: leftMargin, y: currentY), font: storeFont)
                currentY += 16
                drawText("GSTIN \(data.gstin)", at: CGPoint(x: leftMargin, y: currentY), font: storeFont)
                
                // Right Header (Invoice details)
                var rightY: CGFloat = 116
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy"
                drawText("Date", at: CGPoint(x: rightAlignedX, y: rightY), font: storeFont)
                drawText(dateFormatter.string(from: data.date), at: CGPoint(x: rightAlignedX + 80, y: rightY), font: storeFont)
                rightY += 16
                drawText("Invoice #", at: CGPoint(x: rightAlignedX, y: rightY), font: storeFont)
                drawText(data.invoiceNumber, at: CGPoint(x: rightAlignedX + 80, y: rightY), font: storeFont)
                rightY += 16
                drawText("Customer ID", at: CGPoint(x: rightAlignedX, y: rightY), font: storeFont)
                drawText(data.customerId, at: CGPoint(x: rightAlignedX + 80, y: rightY), font: storeFont)
                
                currentY += 40
                
                // Bill To
                drawText("Bill to:", at: CGPoint(x: leftMargin, y: currentY), font: storeFont)
                currentY += 16
                drawText(data.clientName, at: CGPoint(x: leftMargin + 20, y: currentY), font: storeFont)
                currentY += 16
                
                let detailsLines = data.clientDetails.split(separator: "\n")
                for line in detailsLines {
                    drawText(String(line), at: CGPoint(x: leftMargin + 20, y: currentY), font: storeFont)
                    currentY += 16
                }
                
                currentY += 30
                
                // Table Header
                let col1: CGFloat = leftMargin // Description
                let col2: CGFloat = leftMargin + 280 // Qty
                let col3: CGFloat = leftMargin + 340 // Rate
                let col4: CGFloat = rightMargin - 80 // Amount
                
                drawText("Description", at: CGPoint(x: col1 + 5, y: currentY + 5), font: storeFont)
                drawText("Qty", at: CGPoint(x: col2 + 5, y: currentY + 5), font: storeFont)
                
                if !data.isGiftInvoice {
                    drawText("Rate", at: CGPoint(x: col3 + 5, y: currentY + 5), font: storeFont)
                    drawText("Amount", at: CGPoint(x: col4 + 5, y: currentY + 5), font: storeFont)
                }
                
                // Draw table header borders
                drawRect(CGRect(x: leftMargin, y: currentY, width: rightMargin - leftMargin, height: 25), context: cgContext)
                drawLine(from: CGPoint(x: col2, y: currentY), to: CGPoint(x: col2, y: currentY + 25), context: cgContext)
                if !data.isGiftInvoice {
                    drawLine(from: CGPoint(x: col3, y: currentY), to: CGPoint(x: col3, y: currentY + 25), context: cgContext)
                    drawLine(from: CGPoint(x: col4, y: currentY), to: CGPoint(x: col4, y: currentY + 25), context: cgContext)
                }
                
                currentY += 25
                let tableStartY = currentY
                
                // Table Rows
                for item in data.items {
                    drawText(item.description, at: CGPoint(x: col1 + 5, y: currentY + 5), font: storeFont)
                    drawText("\(item.qty)", at: CGPoint(x: col2 + 5, y: currentY + 5), font: storeFont)
                    
                    if !data.isGiftInvoice {
                        drawText(CurrencyManager.shared.format(amount: item.rate), at: CGPoint(x: col3 + 5, y: currentY + 5), font: storeFont)
                        let amountText = CurrencyManager.shared.format(amount: item.amount)
                        
                        let amountSize = amountText.size(withAttributes: [.font: storeFont])
                        drawText(amountText, at: CGPoint(x: rightMargin - amountSize.width - 5, y: currentY + 5), font: storeFont)
                    }
                    
                    currentY += 25
                }
                
                // Draw table body borders
                drawRect(CGRect(x: leftMargin, y: tableStartY, width: rightMargin - leftMargin, height: currentY - tableStartY), context: cgContext)
                drawLine(from: CGPoint(x: col2, y: tableStartY), to: CGPoint(x: col2, y: currentY), context: cgContext)
                if !data.isGiftInvoice {
                    drawLine(from: CGPoint(x: col3, y: tableStartY), to: CGPoint(x: col3, y: currentY), context: cgContext)
                    drawLine(from: CGPoint(x: col4, y: tableStartY), to: CGPoint(x: col4, y: currentY), context: cgContext)
                }
                
                // Totals
                if !data.isGiftInvoice {
                    let totalsYStart = currentY
                    let totalsLabelsX = col4 - 100
                    
                    drawText("Subtotal", at: CGPoint(x: totalsLabelsX, y: currentY + 5), font: storeFont)
                    drawTextRightAligned(CurrencyManager.shared.format(amount: data.subtotal), atY: currentY + 5, rightEdge: rightMargin - 5, font: storeFont)
                    currentY += 20
                    
                    drawText("CGST (\((0.09).formatted(.percent)))", at: CGPoint(x: totalsLabelsX, y: currentY + 5), font: storeFont)
                    drawTextRightAligned(CurrencyManager.shared.format(amount: data.cgst), atY: currentY + 5, rightEdge: rightMargin - 5, font: storeFont)
                    currentY += 20
                    
                    drawText("SGST (\((0.09).formatted(.percent)))", at: CGPoint(x: totalsLabelsX, y: currentY + 5), font: storeFont)
                    drawTextRightAligned(CurrencyManager.shared.format(amount: data.sgst), atY: currentY + 5, rightEdge: rightMargin - 5, font: storeFont)
                    currentY += 20
                    
                    drawText("Total", at: CGPoint(x: totalsLabelsX, y: currentY + 5), font: storeFont)
                    drawTextRightAligned(CurrencyManager.shared.format(amount: data.total), atY: currentY + 5, rightEdge: rightMargin - 5, font: storeFont)
                    currentY += 20
                    
                    // Borders for totals
                    drawLine(from: CGPoint(x: totalsLabelsX - 5, y: totalsYStart), to: CGPoint(x: rightMargin, y: totalsYStart), context: cgContext)
                    drawRect(CGRect(x: totalsLabelsX - 5, y: totalsYStart, width: rightMargin - totalsLabelsX + 5, height: currentY - totalsYStart), context: cgContext)
                    drawLine(from: CGPoint(x: col4, y: totalsYStart), to: CGPoint(x: col4, y: currentY), context: cgContext)
                    
                    // Internal lines for totals
                    for i in 1...3 {
                        let y = totalsYStart + CGFloat(i * 20)
                        drawLine(from: CGPoint(x: totalsLabelsX - 5, y: y), to: CGPoint(x: rightMargin, y: y), context: cgContext)
                    }
                }
                
                // Footer
                drawText("This is electronically generated, Signature not required.", at: CGPoint(x: pageWidth / 2 - 120, y: pageHeight - 50), font: UIFont.italicSystemFont(ofSize: 10))
            })
            return dataURL
        } catch {
            print("Error creating PDF: \(error)")
            return nil
        }
    }
    
    private static func drawText(_ text: String, at point: CGPoint, font: UIFont) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        text.draw(at: point, withAttributes: attributes)
    }
    
    private static func drawTextRightAligned(_ text: String, atY y: CGFloat, rightEdge: CGFloat, font: UIFont) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: rightEdge - size.width, y: y), withAttributes: attributes)
    }
    
    private static func drawRect(_ rect: CGRect, context: CGContext) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        context.stroke(rect)
    }
    
    private static func drawLine(from start: CGPoint, to end: CGPoint, context: CGContext) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
    }
}
