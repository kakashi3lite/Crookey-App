//
//  MetalShaders.metal
//  Crookey
//
//  Created by Elite iOS Engineer on 12/27/24.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Food Enhancement Kernel

kernel void foodEnhancementKernel(texture2d<float, access::read> inputTexture [[texture(0)]],
                                 texture2d<float, access::write> outputTexture [[texture(1)]],
                                 uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    // Read the input pixel
    float4 inputColor = inputTexture.read(gid);
    
    // Enhanced food image processing pipeline
    
    // 1. Color space conversion to HSV for better food color manipulation
    float3 rgb = inputColor.rgb;
    float maxVal = max(max(rgb.r, rgb.g), rgb.b);
    float minVal = min(min(rgb.r, rgb.g), rgb.b);
    float delta = maxVal - minVal;
    
    float hue = 0.0;
    if (delta > 0.0) {
        if (maxVal == rgb.r) {
            hue = fmod((rgb.g - rgb.b) / delta + 6.0, 6.0);
        } else if (maxVal == rgb.g) {
            hue = (rgb.b - rgb.r) / delta + 2.0;
        } else {
            hue = (rgb.r - rgb.g) / delta + 4.0;
        }
        hue /= 6.0;
    }
    
    float saturation = (maxVal == 0.0) ? 0.0 : delta / maxVal;
    float value = maxVal;
    
    // 2. Food-specific enhancements
    
    // Enhance warm colors (reds, oranges, yellows) which are common in food
    if (hue >= 0.0 && hue <= 0.167) { // Red to yellow range
        saturation = min(saturation * 1.15, 1.0); // Increase saturation by 15%
        value = min(value * 1.05, 1.0); // Slight brightness boost
    }
    
    // Enhance greens for vegetables
    if (hue >= 0.25 && hue <= 0.417) { // Green range
        saturation = min(saturation * 1.1, 1.0);
        value = min(value * 1.02, 1.0);
    }
    
    // 3. Convert back to RGB
    float c = value * saturation;
    float x = c * (1.0 - abs(fmod(hue * 6.0, 2.0) - 1.0));
    float m = value - c;
    
    float3 enhancedRgb;
    if (hue < 1.0/6.0) {
        enhancedRgb = float3(c, x, 0);
    } else if (hue < 2.0/6.0) {
        enhancedRgb = float3(x, c, 0);
    } else if (hue < 3.0/6.0) {
        enhancedRgb = float3(0, c, x);
    } else if (hue < 4.0/6.0) {
        enhancedRgb = float3(0, x, c);
    } else if (hue < 5.0/6.0) {
        enhancedRgb = float3(x, 0, c);
    } else {
        enhancedRgb = float3(c, 0, x);
    }
    enhancedRgb += m;
    
    // 4. Apply sharpening filter for better ML recognition
    float sharpenKernel[9] = {
        0, -0.5, 0,
        -0.5, 3.0, -0.5,
        0, -0.5, 0
    };
    
    float3 sharpenedColor = float3(0.0);
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            uint2 samplePos = uint2(max(0, min(int(gid.x) + i, int(inputTexture.get_width()) - 1)),
                                   max(0, min(int(gid.y) + j, int(inputTexture.get_height()) - 1)));
            float4 sampleColor = inputTexture.read(samplePos);
            int kernelIndex = (i + 1) * 3 + (j + 1);
            sharpenedColor += sampleColor.rgb * sharpenKernel[kernelIndex];
        }
    }
    
    // Blend enhanced color with sharpened result
    float3 finalColor = mix(enhancedRgb, sharpenedColor, 0.3);
    finalColor = clamp(finalColor, 0.0, 1.0);
    
    outputTexture.write(float4(finalColor, inputColor.a), gid);
}

// MARK: - Nutrition Analysis Kernel

kernel void nutritionAnalysisKernel(texture2d<float, access::read> inputTexture [[texture(0)]],
                                   texture2d<float, access::write> outputTexture [[texture(1)]],
                                   uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    float4 inputColor = inputTexture.read(gid);
    float3 rgb = inputColor.rgb;
    
    // Nutrition estimation based on color analysis
    
    // Green vegetables analysis (high in vitamins A, C, K, folate)
    float greenness = rgb.g - max(rgb.r, rgb.b);
    greenness = max(0.0, greenness);
    
    // Orange/Red foods analysis (high in beta-carotene, lycopene)
    float warmness = max(rgb.r, rgb.g) - rgb.b;
    warmness = max(0.0, warmness);
    
    // Brown foods analysis (proteins, complex carbohydrates)
    float brownness = min(min(rgb.r, rgb.g), rgb.b) * 2.0 - max(max(rgb.r, rgb.g), rgb.b);
    brownness = max(0.0, brownness);
    
    // White/Light foods analysis (simple carbohydrates, dairy)
    float lightness = (rgb.r + rgb.g + rgb.b) / 3.0;
    
    // Store analysis results in output texture channels
    // R: Vitamin content estimation
    // G: Protein content estimation  
    // B: Carbohydrate content estimation
    // A: Overall nutritional density
    
    float vitaminContent = greenness * 0.8 + warmness * 0.6;
    float proteinContent = brownness * 0.9 + (1.0 - lightness) * 0.3;
    float carbContent = lightness * 0.7 + brownness * 0.4;
    float nutritionalDensity = (vitaminContent + proteinContent + carbContent) / 3.0;
    
    outputTexture.write(float4(vitaminContent, proteinContent, carbContent, nutritionalDensity), gid);
}

// MARK: - Freshness Detection Kernel

kernel void freshnessDetectionKernel(texture2d<float, access::read> inputTexture [[texture(0)]],
                                    texture2d<float, access::write> outputTexture [[texture(1)]],
                                    uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    float4 inputColor = inputTexture.read(gid);
    float3 rgb = inputColor.rgb;
    
    // Freshness analysis based on multiple visual indicators
    
    // 1. Brown spot detection (indicates aging/spoilage)
    float brownSpotScore = 0.0;
    if (rgb.r > 0.4 && rgb.g > 0.25 && rgb.b < 0.3 && 
        rgb.r - rgb.g < 0.2 && rgb.g - rgb.b > 0.1) {
        brownSpotScore = 1.0;
    }
    
    // 2. Color vibrancy analysis
    float maxChannel = max(max(rgb.r, rgb.g), rgb.b);
    float minChannel = min(min(rgb.r, rgb.g), rgb.b);
    float vibrancy = maxChannel - minChannel; // Saturation approximation
    
    // 3. Surface texture analysis using local variance
    float textureVariance = 0.0;
    float3 localMean = float3(0.0);
    int sampleCount = 0;
    
    // Sample 3x3 neighborhood
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            uint2 samplePos = uint2(max(0, min(int(gid.x) + i, int(inputTexture.get_width()) - 1)),
                                   max(0, min(int(gid.y) + j, int(inputTexture.get_height()) - 1)));
            float3 sampleColor = inputTexture.read(samplePos).rgb;
            localMean += sampleColor;
            sampleCount++;
        }
    }
    localMean /= float(sampleCount);
    
    // Calculate variance
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            uint2 samplePos = uint2(max(0, min(int(gid.x) + i, int(inputTexture.get_width()) - 1)),
                                   max(0, min(int(gid.y) + j, int(inputTexture.get_height()) - 1)));
            float3 sampleColor = inputTexture.read(samplePos).rgb;
            float3 diff = sampleColor - localMean;
            textureVariance += dot(diff, diff);
        }
    }
    textureVariance /= float(sampleCount);
    
    // 4. Overall freshness score calculation
    float freshnessScore = vibrancy * 0.4 + 
                          (1.0 - brownSpotScore) * 0.4 + 
                          min(textureVariance * 5.0, 1.0) * 0.2;
    
    // Store results in output texture
    // R: Brown spot detection
    // G: Color vibrancy
    // B: Texture variance
    // A: Overall freshness score
    
    outputTexture.write(float4(brownSpotScore, vibrancy, textureVariance, freshnessScore), gid);
}

// MARK: - Edge Detection for Food Segmentation

kernel void edgeDetectionKernel(texture2d<float, access::read> inputTexture [[texture(0)]],
                               texture2d<float, access::write> outputTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    // Sobel edge detection for food item segmentation
    float sobelX[9] = {
        -1, 0, 1,
        -2, 0, 2,
        -1, 0, 1
    };
    
    float sobelY[9] = {
        -1, -2, -1,
         0,  0,  0,
         1,  2,  1
    };
    
    float3 gradientX = float3(0.0);
    float3 gradientY = float3(0.0);
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            uint2 samplePos = uint2(max(0, min(int(gid.x) + i, int(inputTexture.get_width()) - 1)),
                                   max(0, min(int(gid.y) + j, int(inputTexture.get_height()) - 1)));
            float3 sampleColor = inputTexture.read(samplePos).rgb;
            
            int kernelIndex = (i + 1) * 3 + (j + 1);
            gradientX += sampleColor * sobelX[kernelIndex];
            gradientY += sampleColor * sobelY[kernelIndex];
        }
    }
    
    float3 magnitude = sqrt(gradientX * gradientX + gradientY * gradientY);
    float edgeStrength = (magnitude.r + magnitude.g + magnitude.b) / 3.0;
    
    outputTexture.write(float4(edgeStrength, edgeStrength, edgeStrength, 1.0), gid);
}