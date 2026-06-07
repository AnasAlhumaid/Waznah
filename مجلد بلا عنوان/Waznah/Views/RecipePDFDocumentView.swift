//
//  RecipePDFDocumentView.swift
//  Waznah
//

import SwiftUI
import UIKit

struct RecipePDFDocumentView: View {
    let data: RecipeShareData
    
    private let brand = Color(hex: "#86373E")
    private let paperTop = Color(hex: "#FBF7F4")
    private let paperBottom = Color.white
    
    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 20) {
                heroCard
                metricsGrid
                stepsSection
                notesSection
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 28)
            
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [paperTop, paperBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Waznah".localized())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(brand)
                Text("Coffee Recipe".localized())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(brand)
                .padding(14)
                .background(brand.opacity(0.1))
                .clipShape(Circle())
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(Color.white.opacity(0.65))
    }
    
    private var heroCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(brand.opacity(0.08))
                    .frame(width: 130, height: 130)
                
                Image(data.methodImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
            }
            
            Text(data.displayRoastery)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            HStack(spacing: 8) {
                Label(data.method, systemImage: "mug.fill")
                Text("•")
                Text(data.sourceLabel)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(brand)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
    }
    
    @ViewBuilder
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            pdfMetric(title: "Coffee".localized(), value: data.coffee, tint: Color(hex: "354449"), icon: "circle.hexagongrid")
            pdfMetric(title: "Water".localized(), value: data.water, tint: Color(hex: "648981"), icon: "drop.fill")
            pdfMetric(title: "Ratio".localized(), value: data.ratio, tint: Color(hex: "BF8A6E"), icon: "percent")
            pdfMetric(title: "Temp".localized(), value: data.temperature, tint: Color(hex: "8F7469"), icon: "thermometer.medium")
        }
        
        if !data.grind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, data.grind != "-" {
            HStack {
                pdfMetric(title: "Grind".localized(), value: data.grind, tint: Color(hex: "ABAEA5"), icon: "circle.dotted")
                Spacer(minLength: 0)
            }
        }
    }
    
    @ViewBuilder
    private var stepsSection: some View {
        if !data.steps.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Brew Steps".localized())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(brand)
                
                ForEach(Array(data.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(brand)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.step.isEmpty ? "Pour".localized() : step.step)
                                .font(.system(size: 15, weight: .semibold))
                            
                            HStack(spacing: 16) {
                                Label("\(step.water) ml", systemImage: "drop.fill")
                                Label("\(step.time) \("sec".localized())", systemImage: "timer")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
        let notes = data.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes".localized())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(brand)
                
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
    
    private var footer: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Shared from Waznah".localized())
                    .font(.system(size: 13, weight: .bold))
                Text("Scan to get Waznah".localized())
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.92)
            }
            .foregroundColor(.white)

            Spacer(minLength: 12)

            pdfQRCode
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(brand)
    }

    @ViewBuilder
    private var pdfQRCode: some View {
        if let qrImage = QRCodeGenerator.makeImage(
            from: AppUpdateManager.appStoreShareURLString,
            length: 240
        ) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private func pdfMetric(title: String, value: String, tint: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(tint)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Text(value.isEmpty ? "-" : value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
