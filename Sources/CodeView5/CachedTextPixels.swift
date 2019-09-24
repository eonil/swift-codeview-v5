//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/24/19.
//

import Foundation

struct CachedTextPixels {
    var cgLayer: CGLayer
    var gridFittingCharDisplacementY: CGFloat
    var imageWidth: CGFloat
    var imageHeight: CGFloat
}
extension CGContext {
    ///
    /// CGLayer potentially can be accelerated by GPU.
    /// https://stackoverflow.com/a/38585451/246776
    /// - Anyway it doesn't at this point.
    /// - Profiling result seems like it's doing all composition in CPU.
    ///
    ///     297.00ms 29.8% 297.00ms     vPremultipliedAlphaBlendWithPermute_RGBA8888_CV_avx2
    ///
    /// CGLayer requires grid/point convertion manually.
    /// https://stackoverflow.com/a/8742178/246776
    /// - Everything will be aligned to line height of std-font.
    /// - Any non-std sized glyphs will be aligned to std-font baseline position.
    /// - Large non-std sized glyph can be overlap.
    /// - Distribute leading to both of top and bottom.
    /// - Consider that we pixel-grid alignment.
    ///
    /// Conclustion
    /// -----------
    /// CoreGraphics is high quality and correct graphic drawing facility.
    /// But it is very slow and depending on it is not a good idea.
    /// We can make this far faster using `CALayer`, but that would require
    /// object tree management that I do not want, and using `CALayer`
    /// is still somwhat suboptimal solution.
    /// - It requires more object lifetime and object hierarchy management.
    /// - We cannot control details.
    ///
    /// Ultimate solution should be accessing GPU directly.
    /// But I am not going to do that in Swift. I'll use Rust for that.
    /// Now editing rendering is "good-enough" level, so I'll just accept this.
    ///
    /// Next implementation will be a completely branch new one on Rust.
    /// Don't forget that this one is bootstrapping implementation.
    ///
    func makeCachedTextPixels(config:CodeConfig, scale:CGFloat, with ctLine:CTLine) -> CachedTextPixels? {
        // Test sample: 🔥らがな
        // https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/TypoFeatures/TextSystemFeatures.html
        let stdFont = config.rendering.standardFont
        let stdLineH = stdFont.leading + stdFont.ascender + (-stdFont.descender)
        let stdGridFittingLineH = config.rendering.gridFittingLineHeight
        let stdTopExtraGap = (stdGridFittingLineH - stdLineH)/2
        let charTypoMetrics = ctLine.typographicBounds
        let charLineH = charTypoMetrics.ascent + charTypoMetrics.descent + charTypoMetrics.leading
        let charDisplacementY = -((charTypoMetrics.ascent + charTypoMetrics.leading/2) - (stdFont.ascender + stdTopExtraGap))
        let gridFittingCharDisplacementY = floor(charDisplacementY)
        let drawingY = charDisplacementY - gridFittingCharDisplacementY
        let imageW = ceil(charTypoMetrics.width)
        let imageH = ceil(charLineH + 2)
        guard imageW > 0 && imageH > 0 else { return nil }
        let layerSize = CGSize(width: imageW * scale, height: imageH * scale)
        let cgLayer = CGLayer(self, size: layerSize, auxiliaryInfo: nil)!
        let cgLayerContext = cgLayer.context!
        cgLayerContext.scaleBy(x: scale, y: scale)
        cgLayerContext.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        cgLayerContext.textPosition = CGPoint(
            x: 0,
            y: drawingY + charTypoMetrics.leading/2 + charTypoMetrics.ascent)
        CTLineDraw(ctLine, cgLayerContext)
        let ctp = CachedTextPixels(
            cgLayer: cgLayer,
            gridFittingCharDisplacementY: gridFittingCharDisplacementY,
            imageWidth: imageW,
            imageHeight: imageH)
        return ctp
    }
    func draw(_ c:CachedTextPixels, at p:CGPoint) {
        let f = CGRect(
            x: p.x,
            y: p.y + c.gridFittingCharDisplacementY,
            width: c.imageWidth,
            height: c.imageHeight)
        draw(c.cgLayer, in: f)
    }
}
