#!/usr/bin/env python3
import os
import subprocess

def create_simple_icon():
    """Create a simple SmartScreenshot icon using macOS built-in tools"""
    
    # Create a simple icon using macOS's sips command
    # We'll create a simple colored square with text
    
    # Create a 1024x1024 PNG with a gradient background
    svg_content = '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4A90E2;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#7B68EE;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Background -->
  <rect width="1024" height="1024" fill="url(#grad)" rx="128" ry="128"/>
  
  <!-- Camera body -->
  <rect x="128" y="312" width="768" height="400" fill="rgba(255,255,255,0.9)" 
        stroke="white" stroke-width="8" rx="64" ry="64"/>
  
  <!-- Camera lens -->
  <circle cx="512" cy="512" r="128" fill="black" stroke="white" stroke-width="8"/>
  <circle cx="512" cy="512" r="96" fill="#6495ED"/>
  
  <!-- SS text -->
  <text x="512" y="800" font-family="Helvetica" font-size="120" font-weight="bold" 
        text-anchor="middle" fill="white">SS</text>
  
  <!-- Small camera details -->
  <rect x="400" y="280" width="224" height="32" fill="rgba(255,255,255,0.8)" rx="16" ry="16"/>
  <circle cx="512" cy="296" r="8" fill="#333"/>
</svg>'''
    
    # Write SVG to file
    with open("temp_icon/icon.svg", "w") as f:
        f.write(svg_content)
    
    # Convert SVG to PNG using macOS tools
    try:
        subprocess.run([
            "sips", "-s", "format", "png", "temp_icon/icon.svg", 
            "--out", "temp_icon/AppIcon-1024w.png"
        ], check=True)
        
        # Create different sizes
        sizes = [16, 32, 64, 128, 256, 512]
        for size in sizes:
            subprocess.run([
                "sips", "-z", str(size), str(size), "temp_icon/AppIcon-1024w.png",
                "--out", f"temp_icon/AppIcon-{size}w.png"
            ], check=True)
        
        print("Icons created successfully!")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error creating icons: {e}")
        return False

if __name__ == "__main__":
    create_simple_icon()
