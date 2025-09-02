#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont
import math

def create_smart_screenshot_icon(size, output_path):
    """Create a SmartScreenshot icon with camera and text elements"""
    
    # Create a new image with a gradient background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Calculate dimensions
    padding = size // 8
    center = size // 2
    
    # Create gradient background (blue to purple)
    for y in range(size):
        ratio = y / size
        r = int(64 + (128 - 64) * ratio)
        g = int(128 + (64 - 128) * ratio)
        b = int(255 - 64 * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # Draw camera body (rounded rectangle)
    camera_width = size - 2 * padding
    camera_height = camera_width * 0.6
    camera_x = padding
    camera_y = center - camera_height // 2
    
    # Camera body
    draw.rounded_rectangle(
        [camera_x, camera_y, camera_x + camera_width, camera_y + camera_height],
        radius=size // 16,
        fill=(255, 255, 255, 200),
        outline=(255, 255, 255, 255),
        width=2
    )
    
    # Camera lens
    lens_radius = camera_width // 6
    lens_x = center
    lens_y = center
    draw.ellipse(
        [lens_x - lens_radius, lens_y - lens_radius, 
         lens_x + lens_radius, lens_y + lens_radius],
        fill=(0, 0, 0, 255),
        outline=(255, 255, 255, 255),
        width=2
    )
    
    # Inner lens
    inner_radius = lens_radius - 4
    draw.ellipse(
        [lens_x - inner_radius, lens_y - inner_radius,
         lens_x + inner_radius, lens_y + inner_radius],
        fill=(100, 150, 255, 255)
    )
    
    # Add text "SS" for SmartScreenshot
    try:
        # Try to use a system font
        font_size = size // 8
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
    
    text = "SS"
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    
    text_x = center - text_width // 2
    text_y = camera_y + camera_height + padding // 2
    
    # Text background
    draw.rounded_rectangle(
        [text_x - 4, text_y - 2, text_x + text_width + 4, text_y + text_height + 2],
        radius=4,
        fill=(0, 0, 0, 150)
    )
    
    # Draw text
    draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
    
    # Save the icon
    img.save(output_path, 'PNG')
    print(f"Created icon: {output_path}")

def main():
    """Generate all required icon sizes"""
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    
    for size in sizes:
        output_path = f"temp_icon/AppIcon-{size}w.png"
        create_smart_screenshot_icon(size, output_path)
    
    print("All icons created successfully!")

if __name__ == "__main__":
    main()
